import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:log_models/log_models.dart';

part 'selection_event.dart';
part 'selection_state.dart';

class SelectionBloc extends Bloc<SelectionEvent, SelectionState> {
  SelectionBloc() : super(const SelectionState()) {
    on<EntrySelected>(_onEntrySelected);
    on<SelectionCleared>(_onSelectionCleared);
  }

  void _onEntrySelected(EntrySelected event, Emitter<SelectionState> emitter) {
    emitter(state.copyWith(
      selectedIndex: () => event.index,
      selectedRecord: () => event.record,
      pairedRecord: () => event.pairedRecord,
    ));
  }

  void _onSelectionCleared(
    SelectionCleared event,
    Emitter<SelectionState> emitter,
  ) {
    emitter(const SelectionState());
  }
}
