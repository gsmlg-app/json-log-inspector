import 'package:log_parser/log_parser.dart';
import 'package:test/test.dart';

void main() {
  group('KeyPathDiscovery.discoverPaths', () {
    test('discovers top-level keys', () {
      final paths = KeyPathDiscovery.discoverPaths({'a': 1, 'b': 2});
      expect(paths, equals({'a', 'b'}));
    });

    test('discovers nested keys with dot notation', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'a': {'b': 1},
      });
      expect(paths, containsAll(['a', 'a.b']));
    });

    test('discovers deeply nested keys', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'a': {
          'b': {'c': {'d': 1}},
        },
      });
      expect(paths, containsAll(['a', 'a.b', 'a.b.c', 'a.b.c.d']));
    });

    test('handles flat map with no nesting', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'x': 1,
        'y': 'hello',
        'z': true,
      });
      expect(paths, equals({'x', 'y', 'z'}));
    });

    test('handles empty map', () {
      final paths = KeyPathDiscovery.discoverPaths({});
      expect(paths, isEmpty);
    });

    test('handles prefix parameter', () {
      final paths = KeyPathDiscovery.discoverPaths({'key': 1}, 'root');
      expect(paths, contains('root.key'));
    });

    test('does not recurse into non-map values', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'list': [1, 2, 3],
        'string': 'hello',
        'number': 42,
        'bool': true,
        'null_val': null,
      });
      expect(
        paths,
        equals({'list', 'string', 'number', 'bool', 'null_val'}),
      );
    });

    test('handles mixed nested and flat keys', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'flat': 1,
        'nested': {'inner': 2},
      });
      expect(paths, containsAll(['flat', 'nested', 'nested.inner']));
    });

    test('handles multiple nested branches', () {
      final paths = KeyPathDiscovery.discoverPaths({
        'request': {'method': 'GET', 'uri': '/api'},
        'response': {'status': 200},
      });
      expect(
        paths,
        containsAll([
          'request',
          'request.method',
          'request.uri',
          'response',
          'response.status',
        ]),
      );
    });
  });

  group('KeyPathDiscovery.discoverFromEntries', () {
    test('merges paths from multiple entries', () {
      final entries = [
        {'a': 1, 'b': 2},
        {'b': 3, 'c': 4},
      ];
      final paths = KeyPathDiscovery.discoverFromEntries(entries);

      expect(paths, containsAll(['a', 'b', 'c']));
    });

    test('includes known paths even with empty entries', () {
      final paths = KeyPathDiscovery.discoverFromEntries([]);

      for (final known in KeyPathDiscovery.knownPaths) {
        expect(paths, contains(known));
      }
    });

    test('includes known paths with entries', () {
      final entries = [
        {'custom_key': 'value'},
      ];
      final paths = KeyPathDiscovery.discoverFromEntries(entries);

      expect(paths, contains('custom_key'));
      expect(paths, contains('ts'));
      expect(paths, contains('request.method'));
      expect(paths, contains('response.status'));
    });

    test('merges nested paths from different entries', () {
      final entries = [
        {
          'request': {'method': 'GET'},
        },
        {
          'request': {'uri': '/api'},
        },
      ];
      final paths = KeyPathDiscovery.discoverFromEntries(entries);

      expect(paths, containsAll(['request', 'request.method', 'request.uri']));
    });

    test('returns a set (no duplicates)', () {
      final entries = [
        {'a': 1},
        {'a': 2},
        {'a': 3},
      ];
      final paths = KeyPathDiscovery.discoverFromEntries(entries);

      // 'a' should appear exactly once; it's a Set so by definition no dupes
      expect(paths.where((p) => p == 'a').length, equals(1));
    });
  });

  group('KeyPathDiscovery.knownPaths', () {
    test('contains expected paths', () {
      expect(
        KeyPathDiscovery.knownPaths,
        containsAll([
          'ts',
          'request_id',
          'record_type',
          'duration_ms',
          'request.method',
          'request.uri',
          'request.host',
          'response.status',
          'request.content_type',
          'response.content_type',
        ]),
      );
    });

    test('has exactly 10 known paths', () {
      expect(KeyPathDiscovery.knownPaths, hasLength(10));
    });
  });
}
