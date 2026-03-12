import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'filter_rule.dart';

/// A named collection of filter rules that can be saved and reused.
@immutable
class FilterPreset extends Equatable {
  const FilterPreset({required this.name, required this.rules});

  final String name;
  final List<FilterRule> rules;

  FilterPreset copyWith({String? name, List<FilterRule>? rules}) {
    return FilterPreset(name: name ?? this.name, rules: rules ?? this.rules);
  }

  @override
  List<Object?> get props => [name, rules];
}
