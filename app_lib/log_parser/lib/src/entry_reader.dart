import 'dart:convert';
import 'dart:io';

import 'package:log_models/log_models.dart';

import 'file_index_result.dart';
import 'lru_cache.dart';

/// Reads individual log entries on demand using random file access.
///
/// Parsed [LogRecord] instances are cached in an LRU cache to avoid
/// redundant I/O and parsing for recently accessed entries.
class EntryReader {
  /// Creates an [EntryReader] for the file at [filePath] using the
  /// given [index]. The [cacheSize] controls how many parsed records
  /// are kept in memory.
  EntryReader({
    required this.filePath,
    required this.index,
    int cacheSize = 500,
  }) : _cache = LruCache<int, LogRecord>(maxSize: cacheSize);

  /// The path to the JSONL file.
  final String filePath;

  /// The file index used for random access.
  final FileIndexResult index;

  final LruCache<int, LogRecord> _cache;

  /// Reads and parses the log entry at [lineIndex].
  ///
  /// Returns `null` if the line cannot be parsed as a valid JSON log record.
  Future<LogRecord?> readEntry(int lineIndex) async {
    final cached = _cache.get(lineIndex);
    if (cached != null) return cached;

    final rawLine = await readRawLine(lineIndex);
    try {
      final json = jsonDecode(rawLine) as Map<String, dynamic>;
      final record = LogRecord.fromJson(json, rawLine: rawLine);
      _cache.put(lineIndex, record);
      return record;
    } on Object {
      return null;
    }
  }

  /// Reads the raw line text at [lineIndex] from the file.
  Future<String> readRawLine(int lineIndex) async {
    final line = index.lines[lineIndex];
    final raf = await File(filePath).open();
    try {
      await raf.setPosition(line.offset);
      final bytes = await raf.read(line.length);
      return utf8.decode(bytes);
    } finally {
      await raf.close();
    }
  }
}
