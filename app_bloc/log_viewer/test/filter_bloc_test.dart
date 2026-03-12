import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_models/log_models.dart';
import 'package:log_viewer_bloc/log_viewer_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const rule1 = FilterRule(
    id: 'r1',
    keyPath: 'request.method',
    operator: FilterOperator.equals,
    value: 'GET',
    enabled: true,
  );

  const rule2 = FilterRule(
    id: 'r2',
    keyPath: 'response.status',
    operator: FilterOperator.greaterThan,
    value: '200',
    enabled: true,
  );

  const rule3 = FilterRule(
    id: 'r3',
    keyPath: 'request.uri',
    operator: FilterOperator.contains,
    value: '/api',
    enabled: false,
  );

  // Default presets that are always present when no stored presets exist
  const defaultPresets = [
    FilterPreset(
      name: 'Errors only',
      rules: [
        FilterRule(
          id: 'preset-errors',
          keyPath: 'response.status',
          operator: FilterOperator.greaterThanOrEqual,
          value: '400',
          enabled: true,
        ),
      ],
    ),
    FilterPreset(
      name: 'Slow requests',
      rules: [
        FilterRule(
          id: 'preset-slow',
          keyPath: 'duration_ms',
          operator: FilterOperator.greaterThan,
          value: '1000',
          enabled: true,
        ),
      ],
    ),
    FilterPreset(
      name: 'SSE streams',
      rules: [
        FilterRule(
          id: 'preset-sse',
          keyPath: 'record_type',
          operator: FilterOperator.notEquals,
          value: 'exchange',
          enabled: true,
        ),
      ],
    ),
  ];

  late SharedPreferences sharedPreferences;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SharedPreferences> getPrefs() async {
    return SharedPreferences.getInstance();
  }

  group('FilterBloc', () {
    group('initial state', () {
      blocTest<FilterBloc, FilterState>(
        'emits initial state with empty rules, search, and default presets',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        verify: (bloc) {
          expect(bloc.state.rules, isEmpty);
          expect(bloc.state.searchQuery, '');
          expect(bloc.state.presets, hasLength(3));
          expect(bloc.state.presets, defaultPresets);
        },
      );

      test('loads presets from SharedPreferences on creation', () async {
        final presetJson = jsonEncode([
          {
            'name': 'Saved Preset',
            'rules': [
              {
                'id': 'r1',
                'keyPath': 'request.method',
                'operator': 'equals',
                'value': 'GET',
                'enabled': true,
              },
            ],
          },
        ]);
        SharedPreferences.setMockInitialValues({'filter_presets': presetJson});
        final prefs = await SharedPreferences.getInstance();
        final bloc = FilterBloc(sharedPreferences: prefs);

        expect(bloc.state.presets, hasLength(1));
        expect(bloc.state.presets.first.name, 'Saved Preset');
        expect(bloc.state.presets.first.rules, hasLength(1));
        expect(bloc.state.presets.first.rules.first, rule1);

        await bloc.close();
      });

      test('handles malformed JSON in SharedPreferences gracefully', () async {
        SharedPreferences.setMockInitialValues(
          {'filter_presets': 'not valid json'},
        );
        final prefs = await SharedPreferences.getInstance();
        final bloc = FilterBloc(sharedPreferences: prefs);

        // Falls back to default presets on malformed JSON
        expect(bloc.state.presets, defaultPresets);

        await bloc.close();
      });
    });

    group('RuleAdded', () {
      blocTest<FilterBloc, FilterState>(
        'adds a single rule',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        act: (bloc) => bloc.add(const RuleAdded(rule1)),
        expect: () => [
          const FilterState(rules: [rule1], presets: defaultPresets),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'adds multiple rules in sequence',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        act: (bloc) {
          bloc
            ..add(const RuleAdded(rule1))
            ..add(const RuleAdded(rule2));
        },
        expect: () => [
          const FilterState(rules: [rule1], presets: defaultPresets),
          const FilterState(rules: [rule1, rule2], presets: defaultPresets),
        ],
      );
    });

    group('RuleRemoved', () {
      blocTest<FilterBloc, FilterState>(
        'removes an existing rule by id',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1, rule2]),
        act: (bloc) => bloc.add(const RuleRemoved('r1')),
        expect: () => [
          const FilterState(rules: [rule2]),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'does nothing when removing non-existent rule id',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(const RuleRemoved('non_existent')),
        expect: () => <FilterState>[],
        verify: (bloc) {
          expect(bloc.state.rules, [rule1]);
        },
      );

      blocTest<FilterBloc, FilterState>(
        'removes the last rule resulting in empty list',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(const RuleRemoved('r1')),
        expect: () => [
          const FilterState(),
        ],
      );
    });

    group('RuleToggled', () {
      blocTest<FilterBloc, FilterState>(
        'toggles an enabled rule to disabled',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(const RuleToggled('r1')),
        expect: () => [
          FilterState(rules: [rule1.copyWith(enabled: false)]),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'toggles a disabled rule to enabled',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule3]),
        act: (bloc) => bloc.add(const RuleToggled('r3')),
        expect: () => [
          FilterState(rules: [rule3.copyWith(enabled: true)]),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'only toggles the targeted rule, leaving others unchanged',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1, rule2]),
        act: (bloc) => bloc.add(const RuleToggled('r2')),
        expect: () => [
          FilterState(rules: [rule1, rule2.copyWith(enabled: false)]),
        ],
      );
    });

    group('RuleUpdated', () {
      blocTest<FilterBloc, FilterState>(
        'updates an existing rule',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1, rule2]),
        act: (bloc) => bloc.add(
          RuleUpdated(rule1.copyWith(value: 'POST')),
        ),
        expect: () => [
          FilterState(rules: [rule1.copyWith(value: 'POST'), rule2]),
        ],
      );
    });

    group('SearchChanged', () {
      blocTest<FilterBloc, FilterState>(
        'updates search query',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        act: (bloc) => bloc.add(const SearchChanged('error')),
        expect: () => [
          const FilterState(
            searchQuery: 'error',
            presets: defaultPresets,
          ),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'clears search query with empty string',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(searchQuery: 'error'),
        act: (bloc) => bloc.add(const SearchChanged('')),
        expect: () => [
          const FilterState(searchQuery: ''),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'preserves existing rules when search changes',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(const SearchChanged('test')),
        expect: () => [
          const FilterState(rules: [rule1], searchQuery: 'test'),
        ],
      );
    });

    group('PresetApplied', () {
      const preset = FilterPreset(name: 'Test Preset', rules: [rule1, rule2]);

      blocTest<FilterBloc, FilterState>(
        'replaces current rules with preset rules',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule3]),
        act: (bloc) => bloc.add(const PresetApplied(preset)),
        expect: () => [
          const FilterState(rules: [rule1, rule2]),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'applies empty preset clearing all rules',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(
          const PresetApplied(FilterPreset(name: 'Empty', rules: [])),
        ),
        expect: () => [
          const FilterState(),
        ],
      );
    });

    group('PresetSaved', () {
      blocTest<FilterBloc, FilterState>(
        'saves current rules as a new preset',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1, rule2]),
        act: (bloc) => bloc.add(const PresetSaved('My Preset')),
        expect: () => [
          FilterState(
            rules: const [rule1, rule2],
            presets: [
              const FilterPreset(name: 'My Preset', rules: [rule1, rule2]),
            ],
          ),
        ],
      );

      blocTest<FilterBloc, FilterState>(
        'persists preset to SharedPreferences',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => const FilterState(rules: [rule1]),
        act: (bloc) => bloc.add(const PresetSaved('Persisted')),
        verify: (bloc) {
          final stored = sharedPreferences.getString('filter_presets');
          expect(stored, isNotNull);
          final decoded = jsonDecode(stored!) as List<dynamic>;
          expect(decoded, hasLength(1));
          final presetMap = decoded.first as Map<String, dynamic>;
          expect(presetMap['name'], 'Persisted');
          final rules = presetMap['rules'] as List<dynamic>;
          expect(rules, hasLength(1));
          final ruleMap = rules.first as Map<String, dynamic>;
          expect(ruleMap['id'], 'r1');
          expect(ruleMap['keyPath'], 'request.method');
          expect(ruleMap['operator'], 'equals');
          expect(ruleMap['value'], 'GET');
          expect(ruleMap['enabled'], true);
        },
      );

      blocTest<FilterBloc, FilterState>(
        'appends to existing presets',
        setUp: () async {
          sharedPreferences = await getPrefs();
        },
        build: () => FilterBloc(sharedPreferences: sharedPreferences),
        seed: () => FilterState(
          rules: const [rule2],
          presets: [
            const FilterPreset(name: 'First', rules: [rule1]),
          ],
        ),
        act: (bloc) => bloc.add(const PresetSaved('Second')),
        expect: () => [
          FilterState(
            rules: const [rule2],
            presets: [
              const FilterPreset(name: 'First', rules: [rule1]),
              const FilterPreset(name: 'Second', rules: [rule2]),
            ],
          ),
        ],
      );
    });
  });
}
