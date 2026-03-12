part of 'selection_bloc.dart';

sealed class SelectionEvent {
  const SelectionEvent();
}

final class EntrySelected extends SelectionEvent {
  final int index;

  const EntrySelected(this.index);
}

final class SelectionCleared extends SelectionEvent {
  const SelectionCleared();
}
