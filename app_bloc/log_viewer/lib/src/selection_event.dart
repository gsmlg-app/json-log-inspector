part of 'selection_bloc.dart';

sealed class SelectionEvent {
  const SelectionEvent();
}

final class EntrySelected extends SelectionEvent {
  final int index;
  final LogRecord record;
  final LogRecord? pairedRecord;

  const EntrySelected({
    required this.index,
    required this.record,
    this.pairedRecord,
  });
}

final class SelectionCleared extends SelectionEvent {
  const SelectionCleared();
}
