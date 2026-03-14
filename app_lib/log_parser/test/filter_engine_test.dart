import 'dart:convert';
import 'dart:io';

import 'package:log_models/log_models.dart';
import 'package:log_parser/log_parser.dart';
import 'package:test/test.dart';

/// Helper to build a minimal valid LogRecord from a JSON map.
LogRecord _record(Map<String, dynamic> json) {
  final raw = jsonEncode(json);
  return LogRecord.fromJson(json, rawLine: raw);
}

/// Helper to build a minimal JSON map with the required LogRecord fields.
Map<String, dynamic> _minJson({
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

FilterRule _rule({
  String keyPath = 'record_type',
  FilterOperator operator = FilterOperator.equals,
  String value = 'request',
  bool enabled = true,
  String id = 'r1',
}) {
  return FilterRule(
    id: id,
    keyPath: keyPath,
    operator: operator,
    value: value,
    enabled: enabled,
  );
}

void main() {
  group('FilterEngine.matchesSearch', () {
    test('returns true when query is empty', () {
      expect(FilterEngine.matchesSearch('anything', ''), isTrue);
    });

    test('returns true for case-insensitive match', () {
      expect(FilterEngine.matchesSearch('Hello World', 'hello'), isTrue);
    });

    test('returns false when not found', () {
      expect(FilterEngine.matchesSearch('Hello', 'xyz'), isFalse);
    });

    test('handles special characters in raw line', () {
      expect(FilterEngine.matchesSearch('{"key":"val"}', '"key"'), isTrue);
    });
  });

  group('FilterEngine.getValueByPath', () {
    test('returns top-level value', () {
      expect(FilterEngine.getValueByPath({'a': 1}, 'a'), equals(1));
    });

    test('returns nested value', () {
      expect(
        FilterEngine.getValueByPath({
          'a': {
            'b': {'c': 42},
          },
        }, 'a.b.c'),
        equals(42),
      );
    });

    test('returns null for missing top-level key', () {
      expect(FilterEngine.getValueByPath({'a': 1}, 'b'), isNull);
    });

    test('returns null for missing nested key', () {
      expect(
        FilterEngine.getValueByPath({
          'a': {'b': 1},
        }, 'a.c'),
        isNull,
      );
    });

    test('returns null when traversing through a non-map value', () {
      expect(FilterEngine.getValueByPath({'a': 'string'}, 'a.b'), isNull);
    });

    test('returns the map itself for intermediate path', () {
      final inner = {'b': 1};
      expect(FilterEngine.getValueByPath({'a': inner}, 'a'), equals(inner));
    });

    test('returns null value when key exists but value is null', () {
      expect(FilterEngine.getValueByPath({'a': null}, 'a'), isNull);
    });
  });

  group('FilterEngine.matchesFilters', () {
    group('FilterOperator.equals', () {
      test('matches when value equals rule value', () {
        final record = _record(_minJson(recordType: 'request'));
        final rules = [_rule(value: 'request')];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when value differs', () {
        final record = _record(_minJson(recordType: 'response'));
        final rules = [_rule(value: 'request')];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.notEquals', () {
      test('matches when value differs', () {
        final record = _record(_minJson(recordType: 'response'));
        final rules = [
          _rule(operator: FilterOperator.notEquals, value: 'request'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when value equals', () {
        final record = _record(_minJson(recordType: 'request'));
        final rules = [
          _rule(operator: FilterOperator.notEquals, value: 'request'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.contains', () {
      test('matches substring', () {
        final record = _record(_minJson(recordType: 'request_start'));
        final rules = [
          _rule(operator: FilterOperator.contains, value: 'request'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when substring absent', () {
        final record = _record(_minJson(recordType: 'response'));
        final rules = [
          _rule(operator: FilterOperator.contains, value: 'request'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });

      test('returns false when value is null', () {
        final json = _minJson(extra: {'level': null});
        // Override rawLine to include the null field
        final rawLine = jsonEncode(json);
        final record = LogRecord.fromJson(json, rawLine: rawLine);
        final rules = [
          _rule(
            keyPath: 'level',
            operator: FilterOperator.contains,
            value: 'x',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.exists', () {
      test('matches when key exists', () {
        final record = _record(_minJson());
        final rules = [
          _rule(
            keyPath: 'record_type',
            operator: FilterOperator.exists,
            value: '',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when key is absent', () {
        final record = _record(_minJson());
        final rules = [
          _rule(
            keyPath: 'nonexistent',
            operator: FilterOperator.exists,
            value: '',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.greaterThan', () {
      test('matches when numeric value is greater', () {
        final record = _record(_minJson(durationMs: 100));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when equal', () {
        final record = _record(_minJson(durationMs: 50));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });

      test('does not match when less', () {
        final record = _record(_minJson(durationMs: 10));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.lessThan', () {
      test('matches when numeric value is less', () {
        final record = _record(_minJson(durationMs: 10));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.lessThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when equal', () {
        final record = _record(_minJson(durationMs: 50));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.lessThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.greaterThanOrEqual', () {
      test('matches when equal', () {
        final record = _record(_minJson(durationMs: 50));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('matches when greater', () {
        final record = _record(_minJson(durationMs: 100));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when less', () {
        final record = _record(_minJson(durationMs: 10));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.lessThanOrEqual', () {
      test('matches when equal', () {
        final record = _record(_minJson(durationMs: 50));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.lessThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('matches when less', () {
        final record = _record(_minJson(durationMs: 10));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.lessThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when greater', () {
        final record = _record(_minJson(durationMs: 100));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.lessThanOrEqual,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('FilterOperator.regex', () {
      test('matches valid regex', () {
        final record = _record(_minJson(recordType: 'request_start'));
        final rules = [
          _rule(operator: FilterOperator.regex, value: r'^request_\w+$'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('does not match when regex fails', () {
        final record = _record(_minJson(recordType: 'response'));
        final rules = [
          _rule(operator: FilterOperator.regex, value: r'^request'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });

      test('returns false for invalid regex', () {
        final record = _record(_minJson(recordType: 'request'));
        final rules = [
          _rule(operator: FilterOperator.regex, value: r'[invalid'),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });

      test('handles null value with regex', () {
        final record = _record(_minJson());
        final rules = [
          _rule(
            keyPath: 'nonexistent',
            operator: FilterOperator.regex,
            value: '.*',
          ),
        ];
        // null value should not match regex
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('numeric comparison edge cases', () {
      test('non-numeric value returns 0 from compare (treated as equal)', () {
        final record = _record(_minJson(recordType: 'abc'));
        // Comparing string 'abc' > '50' -- both parse fails, returns 0
        final rules = [
          _rule(
            keyPath: 'record_type',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });

      test('non-numeric rule value returns 0 from compare', () {
        final record = _record(_minJson(durationMs: 100));
        final rules = [
          _rule(
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: 'abc',
          ),
        ];
        // a = 100, b = null -> returns 0 -> 0 > 0 is false
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('multiple rules', () {
      test('all rules must match (AND logic)', () {
        final json = _minJson(recordType: 'request', durationMs: 100);
        final record = _record(json);
        final rules = [
          _rule(value: 'request'),
          _rule(
            id: 'r2',
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('fails if any rule does not match', () {
        final json = _minJson(recordType: 'request', durationMs: 10);
        final record = _record(json);
        final rules = [
          _rule(value: 'request'),
          _rule(
            id: 'r2',
            keyPath: 'duration_ms',
            operator: FilterOperator.greaterThan,
            value: '50',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isFalse);
      });
    });

    group('disabled rules', () {
      test('disabled rules are ignored', () {
        final record = _record(_minJson(recordType: 'response'));
        final rules = [_rule(value: 'request', enabled: false)];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });

      test('returns true when all rules are disabled', () {
        final record = _record(_minJson());
        final rules = [
          _rule(enabled: false),
          _rule(id: 'r2', keyPath: 'nonexistent', enabled: false),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });
    });

    test('returns true when rules list is empty', () {
      final record = _record(_minJson());
      expect(FilterEngine.matchesFilters(record, []), isTrue);
    });

    group('nested key paths in filters', () {
      test('filters on nested key path', () {
        final json = _minJson(
          extra: {
            'request': {
              'method': 'GET',
              'scheme': 'https',
              'host': 'example.com',
              'uri': '/api',
              'proto': 'HTTP/1.1',
              'remote_addr': '127.0.0.1',
            },
          },
        );
        final record = _record(json);
        final rules = [
          _rule(
            keyPath: 'request.method',
            operator: FilterOperator.equals,
            value: 'GET',
          ),
        ];
        expect(FilterEngine.matchesFilters(record, rules), isTrue);
      });
    });
  });

  group('FilterEngine.buildFilteredIndex', () {
    late Directory tempDir;
    late String filePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('filter_engine_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    FileIndexResult _writeAndIndex(List<String> jsonLines) {
      filePath = '${tempDir.path}/test.jsonl';
      final content = jsonLines.join('\n');
      File(filePath).writeAsStringSync(content);

      // Build LineIndex manually
      final bytes = File(filePath).readAsBytesSync();
      final lines = <LineIndex>[];
      var lineStart = 0;
      for (var i = 0; i <= bytes.length; i++) {
        if (i == bytes.length || bytes[i] == 0x0A) {
          final length = i - lineStart;
          if (length > 0) {
            lines.add(LineIndex(offset: lineStart, length: length));
          }
          lineStart = i + 1;
        }
      }

      return FileIndexResult(
        lines: lines,
        totalLines: lines.length,
        validLines: lines.length,
        invalidLines: 0,
        keyPaths: {},
        requestIdMap: {},
      );
    }

    test('returns all indices when no filters and no search', () async {
      final jsonLines = [
        jsonEncode(_minJson(requestId: 'r1')),
        jsonEncode(_minJson(requestId: 'r2')),
        jsonEncode(_minJson(requestId: 'r3')),
      ];
      final index = _writeAndIndex(jsonLines);
      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [],
        searchQuery: '',
      );
      expect(result, equals([0, 1, 2]));
    });

    test('filters by search query', () async {
      final jsonLines = [
        jsonEncode(_minJson(requestId: 'abc')),
        jsonEncode(_minJson(requestId: 'def')),
        jsonEncode(_minJson(requestId: 'abcdef')),
      ];
      final index = _writeAndIndex(jsonLines);
      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [],
        searchQuery: 'abc',
      );
      expect(result, equals([0, 2]));
    });

    test('filters by rules', () async {
      final jsonLines = [
        jsonEncode(_minJson(recordType: 'request')),
        jsonEncode(_minJson(recordType: 'response')),
        jsonEncode(_minJson(recordType: 'request')),
      ];
      final index = _writeAndIndex(jsonLines);
      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [_rule(value: 'request')],
        searchQuery: '',
      );
      expect(result, equals([0, 2]));
    });

    test('combines search and rules', () async {
      final jsonLines = [
        jsonEncode(_minJson(recordType: 'request', requestId: 'abc')),
        jsonEncode(_minJson(recordType: 'response', requestId: 'abc')),
        jsonEncode(_minJson(recordType: 'request', requestId: 'def')),
      ];
      final index = _writeAndIndex(jsonLines);
      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [_rule(value: 'request')],
        searchQuery: 'abc',
      );
      expect(result, equals([0]));
    });

    test('skips lines that fail JSON parsing', () async {
      filePath = '${tempDir.path}/test.jsonl';
      final validLine = jsonEncode(_minJson(recordType: 'request'));
      File(filePath).writeAsStringSync('not-json\n$validLine');

      final bytes = File(filePath).readAsBytesSync();
      final lines = <LineIndex>[];
      var lineStart = 0;
      for (var i = 0; i <= bytes.length; i++) {
        if (i == bytes.length || bytes[i] == 0x0A) {
          final length = i - lineStart;
          if (length > 0) {
            lines.add(LineIndex(offset: lineStart, length: length));
          }
          lineStart = i + 1;
        }
      }

      final index = FileIndexResult(
        lines: lines,
        totalLines: lines.length,
        validLines: 1,
        invalidLines: 1,
        keyPaths: {},
        requestIdMap: {},
      );

      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [_rule(value: 'request')],
        searchQuery: '',
      );
      // The invalid JSON line (index 0) should be skipped
      expect(result, equals([1]));
    });

    test('disabled rules do not filter anything', () async {
      final jsonLines = [
        jsonEncode(_minJson(recordType: 'request')),
        jsonEncode(_minJson(recordType: 'response')),
      ];
      final index = _writeAndIndex(jsonLines);
      final result = await FilterEngine.buildFilteredIndex(
        filePath: filePath,
        index: index,
        rules: [_rule(value: 'request', enabled: false)],
        searchQuery: '',
      );
      expect(result, equals([0, 1]));
    });
  });
}
