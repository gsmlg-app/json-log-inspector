import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:log_models/log_models.dart';

/// A quick filter input bar for filtering log entries.
///
/// Provides a text input accepting `key:operator:value` syntax and
/// a separate search field with debounce. Active filter rules are
/// displayed as dismissible chips below the input.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.onFilterAdded,
    required this.onSearchChanged,
    this.activeRules = const [],
    this.onRuleToggled,
    this.onRuleRemoved,
  });

  final void Function(FilterRule rule) onFilterAdded;
  final void Function(String query) onSearchChanged;
  final List<FilterRule> activeRules;
  final void Function(String ruleId)? onRuleToggled;
  final void Function(String ruleId)? onRuleRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            if (compact) {
              return Column(
                children: [
                  _InputShell(
                    label: 'Structured filter',
                    child: _FilterInput(onFilterAdded: onFilterAdded),
                  ),
                  const SizedBox(height: 10),
                  _InputShell(
                    label: 'Full text search',
                    child: _SearchInput(onSearchChanged: onSearchChanged),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _InputShell(
                    label: 'Structured filter',
                    child: _FilterInput(onFilterAdded: onFilterAdded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputShell(
                    label: 'Full text search',
                    child: _SearchInput(onSearchChanged: onSearchChanged),
                  ),
                ),
              ],
            );
          },
        ),
        if (activeRules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeRules.map((rule) {
                final selected = rule.enabled;

                return FilterChip(
                  avatar: Icon(
                    selected ? Icons.filter_alt : Icons.filter_alt_off_outlined,
                    size: 16,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    '${rule.keyPath} ${rule.operator.name} ${rule.value}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  selectedColor: colorScheme.primaryContainer,
                  side: BorderSide(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.32)
                        : colorScheme.outlineVariant,
                  ),
                  onSelected: onRuleToggled != null
                      ? (_) => onRuleToggled!(rule.id)
                      : null,
                  onDeleted: onRuleRemoved != null
                      ? () => onRuleRemoved!(rule.id)
                      : null,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FilterInput extends StatefulWidget {
  const _FilterInput({required this.onFilterAdded});

  final void Function(FilterRule rule) onFilterAdded;

  @override
  State<_FilterInput> createState() => _FilterInputState();
}

class _FilterInputState extends State<_FilterInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitFilter() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final parts = text.split(':');
    if (parts.length >= 3) {
      final keyPath = parts[0];
      final operatorStr = parts[1];
      final value = parts.sublist(2).join(':');

      final operator = _parseOperator(operatorStr);
      if (operator != null) {
        widget.onFilterAdded(
          FilterRule(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            keyPath: keyPath,
            operator: operator,
            value: value,
            enabled: true,
          ),
        );
        _controller.clear();
      }
    }
  }

  FilterOperator? _parseOperator(String str) {
    return switch (str.toLowerCase()) {
      'eq' || 'equals' || '==' => FilterOperator.equals,
      'ne' || 'notequals' || '!=' => FilterOperator.notEquals,
      'contains' || '~' => FilterOperator.contains,
      'gt' || '>' => FilterOperator.greaterThan,
      'lt' || '<' => FilterOperator.lessThan,
      'gte' || '>=' => FilterOperator.greaterThanOrEqual,
      'lte' || '<=' => FilterOperator.lessThanOrEqual,
      'exists' => FilterOperator.exists,
      'regex' || '=~' => FilterOperator.regex,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Filter: key:operator:value',
        isDense: true,
        prefixIcon: const Icon(Icons.tune, size: 18),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 18),
          onPressed: _submitFilter,
          tooltip: 'Add filter',
        ),
      ),
      style: theme.codeTextStyle(
        fontSize: 13,
        color: theme.colorScheme.onSurface,
      ),
      onSubmitted: (_) => _submitFilter(),
    );
  }
}

class _SearchInput extends StatefulWidget {
  const _SearchInput({required this.onSearchChanged});

  final void Function(String query) onSearchChanged;

  @override
  State<_SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<_SearchInput> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search raw lines, headers, and bodies',
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }

            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _controller.clear();
                widget.onSearchChanged('');
              },
              tooltip: 'Clear search',
            );
          },
        ),
      ),
      style: theme.codeTextStyle(
        fontSize: 13,
        color: theme.colorScheme.onSurface,
      ),
      onChanged: _onChanged,
    );
  }
}
