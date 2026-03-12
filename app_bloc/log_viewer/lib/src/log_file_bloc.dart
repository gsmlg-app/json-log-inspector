import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:log_parser/log_parser.dart';

part 'log_file_event.dart';
part 'log_file_state.dart';

class LogFileBloc extends Bloc<LogFileEvent, LogFileState> {
  LogFileBloc() : super(const LogFileState()) {
    on<FileOpened>(_onFileOpened);
    on<Cleared>(_onCleared);
    on<FilterApplied>(_onFilterApplied);
  }

  Future<void> _onFileOpened(
    FileOpened event,
    Emitter<LogFileState> emitter,
  ) async {
    emitter(
      state.copyWith(status: LogFileStatus.loading, filePath: event.path),
    );

    try {
      final index = await FileIndexer.indexFile(event.path);
      final entryReader = EntryReader(filePath: event.path, index: index);

      emitter(
        state.copyWith(
          status: LogFileStatus.loaded,
          index: index,
          keyPaths: index.keyPaths,
          entryReader: entryReader,
        ),
      );
    } on Exception catch (e) {
      emitter(
        state.copyWith(status: LogFileStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onCleared(Cleared event, Emitter<LogFileState> emitter) {
    emitter(const LogFileState());
  }

  void _onFilterApplied(FilterApplied event, Emitter<LogFileState> emitter) {
    emitter(state.copyWith(filteredIndices: () => event.filteredIndices));
  }
}
