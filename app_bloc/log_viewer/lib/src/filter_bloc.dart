import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:log_models/log_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'filter_event.dart';
part 'filter_state.dart';

class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences,
      super(FilterState(presets: _loadPresets(sharedPreferences))) {
    on<RuleAdded>(_onRuleAdded);
    on<RuleRemoved>(_onRuleRemoved);
    on<RuleToggled>(_onRuleToggled);
    on<RuleUpdated>(_onRuleUpdated);
    on<SearchChanged>(_onSearchChanged);
    on<PresetApplied>(_onPresetApplied);
    on<PresetSaved>(_onPresetSaved);
  }

  final SharedPreferences _sharedPreferences;

  static const _presetsKey = 'filter_presets';

  static const _defaultPresets = [
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

  static List<FilterPreset> _loadPresets(SharedPreferences prefs) {
    final json = prefs.getString(_presetsKey);
    if (json == null) return List.of(_defaultPresets);
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final rules = (map['rules'] as List<dynamic>).map((r) {
          final rMap = r as Map<String, dynamic>;
          return FilterRule(
            id: rMap['id'] as String,
            keyPath: rMap['keyPath'] as String,
            operator: FilterOperator.values.byName(rMap['operator'] as String),
            value: rMap['value'] as String,
            enabled: rMap['enabled'] as bool,
          );
        }).toList();
        return FilterPreset(name: map['name'] as String, rules: rules);
      }).toList();
    } on Object {
      return List.of(_defaultPresets);
    }
  }

  void _persistPresets(List<FilterPreset> presets) {
    final json = jsonEncode(
      presets
          .map(
            (p) => {
              'name': p.name,
              'rules': p.rules
                  .map(
                    (r) => {
                      'id': r.id,
                      'keyPath': r.keyPath,
                      'operator': r.operator.name,
                      'value': r.value,
                      'enabled': r.enabled,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    );
    _sharedPreferences.setString(_presetsKey, json);
  }

  void _onRuleAdded(RuleAdded event, Emitter<FilterState> emitter) {
    emitter(state.copyWith(rules: [...state.rules, event.rule]));
  }

  void _onRuleRemoved(RuleRemoved event, Emitter<FilterState> emitter) {
    emitter(
      state.copyWith(
        rules: state.rules.where((r) => r.id != event.ruleId).toList(),
      ),
    );
  }

  void _onRuleToggled(RuleToggled event, Emitter<FilterState> emitter) {
    emitter(
      state.copyWith(
        rules: state.rules.map((r) {
          if (r.id == event.ruleId) {
            return r.copyWith(enabled: !r.enabled);
          }
          return r;
        }).toList(),
      ),
    );
  }

  void _onRuleUpdated(RuleUpdated event, Emitter<FilterState> emitter) {
    emitter(
      state.copyWith(
        rules: state.rules.map((r) {
          if (r.id == event.rule.id) return event.rule;
          return r;
        }).toList(),
      ),
    );
  }

  void _onSearchChanged(SearchChanged event, Emitter<FilterState> emitter) {
    emitter(state.copyWith(searchQuery: event.query));
  }

  void _onPresetApplied(PresetApplied event, Emitter<FilterState> emitter) {
    emitter(state.copyWith(rules: List.of(event.preset.rules)));
  }

  void _onPresetSaved(PresetSaved event, Emitter<FilterState> emitter) {
    final preset = FilterPreset(name: event.name, rules: List.of(state.rules));
    final updatedPresets = [...state.presets, preset];
    _persistPresets(updatedPresets);
    emitter(state.copyWith(presets: updatedPresets));
  }
}
