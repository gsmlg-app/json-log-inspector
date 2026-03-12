part of 'filter_bloc.dart';

class FilterState extends Equatable {
  const FilterState({
    this.rules = const [],
    this.searchQuery = '',
    this.presets = const [],
  });

  final List<FilterRule> rules;
  final String searchQuery;
  final List<FilterPreset> presets;

  @override
  List<Object?> get props => [rules, searchQuery, presets];

  FilterState copyWith({
    List<FilterRule>? rules,
    String? searchQuery,
    List<FilterPreset>? presets,
  }) {
    return FilterState(
      rules: rules ?? this.rules,
      searchQuery: searchQuery ?? this.searchQuery,
      presets: presets ?? this.presets,
    );
  }
}
