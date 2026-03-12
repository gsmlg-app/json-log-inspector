import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'file_index_result.dart';
import 'key_path_discovery.dart';
import 'line_index.dart';

/// Indexes a JSONL file by scanning for line boundaries and collecting
/// metadata without loading the entire file into memory.
class FileIndexer {
  /// Indexes the file at [filePath] by streaming through it line-by-line.
  ///
  /// Builds a lightweight byte-offset index for random access. Also collects:
  /// - Total, valid, and invalid line counts
  /// - Key paths discovered from the first 100 valid JSON entries
  /// - An SSE pairing map keyed by `request_id`
  static Future<FileIndexResult> indexFile(String filePath) async {
    final file = File(filePath);
    final lines = <LineIndex>[];
    var validLines = 0;
    var invalidLines = 0;
    final sampleEntries = <Map<String, dynamic>>[];
    final requestIdMap = <String, List<int>>{};

    final stream = file.openRead();
    var lineStart = 0;
    final lineBuffer = BytesBuilder(copy: false);
    var fileOffset = 0;

    await for (final chunk in stream) {
      var bufferStart = 0;

      for (var i = 0; i < chunk.length; i++) {
        if (chunk[i] == 0x0A) {
          lineBuffer.add(chunk.sublist(bufferStart, i));
          final lineBytes = lineBuffer.takeBytes();
          _addLine(
            lineBytes,
            lineStart,
            lines,
            sampleEntries,
            requestIdMap,
            (valid) => valid ? validLines++ : invalidLines++,
          );
          lineStart = fileOffset + i + 1;
          bufferStart = i + 1;
        }
      }

      if (bufferStart < chunk.length) {
        lineBuffer.add(chunk.sublist(bufferStart));
      }
      fileOffset += chunk.length;
    }

    // Handle last line without trailing newline
    final remaining = lineBuffer.takeBytes();
    if (remaining.isNotEmpty) {
      _addLine(
        remaining,
        lineStart,
        lines,
        sampleEntries,
        requestIdMap,
        (valid) => valid ? validLines++ : invalidLines++,
      );
    }

    final keyPaths = KeyPathDiscovery.discoverFromEntries(sampleEntries);

    return FileIndexResult(
      lines: lines,
      totalLines: lines.length,
      validLines: validLines,
      invalidLines: invalidLines,
      keyPaths: keyPaths,
      requestIdMap: requestIdMap,
    );
  }

  static void _addLine(
    List<int> rawBytes,
    int lineStart,
    List<LineIndex> lines,
    List<Map<String, dynamic>> sampleEntries,
    Map<String, List<int>> requestIdMap,
    void Function(bool valid) onResult,
  ) {
    var length = rawBytes.length;

    // Strip trailing \r for Windows line endings
    if (length > 0 && rawBytes[length - 1] == 0x0D) {
      length--;
    }
    if (length == 0) return;

    final lineIndex = lines.length;
    lines.add(LineIndex(offset: lineStart, length: length));

    try {
      final bytes =
          rawBytes is Uint8List
              ? rawBytes.buffer.asUint8List(rawBytes.offsetInBytes, length)
              : Uint8List.fromList(rawBytes.sublist(0, length));
      final lineStr = utf8.decode(bytes);
      final json = jsonDecode(lineStr) as Map<String, dynamic>;
      onResult(true);

      if (sampleEntries.length < 100) {
        sampleEntries.add(json);
      }

      final requestId = json['request_id'];
      if (requestId is String) {
        requestIdMap.putIfAbsent(requestId, () => []).add(lineIndex);
      }
    } on Object {
      onResult(false);
    }
  }
}
