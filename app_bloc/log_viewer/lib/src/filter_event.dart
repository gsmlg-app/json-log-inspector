part of 'filter_bloc.dart';

sealed class FilterEvent {
  const FilterEvent();
}

final class RuleAdded extends FilterEvent {
  final FilterRule rule;

  const RuleAdded(this.rule);
}

final class RuleRemoved extends FilterEvent {
  final String ruleId;

  const RuleRemoved(this.ruleId);
}

final class RuleToggled extends FilterEvent {
  final String ruleId;

  const RuleToggled(this.ruleId);
}

final class RuleUpdated extends FilterEvent {
  final FilterRule rule;

  const RuleUpdated(this.rule);
}

final class SearchChanged extends FilterEvent {
  final String query;

  const SearchChanged(this.query);
}

final class PresetApplied extends FilterEvent {
  final FilterPreset preset;

  const PresetApplied(this.preset);
}

final class PresetSaved extends FilterEvent {
  final String name;

  const PresetSaved(this.name);
}
