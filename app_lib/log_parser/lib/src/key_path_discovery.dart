/// Utilities for discovering dot-separated key paths from JSON maps.
class KeyPathDiscovery {
  /// Known top-level paths that are always included in discovery results.
  static const Set<String> knownPaths = {
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
  };

  /// Recursively walks a parsed JSON map collecting all dot-separated key
  /// paths.
  ///
  /// If [prefix] is provided, it is prepended to each discovered path.
  static Set<String> discoverPaths(
    Map<String, dynamic> json, [
    String prefix = '',
  ]) {
    final paths = <String>{};
    for (final entry in json.entries) {
      final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      paths.add(path);
      if (entry.value is Map<String, dynamic>) {
        paths.addAll(discoverPaths(entry.value as Map<String, dynamic>, path));
      }
    }
    return paths;
  }

  /// Discovers key paths from multiple JSON entries and merges them with
  /// [knownPaths].
  static Set<String> discoverFromEntries(List<Map<String, dynamic>> entries) {
    final paths = <String>{...knownPaths};
    for (final entry in entries) {
      paths.addAll(discoverPaths(entry));
    }
    return paths;
  }
}
