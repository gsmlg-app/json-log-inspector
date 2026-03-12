import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:log_models/log_models.dart';

import 'file_index_result.dart';

/// Provides filtering and search capabilities for log records.
class FilterEngine {
  /// Returns `true` if [record] matches all enabled [rules].
  static bool matchesFilters(LogRecord record, List<FilterRule> rules) {
    final enabledRules = rules.where((r) => r.enabled).toList();
    if (enabledRules.isEmpty) return true;

    final json = jsonDecode(record.rawLine) as Map<String, dynamic>;
    for (final rule in enabledRules) {
      final value = getValueByPath(json, rule.keyPath);
      if (!_matchesRule(value, rule)) return false;
    }
    return true;
  }

  /// Returns `true` if [rawLine] contains [query] (case-insensitive).
  static bool matchesSearch(String rawLine, String query) {
    if (query.isEmpty) return true;
    return rawLine.toLowerCase().contains(query.toLowerCase());
  }

  /// Retrieves a value from a nested JSON map using a dot-separated
  /// [keyPath].
  ///
  /// For example, `getValueByPath({'a': {'b': 1}}, 'a.b')` returns `1`.
  static dynamic getValueByPath(Map<String, dynamic> json, String keyPath) {
    final parts = keyPath.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Builds a list of line indices that match the given [rules] and
  /// [searchQuery].
  ///
  /// For large files, the filtering runs in a separate isolate to avoid
  /// blocking the main thread.
  static Future<List<int>> buildFilteredIndex({
    required String filePath,
    required FileIndexResult index,
    required List<FilterRule> rules,
    required String searchQuery,
  }) async {
    if (index.lines.length > 1000) {
      return Isolate.run(
        () => _buildFilteredIndexSync(filePath, index, rules, searchQuery),
      );
    }
    return _buildFilteredIndexSync(filePath, index, rules, searchQuery);
  }

  static List<int> _buildFilteredIndexSync(
    String filePath,
    FileIndexResult index,
    List<FilterRule> rules,
    String searchQuery,
  ) {
    final enabledRules = rules.where((r) => r.enabled).toList();
    final hasRules = enabledRules.isNotEmpty;
    final hasSearch = searchQuery.isNotEmpty;

    if (!hasRules && !hasSearch) {
      return List.generate(index.lines.length, (i) => i);
    }

    final file = File(filePath);
    final raf = file.openSync();

    try {
      final result = <int>[];
      for (var i = 0; i < index.lines.length; i++) {
        final line = index.lines[i];
        raf.setPositionSync(line.offset);
        final bytes = raf.readSync(line.length);
        final rawLine = utf8.decode(bytes);

        if (hasSearch && !matchesSearch(rawLine, searchQuery)) continue;

        if (hasRules) {
          try {
            final json = jsonDecode(rawLine) as Map<String, dynamic>;
            if (!_matchesFiltersFromJson(json, enabledRules)) continue;
          } on Object {
            continue;
          }
        }

        result.add(i);
      }
      return result;
    } finally {
      raf.closeSync();
    }
  }

  /// Matches filters directly from parsed JSON to avoid double-parsing.
  static bool _matchesFiltersFromJson(
    Map<String, dynamic> json,
    List<FilterRule> enabledRules,
  ) {
    for (final rule in enabledRules) {
      final value = getValueByPath(json, rule.keyPath);
      if (!_matchesRule(value, rule)) return false;
    }
    return true;
  }

  static bool _matchesRule(dynamic value, FilterRule rule) {
    switch (rule.operator) {
      case FilterOperator.exists:
        return value != null;
      case FilterOperator.equals:
        return value?.toString() == rule.value;
      case FilterOperator.notEquals:
        if (value == null) return false;
        return value.toString() != rule.value;
      case FilterOperator.contains:
        return value?.toString().contains(rule.value) ?? false;
      case FilterOperator.greaterThan:
        return _compareNumeric(value, rule.value, (cmp) => cmp > 0);
      case FilterOperator.lessThan:
        return _compareNumeric(value, rule.value, (cmp) => cmp < 0);
      case FilterOperator.greaterThanOrEqual:
        return _compareNumeric(value, rule.value, (cmp) => cmp >= 0);
      case FilterOperator.lessThanOrEqual:
        return _compareNumeric(value, rule.value, (cmp) => cmp <= 0);
      case FilterOperator.regex:
        if (value == null) return false;
        try {
          return RegExp(rule.value).hasMatch(value.toString());
        } on FormatException {
          return false;
        }
    }
  }

  static bool _compareNumeric(
    dynamic value,
    String ruleValue,
    bool Function(int) test,
  ) {
    final a = double.tryParse(value?.toString() ?? '');
    final b = double.tryParse(ruleValue);
    if (a == null || b == null) return false;
    return test(a.compareTo(b));
  }
}
