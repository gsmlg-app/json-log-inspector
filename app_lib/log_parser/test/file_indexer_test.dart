import 'dart:convert';
import 'dart:io';

import 'package:log_parser/log_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_indexer_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String writeTempFile(String content, {String name = 'test.jsonl'}) {
    final path = '${tempDir.path}/$name';
    File(path).writeAsStringSync(content);
    return path;
  }

  Map<String, dynamic> _entry({
    String ts = '2024-01-01T00:00:00Z',
    String requestId = 'req-1',
    String recordType = 'request',
    double? durationMs,
    Map<String, dynamic>? extra,
  }) {
    return {
      'ts': ts,
      'request_id': requestId,
      'record_type': recordType,
      if (durationMs != null) 'duration_ms': durationMs,
      ...?extra,
    };
  }

  group('FileIndexer.indexFile', () {
    test('indexes a single valid JSON line', () async {
      final json = _entry();
      final path = writeTempFile(jsonEncode(json));

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(1));
      expect(result.validLines, equals(1));
      expect(result.invalidLines, equals(0));
      expect(result.lines, hasLength(1));
      expect(result.lines[0].offset, equals(0));
    });

    test('indexes multiple valid JSON lines', () async {
      final lines = [
        jsonEncode(_entry(requestId: 'r1')),
        jsonEncode(_entry(requestId: 'r2')),
        jsonEncode(_entry(requestId: 'r3')),
      ];
      final path = writeTempFile(lines.join('\n'));

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(3));
      expect(result.validLines, equals(3));
      expect(result.invalidLines, equals(0));
      expect(result.lines, hasLength(3));
    });

    test('tracks invalid JSON lines', () async {
      final valid = jsonEncode(_entry());
      final path = writeTempFile('not-json\n$valid\n{broken');

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(3));
      expect(result.validLines, equals(1));
      expect(result.invalidLines, equals(2));
    });

    test('skips empty lines', () async {
      final line = jsonEncode(_entry());
      final path = writeTempFile('$line\n\n$line');

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(2));
      expect(result.validLines, equals(2));
    });

    test('handles trailing newline', () async {
      final line = jsonEncode(_entry());
      final path = writeTempFile('$line\n');

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(1));
      expect(result.validLines, equals(1));
    });

    test('handles Windows line endings (CRLF)', () async {
      final lines = [
        jsonEncode(_entry(requestId: 'r1')),
        jsonEncode(_entry(requestId: 'r2')),
      ];
      final path = writeTempFile(lines.join('\r\n'));

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(2));
      expect(result.validLines, equals(2));
      // Verify the line lengths exclude the \r
      for (final line in result.lines) {
        final bytes = File(path).readAsBytesSync();
        final raw = utf8.decode(
          bytes.sublist(line.offset, line.offset + line.length),
        );
        // Should be valid JSON without trailing \r
        expect(() => jsonDecode(raw), returnsNormally);
      }
    });

    test('handles empty file', () async {
      final path = writeTempFile('');

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(0));
      expect(result.validLines, equals(0));
      expect(result.invalidLines, equals(0));
      expect(result.lines, isEmpty);
    });

    test('discovers key paths from entries', () async {
      final lines = [
        jsonEncode(
          _entry(
            extra: {
              'level': 'info',
              'nested': {'a': 1},
            },
          ),
        ),
      ];
      final path = writeTempFile(lines.join('\n'));

      final result = await FileIndexer.indexFile(path);

      expect(result.keyPaths, contains('ts'));
      expect(result.keyPaths, contains('request_id'));
      expect(result.keyPaths, contains('record_type'));
      expect(result.keyPaths, contains('level'));
      expect(result.keyPaths, contains('nested'));
      expect(result.keyPaths, contains('nested.a'));
    });

    test('includes known paths even if not present in entries', () async {
      final path = writeTempFile(jsonEncode(_entry()));

      final result = await FileIndexer.indexFile(path);

      // Known paths from KeyPathDiscovery.knownPaths should be present
      expect(result.keyPaths, contains('request.method'));
      expect(result.keyPaths, contains('response.status'));
    });

    test('builds request_id map', () async {
      final lines = [
        jsonEncode(_entry(requestId: 'abc')),
        jsonEncode(_entry(requestId: 'def')),
        jsonEncode(_entry(requestId: 'abc')),
      ];
      final path = writeTempFile(lines.join('\n'));

      final result = await FileIndexer.indexFile(path);

      expect(result.requestIdMap['abc'], equals([0, 2]));
      expect(result.requestIdMap['def'], equals([1]));
    });

    test('line offsets allow correct byte-level access', () async {
      final entry1 = jsonEncode(_entry(requestId: 'r1'));
      final entry2 = jsonEncode(_entry(requestId: 'r2'));
      final path = writeTempFile('$entry1\n$entry2');

      final result = await FileIndexer.indexFile(path);
      final bytes = File(path).readAsBytesSync();

      // Verify first line
      final line0 = result.lines[0];
      final raw0 = utf8.decode(
        bytes.sublist(line0.offset, line0.offset + line0.length),
      );
      expect(raw0, equals(entry1));

      // Verify second line
      final line1 = result.lines[1];
      final raw1 = utf8.decode(
        bytes.sublist(line1.offset, line1.offset + line1.length),
      );
      expect(raw1, equals(entry2));
    });

    test('samples at most 100 entries for key path discovery', () async {
      // Create 110 entries each with a unique extra key
      final lines = <String>[];
      for (var i = 0; i < 110; i++) {
        lines.add(jsonEncode(_entry(extra: {'key_$i': i})));
      }
      final path = writeTempFile(lines.join('\n'));

      final result = await FileIndexer.indexFile(path);

      expect(result.validLines, equals(110));
      // Keys from the first 100 entries should be present
      expect(result.keyPaths, contains('key_0'));
      expect(result.keyPaths, contains('key_99'));
      // Key from entry 100 should not be discovered (only first 100 sampled)
      expect(result.keyPaths, isNot(contains('key_100')));
    });

    test('handles file with only invalid lines', () async {
      final path = writeTempFile('not-json\nalso not json\n{broken');

      final result = await FileIndexer.indexFile(path);

      expect(result.totalLines, equals(3));
      expect(result.validLines, equals(0));
      expect(result.invalidLines, equals(3));
      expect(result.requestIdMap, isEmpty);
    });

    test('handles UTF-8 content correctly', () async {
      final json = _entry(
        extra: {'message': 'Hello \u00e9\u00e8\u00ea \u4e16\u754c'},
      );
      final path = writeTempFile(jsonEncode(json));

      final result = await FileIndexer.indexFile(path);

      expect(result.validLines, equals(1));
      // The byte offset + length should recover the original line
      final bytes = File(path).readAsBytesSync();
      final line = result.lines[0];
      final raw = utf8.decode(
        bytes.sublist(line.offset, line.offset + line.length),
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(
        decoded['message'],
        equals('Hello \u00e9\u00e8\u00ea \u4e16\u754c'),
      );
    });

    test(
      'does not include request_id map entry for non-string request_id',
      () async {
        // request_id is always a string in _entry, but let's write raw JSON
        final path = writeTempFile(
          '{"ts":"t","request_id":123,"record_type":"r"}',
        );

        final result = await FileIndexer.indexFile(path);

        expect(result.validLines, equals(1));
        expect(result.requestIdMap, isEmpty);
      },
    );
  });
}
