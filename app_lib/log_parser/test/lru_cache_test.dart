import 'package:log_parser/log_parser.dart';
import 'package:test/test.dart';

void main() {
  group('LruCache', () {
    test('stores and retrieves values', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('returns null for missing keys', () {
      final cache = LruCache<String, int>(maxSize: 3);
      expect(cache.get('missing'), isNull);
    });

    test('evicts least recently used entry when full', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.put('d', 4); // should evict 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
      expect(cache.get('d'), 4);
      expect(cache.length, 3);
    });

    test('accessing a key promotes it and prevents eviction', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Access 'a' to promote it
      cache.get('a');

      cache.put('d', 4); // should evict 'b' (now least recently used)

      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
      expect(cache.get('d'), 4);
    });

    test('updating an existing key does not increase size', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('a', 10);

      expect(cache.get('a'), 10);
      expect(cache.length, 2);
    });

    test('clear removes all entries', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();

      expect(cache.length, 0);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });

    test('reports correct length', () {
      final cache = LruCache<String, int>(maxSize: 5);
      expect(cache.length, 0);

      cache.put('a', 1);
      expect(cache.length, 1);

      cache.put('b', 2);
      expect(cache.length, 2);
    });
  });
}
