import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_models/log_models.dart';
import 'package:log_viewer_bloc/log_viewer_bloc.dart';

void main() {
  const sampleRecord = LogRecord(
    ts: '2024-01-01T00:00:00Z',
    requestId: 'req-1',
    recordType: 'request',
    rawLine: '{"ts":"2024-01-01T00:00:00Z","request_id":"req-1"}',
  );

  const pairedRecord = LogRecord(
    ts: '2024-01-01T00:00:01Z',
    requestId: 'req-1',
    recordType: 'response',
    durationMs: 150.0,
    rawLine: '{"ts":"2024-01-01T00:00:01Z","request_id":"req-1"}',
  );

  group('SelectionBloc', () {
    group('initial state', () {
      test('has null selectedIndex, selectedRecord, and pairedRecord', () {
        final bloc = SelectionBloc();
        expect(bloc.state.selectedIndex, isNull);
        expect(bloc.state.selectedRecord, isNull);
        expect(bloc.state.pairedRecord, isNull);
        bloc.close();
      });
    });

    group('EntrySelected', () {
      blocTest<SelectionBloc, SelectionState>(
        'sets selectedIndex',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const EntrySelected(5)),
        expect: () => [
          const SelectionState(selectedIndex: 5),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'updates selectedIndex when selecting a different entry',
        build: SelectionBloc.new,
        seed: () => const SelectionState(selectedIndex: 3),
        act: (bloc) => bloc.add(const EntrySelected(7)),
        expect: () => [
          const SelectionState(selectedIndex: 7),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting the same index emits state with same index',
        build: SelectionBloc.new,
        seed: () => const SelectionState(selectedIndex: 5),
        act: (bloc) => bloc.add(const EntrySelected(5)),
        // Equatable means same state is not re-emitted
        expect: () => <SelectionState>[],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting index 0 works correctly',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const EntrySelected(0)),
        expect: () => [
          const SelectionState(selectedIndex: 0),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting entry preserves existing selectedRecord and pairedRecord',
        build: SelectionBloc.new,
        seed: () => const SelectionState(
          selectedIndex: 1,
          selectedRecord: sampleRecord,
          pairedRecord: pairedRecord,
        ),
        act: (bloc) => bloc.add(const EntrySelected(2)),
        expect: () => [
          const SelectionState(
            selectedIndex: 2,
            selectedRecord: sampleRecord,
            pairedRecord: pairedRecord,
          ),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting multiple entries in sequence tracks the last one',
        build: SelectionBloc.new,
        act: (bloc) {
          bloc
            ..add(const EntrySelected(1))
            ..add(const EntrySelected(2))
            ..add(const EntrySelected(3));
        },
        expect: () => [
          const SelectionState(selectedIndex: 1),
          const SelectionState(selectedIndex: 2),
          const SelectionState(selectedIndex: 3),
        ],
      );
    });

    group('SelectionCleared', () {
      blocTest<SelectionBloc, SelectionState>(
        'resets state to initial values',
        build: SelectionBloc.new,
        seed: () => const SelectionState(selectedIndex: 5),
        act: (bloc) => bloc.add(const SelectionCleared()),
        expect: () => [
          const SelectionState(),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'clears selectedRecord and pairedRecord',
        build: SelectionBloc.new,
        seed: () => const SelectionState(
          selectedIndex: 1,
          selectedRecord: sampleRecord,
          pairedRecord: pairedRecord,
        ),
        act: (bloc) => bloc.add(const SelectionCleared()),
        expect: () => [
          const SelectionState(),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'clearing already cleared state still emits (new instance)',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const SelectionCleared()),
        expect: () => [const SelectionState()],
      );
    });

    group('SelectionState', () {
      test('copyWith selectedIndex nullable via function', () {
        const state = SelectionState(selectedIndex: 5);
        final cleared = state.copyWith(selectedIndex: () => null);
        expect(cleared.selectedIndex, isNull);
      });

      test('copyWith preserves fields when not specified', () {
        const state = SelectionState(
          selectedIndex: 3,
          selectedRecord: sampleRecord,
          pairedRecord: pairedRecord,
        );
        final updated = state.copyWith(selectedIndex: () => 10);
        expect(updated.selectedIndex, 10);
        expect(updated.selectedRecord, sampleRecord);
        expect(updated.pairedRecord, pairedRecord);
      });

      test('copyWith selectedRecord nullable via function', () {
        const state = SelectionState(selectedRecord: sampleRecord);
        final cleared = state.copyWith(selectedRecord: () => null);
        expect(cleared.selectedRecord, isNull);
      });

      test('copyWith pairedRecord nullable via function', () {
        const state = SelectionState(pairedRecord: pairedRecord);
        final cleared = state.copyWith(pairedRecord: () => null);
        expect(cleared.pairedRecord, isNull);
      });

      test('equality works correctly', () {
        const a = SelectionState(selectedIndex: 1);
        const b = SelectionState(selectedIndex: 1);
        const c = SelectionState(selectedIndex: 2);
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('equality considers all fields', () {
        const a = SelectionState(
          selectedIndex: 1,
          selectedRecord: sampleRecord,
          pairedRecord: pairedRecord,
        );
        const b = SelectionState(
          selectedIndex: 1,
          selectedRecord: sampleRecord,
        );
        expect(a, isNot(equals(b)));
      });
    });

    group('event-response pairing scenario', () {
      blocTest<SelectionBloc, SelectionState>(
        'select then clear produces correct state sequence',
        build: SelectionBloc.new,
        act: (bloc) {
          bloc
            ..add(const EntrySelected(3))
            ..add(const SelectionCleared())
            ..add(const EntrySelected(7));
        },
        expect: () => [
          const SelectionState(selectedIndex: 3),
          const SelectionState(),
          const SelectionState(selectedIndex: 7),
        ],
      );
    });
  });
}
