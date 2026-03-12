part of 'selection_bloc.dart';

class SelectionState extends Equatable {
  const SelectionState({
    this.selectedIndex,
    this.selectedRecord,
    this.pairedRecord,
  });

  final int? selectedIndex;
  final LogRecord? selectedRecord;
  final LogRecord? pairedRecord;

  @override
  List<Object?> get props => [selectedIndex, selectedRecord, pairedRecord];

  SelectionState copyWith({
    int? Function()? selectedIndex,
    LogRecord? Function()? selectedRecord,
    LogRecord? Function()? pairedRecord,
  }) {
    return SelectionState(
      selectedIndex: selectedIndex != null
          ? selectedIndex()
          : this.selectedIndex,
      selectedRecord: selectedRecord != null
          ? selectedRecord()
          : this.selectedRecord,
      pairedRecord: pairedRecord != null ? pairedRecord() : this.pairedRecord,
    );
  }
}
