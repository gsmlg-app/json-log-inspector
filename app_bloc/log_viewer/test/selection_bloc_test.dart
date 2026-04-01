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

  const sampleRecord2 = LogRecord(
    ts: '2024-01-01T00:00:02Z',
    requestId: 'req-2',
    recordType: 'request',
    rawLine: '{"ts":"2024-01-01T00:00:02Z","request_id":"req-2"}',
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
        'sets selectedIndex and record',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const EntrySelected(
          index: 5,
          record: sampleRecord,
        )),
        expect: () => [
          const SelectionState(
            selectedIndex: 5,
            selectedRecord: sampleRecord,
          ),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'updates when selecting a different entry',
        build: SelectionBloc.new,
        seed: () => const SelectionState(
          selectedIndex: 3,
          selectedRecord: sampleRecord,
        ),
        act: (bloc) => bloc.add(const EntrySelected(
          index: 7,
          record: sampleRecord2,
        )),
        expect: () => [
          const SelectionState(
            selectedIndex: 7,
            selectedRecord: sampleRecord2,
          ),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting the same index and record does not re-emit',
        build: SelectionBloc.new,
        seed: () => const SelectionState(
          selectedIndex: 5,
          selectedRecord: sampleRecord,
        ),
        act: (bloc) => bloc.add(const EntrySelected(
          index: 5,
          record: sampleRecord,
        )),
        // Equatable means same state is not re-emitted
        expect: () => <SelectionState>[],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting index 0 works correctly',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const EntrySelected(
          index: 0,
          record: sampleRecord,
        )),
        expect: () => [
          const SelectionState(
            selectedIndex: 0,
            selectedRecord: sampleRecord,
          ),
        ],
      );

      blocTest<SelectionBloc, SelectionState>(
        'selecting entry with paired record stores both',
        build: SelectionBloc.new,
        act: (bloc) => bloc.add(const EntrySelected(
          index: 1,
          record: sampleRecord,
          pairedRecord: pairedRecord,
        )),
        expect: () => [
          const SelectionState(
            selectedIndex: 1,
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
            ..add(const EntrySelected(index: 1, record: sampleRecord))
            ..add(const EntrySelected(index: 2, record: sampleRecord2))
            ..add(const EntrySelected(
              index: 3,
              record: pairedRecord,
              pairedRecord: sampleRecord,
            ));
        },
        expect: () => [
          const SelectionState(
            selectedIndex: 1,
            selectedRecord: sampleRecord,
          ),
          const SelectionState(
            selectedIndex: 2,
            selectedRecord: sampleRecord2,
          ),
          const SelectionState(
            selectedIndex: 3,
            selectedRecord: pairedRecord,
            pairedRecord: sampleRecord,
          ),
        ],
      );
    });

    group('SelectionCleared', () {
      blocTest<SelectionBloc, SelectionState>(
        'resets state to initial values',
        build: SelectionBloc.new,
        seed: () => const SelectionState(
          selectedIndex: 5,
          selectedRecord: sampleRecord,
        ),
        act: (bloc) => bloc.add(const SelectionCleared()),
        expect: () => [const SelectionState()],
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
        expect: () => [const SelectionState()],
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
            ..add(const EntrySelected(index: 3, record: sampleRecord))
            ..add(const SelectionCleared())
            ..add(const EntrySelected(index: 7, record: sampleRecord2));
        },
        expect: () => [
          const SelectionState(
            selectedIndex: 3,
            selectedRecord: sampleRecord,
          ),
          const SelectionState(),
          const SelectionState(
            selectedIndex: 7,
            selectedRecord: sampleRecord2,
          ),
        ],
      );
    });
  });
}
