part of 'log_file_bloc.dart';

sealed class LogFileEvent {
  const LogFileEvent();
}

final class FileOpened extends LogFileEvent {
  final String path;

  const FileOpened(this.path);
}

final class Cleared extends LogFileEvent {
  const Cleared();
}

final class FilterApplied extends LogFileEvent {
  final List<int> filteredIndices;

  const FilterApplied(this.filteredIndices);
}
