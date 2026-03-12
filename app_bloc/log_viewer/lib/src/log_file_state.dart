part of 'log_file_bloc.dart';

enum LogFileStatus { initial, loading, loaded, error }

class LogFileState extends Equatable {
  const LogFileState({
    this.status = LogFileStatus.initial,
    this.filePath,
    this.index,
    this.filteredIndices,
    this.keyPaths = const {},
    this.errorMessage,
    this.entryReader,
  });

  final LogFileStatus status;
  final String? filePath;
  final FileIndexResult? index;
  final List<int>? filteredIndices;
  final Set<String> keyPaths;
  final String? errorMessage;
  final EntryReader? entryReader;

  @override
  List<Object?> get props => [
    status,
    filePath,
    index,
    filteredIndices,
    keyPaths,
    errorMessage,
    entryReader,
  ];

  LogFileState copyWith({
    LogFileStatus? status,
    String? filePath,
    FileIndexResult? index,
    List<int>? Function()? filteredIndices,
    Set<String>? keyPaths,
    String? errorMessage,
    EntryReader? entryReader,
  }) {
    return LogFileState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      index: index ?? this.index,
      filteredIndices: filteredIndices != null
          ? filteredIndices()
          : this.filteredIndices,
      keyPaths: keyPaths ?? this.keyPaths,
      errorMessage: errorMessage ?? this.errorMessage,
      entryReader: entryReader ?? this.entryReader,
    );
  }
}
