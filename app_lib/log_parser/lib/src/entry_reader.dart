import 'dart:convert';
import 'dart:io';

import 'package:log_models/log_models.dart';

import 'file_index_result.dart';
import 'lru_cache.dart';

/// Reads individual log entries on demand using random file access.
///
/// Parsed [LogRecord] instances are cached in an LRU cache to avoid
/// redundant I/O and parsing for recently accessed entries.
///
/// Call [dispose] when the reader is no longer needed to release the
/// file handle.
class EntryReader {
  /// Creates an [EntryReader] for the file at [filePath] using the
  /// given [index]. The [cacheSize] controls how many parsed records
  /// are kept in memory.
  EntryReader({
    required this.filePath,
    required this.index,
    int cacheSize = 500,
  }) : _cache = LruCache<int, LogRecord>(maxSize: cacheSize),
       _rawLineCache = LruCache<int, String>(maxSize: cacheSize);

  /// The path to the JSONL file.
  final String filePath;

  /// The file index used for random access.
  final FileIndexResult index;

  final LruCache<int, LogRecord> _cache;
  final LruCache<int, String> _rawLineCache;

  RandomAccessFile? _raf;

  Future<RandomAccessFile> _getHandle() async {
    _raf ??= await File(filePath).open();
    return _raf!;
  }

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
    } on Exception {
      return null;
    }
  }

  /// Reads the raw line text at [lineIndex] from the file.
  Future<String> readRawLine(int lineIndex) async {
    final cachedLine = _rawLineCache.get(lineIndex);
    if (cachedLine != null) return cachedLine;

    final line = index.lines[lineIndex];
    final raf = await _getHandle();
    await raf.setPosition(line.offset);
    final bytes = await raf.read(line.length);
    final text = utf8.decode(bytes);
    _rawLineCache.put(lineIndex, text);
    return text;
  }

  /// Releases the file handle. Safe to call multiple times.
  Future<void> dispose() async {
    await _raf?.close();
    _raf = null;
    _cache.clear();
    _rawLineCache.clear();
  }
}
