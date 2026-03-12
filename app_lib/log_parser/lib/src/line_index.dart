import 'package:meta/meta.dart';

/// Represents the position and size of a single line within a file.
@immutable
class LineIndex {
  /// Creates a [LineIndex] with the byte [offset] and [length] of the line.
  const LineIndex({required this.offset, required this.length});

  /// The byte offset from the start of the file where this line begins.
  final int offset;

  /// The length of this line in bytes (excluding the newline character).
  final int length;
}
