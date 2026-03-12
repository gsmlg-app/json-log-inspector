/// A generic Least Recently Used (LRU) cache.
///
/// Evicts the least recently accessed entry when [maxSize] is exceeded.
class LruCache<K, V> {
  /// Creates an LRU cache with the given [maxSize].
  LruCache({this.maxSize = 500});

  /// The maximum number of entries the cache can hold.
  final int maxSize;

  final _cache = <K, V>{};
  final _order = <K>[];

  /// Returns the value for [key], or `null` if not present.
  ///
  /// Promotes the key to the most recently used position.
  V? get(K key) {
    if (_cache.containsKey(key)) {
      _order.remove(key);
      _order.add(key);
      return _cache[key];
    }
    return null;
  }

  /// Adds or updates [key] with [value].
  ///
  /// If the cache exceeds [maxSize], the least recently used entry is evicted.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _order.remove(key);
    } else if (_cache.length >= maxSize) {
      final evicted = _order.removeAt(0);
      _cache.remove(evicted);
    }
    _cache[key] = value;
    _order.add(key);
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
    _order.clear();
  }

  /// The number of entries currently in the cache.
  int get length => _cache.length;
}
