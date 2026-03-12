/// A generic Least Recently Used (LRU) cache backed by [LinkedHashMap].
///
/// Both [get] and [put] are O(1). Evicts the least recently accessed
/// entry when [maxSize] is exceeded.
class LruCache<K, V> {
  /// Creates an LRU cache with the given [maxSize].
  LruCache({this.maxSize = 500});

  /// The maximum number of entries the cache can hold.
  final int maxSize;

  final _cache = <K, V>{};

  /// Returns the value for [key], or `null` if not present.
  ///
  /// Promotes the key to the most recently used position.
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      return value;
    }
    return null;
  }

  /// Adds or updates [key] with [value].
  ///
  /// If the cache exceeds [maxSize], the least recently used entry is evicted.
  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// The number of entries currently in the cache.
  int get length => _cache.length;
}
