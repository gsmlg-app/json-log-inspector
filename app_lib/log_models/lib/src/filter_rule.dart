import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'filter_operator.dart';

/// A single filter rule that can be applied to log records.
@immutable
class FilterRule extends Equatable {
  const FilterRule({
    required this.id,
    required this.keyPath,
    required this.operator,
    required this.value,
    required this.enabled,
  });

  final String id;
  final String keyPath;
  final FilterOperator operator;
  final String value;
  final bool enabled;

  FilterRule copyWith({
    String? id,
    String? keyPath,
    FilterOperator? operator,
    String? value,
    bool? enabled,
  }) {
    return FilterRule(
      id: id ?? this.id,
      keyPath: keyPath ?? this.keyPath,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [id, keyPath, operator, value, enabled];
}
