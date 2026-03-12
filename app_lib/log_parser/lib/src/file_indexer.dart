import 'dart:convert';
import 'dart:io';

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
    final bytes = await file.readAsBytes();

    final lines = <LineIndex>[];
    var validLines = 0;
    var invalidLines = 0;
    final sampleEntries = <Map<String, dynamic>>[];
    final requestIdMap = <String, List<int>>{};

    var lineStart = 0;
    for (var i = 0; i <= bytes.length; i++) {
      final isEnd = i == bytes.length;
      if (isEnd || bytes[i] == 0x0A) {
        // newline
        final lineLength = i - lineStart;
        if (lineLength > 0) {
          // Skip empty lines
          var end = i;
          // Strip trailing \r for Windows line endings
          if (end > lineStart && bytes[end - 1] == 0x0D) {
            end--;
          }
          final actualLength = end - lineStart;
          if (actualLength > 0) {
            final lineIndex = lines.length;
            lines.add(LineIndex(offset: lineStart, length: actualLength));

            // Try to parse as JSON
            try {
              final lineStr = utf8.decode(
                bytes.sublist(lineStart, lineStart + actualLength),
              );
              final json = jsonDecode(lineStr) as Map<String, dynamic>;
              validLines++;

              // Collect samples for key path discovery (first 100)
              if (sampleEntries.length < 100) {
                sampleEntries.add(json);
              }

              // Build request_id map
              final requestId = json['request_id'];
              if (requestId is String) {
                requestIdMap.putIfAbsent(requestId, () => []).add(lineIndex);
              }
            } on Object {
              invalidLines++;
            }
          }
        }
        lineStart = i + 1;
      }
    }

    // Discover key paths from sample entries
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
}
