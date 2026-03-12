import 'dart:convert';
import 'dart:io';

import 'package:log_parser/log_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('entry_reader_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Map<String, dynamic> _entry({
    String ts = '2024-01-01T00:00:00Z',
    String requestId = 'req-1',
    String recordType = 'request',
    double? durationMs,
  }) {
    return {
      'ts': ts,
      'request_id': requestId,
      'record_type': recordType,
      if (durationMs != null) 'duration_ms': durationMs,
    };
  }

  /// Writes content to a temp file and returns the path plus a FileIndexResult
  /// built via FileIndexer.
  Future<(String, FileIndexResult)> writeAndIndex(String content) async {
    final path = '${tempDir.path}/test.jsonl';
    File(path).writeAsStringSync(content);
    final index = await FileIndexer.indexFile(path);
    return (path, index);
  }

  group('EntryReader.readEntry', () {
    test('reads and parses a single entry', () async {
      final json = _entry();
      final (path, index) = await writeAndIndex(jsonEncode(json));

      final reader = EntryReader(filePath: path, index: index);
      final record = await reader.readEntry(0);

      expect(record, isNotNull);
      expect(record!.ts, equals('2024-01-01T00:00:00Z'));
      expect(record.requestId, equals('req-1'));
      expect(record.recordType, equals('request'));
    });

    test('reads correct entry from multi-line file', () async {
      final lines = [
        jsonEncode(_entry(requestId: 'r1')),
        jsonEncode(_entry(requestId: 'r2')),
        jsonEncode(_entry(requestId: 'r3')),
      ];
      final (path, index) = await writeAndIndex(lines.join('\n'));

      final reader = EntryReader(filePath: path, index: index);

      final r0 = await reader.readEntry(0);
      expect(r0!.requestId, equals('r1'));

      final r1 = await reader.readEntry(1);
      expect(r1!.requestId, equals('r2'));

      final r2 = await reader.readEntry(2);
      expect(r2!.requestId, equals('r3'));
    });

    test('returns null for invalid JSON line', () async {
      final valid = jsonEncode(_entry());
      final (path, index) = await writeAndIndex('not-json\n$valid');

      final reader = EntryReader(filePath: path, index: index);
      final result = await reader.readEntry(0);

      expect(result, isNull);
    });

    test('caches parsed entries', () async {
      final json = _entry();
      final (path, index) = await writeAndIndex(jsonEncode(json));

      final reader = EntryReader(filePath: path, index: index);

      final first = await reader.readEntry(0);
      final second = await reader.readEntry(0);

      // Both calls should return the same data
      expect(first, equals(second));
    });

    test('respects cache size limit', () async {
      // Create 5 entries but use cache size of 2
      final lines = List.generate(
        5,
        (i) => jsonEncode(_entry(requestId: 'r$i')),
      );
      final (path, index) = await writeAndIndex(lines.join('\n'));

      final reader = EntryReader(
        filePath: path,
        index: index,
        cacheSize: 2,
      );

      // Read entries 0-4 in order; only last 2 should be cached
      for (var i = 0; i < 5; i++) {
        await reader.readEntry(i);
      }

      // All entries should still be readable (cache miss -> re-read from file)
      final r0 = await reader.readEntry(0);
      expect(r0!.requestId, equals('r0'));
    });

    test('handles entry with duration_ms', () async {
      final json = _entry(durationMs: 42.5);
      final (path, index) = await writeAndIndex(jsonEncode(json));

      final reader = EntryReader(filePath: path, index: index);
      final record = await reader.readEntry(0);

      expect(record!.durationMs, equals(42.5));
    });

    test('preserves rawLine', () async {
      final json = _entry();
      final rawLine = jsonEncode(json);
      final (path, index) = await writeAndIndex(rawLine);

      final reader = EntryReader(filePath: path, index: index);
      final record = await reader.readEntry(0);

      expect(record!.rawLine, equals(rawLine));
    });
  });

  group('EntryReader.readRawLine', () {
    test('returns the raw JSON string', () async {
      final json = _entry(requestId: 'abc');
      final rawLine = jsonEncode(json);
      final (path, index) = await writeAndIndex(rawLine);

      final reader = EntryReader(filePath: path, index: index);
      final result = await reader.readRawLine(0);

      expect(result, equals(rawLine));
    });

    test('returns correct line from multi-line file', () async {
      final line0 = jsonEncode(_entry(requestId: 'r0'));
      final line1 = jsonEncode(_entry(requestId: 'r1'));
      final (path, index) = await writeAndIndex('$line0\n$line1');

      final reader = EntryReader(filePath: path, index: index);

      expect(await reader.readRawLine(0), equals(line0));
      expect(await reader.readRawLine(1), equals(line1));
    });

    test('handles UTF-8 content', () async {
      final json = {
        'ts': 't',
        'request_id': 'r',
        'record_type': 'rt',
        'msg': '\u00e9\u00e8\u00ea \u4e16\u754c',
      };
      final rawLine = jsonEncode(json);
      final (path, index) = await writeAndIndex(rawLine);

      final reader = EntryReader(filePath: path, index: index);
      final result = await reader.readRawLine(0);

      expect(result, equals(rawLine));
    });
  });
}
