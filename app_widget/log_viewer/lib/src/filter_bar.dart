import 'dart:async';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _FilterInput(onFilterAdded: onFilterAdded)),
            const SizedBox(width: 8),
            Expanded(child: _SearchInput(onSearchChanged: onSearchChanged)),
          ],
        ),
        if (activeRules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: activeRules.map((rule) {
                return FilterChip(
                  label: Text(
                    '${rule.keyPath} ${rule.operator.name} ${rule.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: rule.enabled,
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
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Filter: key:operator:value',
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: _submitFilter,
          tooltip: 'Add filter',
        ),
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search...',
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
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
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      onChanged: _onChanged,
    );
  }
}
