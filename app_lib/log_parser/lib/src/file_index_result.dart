import 'package:meta/meta.dart';

import 'line_index.dart';

/// The result of indexing a JSONL file.
///
/// Contains the line offset index, statistics about the file contents,
/// discovered key paths, and an SSE pairing map.
@immutable
class FileIndexResult {
  /// Creates a [FileIndexResult].
  const FileIndexResult({
    required this.lines,
    required this.totalLines,
    required this.validLines,
    required this.invalidLines,
    required this.keyPaths,
    required this.requestIdMap,
  });

  /// The byte-offset index for each line in the file.
  final List<LineIndex> lines;

  /// The total number of lines found in the file.
  final int totalLines;

  /// The number of lines that contain valid JSON.
  final int validLines;

  /// The number of lines that do not contain valid JSON.
  final int invalidLines;

  /// The set of discovered dot-separated key paths from the file entries.
  final Set<String> keyPaths;

  /// Maps `request_id` values to the list of line indices that share
  /// that request ID, enabling SSE pairing.
  final Map<String, List<int>> requestIdMap;
}
