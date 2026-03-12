import 'package:flutter/material.dart';
import 'package:log_models/log_models.dart';

/// A visual rule builder dialog for creating or editing filter rules.
///
/// Provides three inputs: key path (with autocomplete from discovered keys),
/// operator (dropdown), and value (text input).
class FilterRuleBuilder extends StatefulWidget {
  const FilterRuleBuilder({
    super.key,
    required this.availableKeyPaths,
    required this.onRuleCreated,
    this.existingRule,
  });

  final Set<String> availableKeyPaths;
  final void Function(FilterRule rule) onRuleCreated;
  final FilterRule? existingRule;

  @override
  State<FilterRuleBuilder> createState() => _FilterRuleBuilderState();
}

class _FilterRuleBuilderState extends State<FilterRuleBuilder> {
  late final TextEditingController _keyPathController;
  late final TextEditingController _valueController;
  late FilterOperator _selectedOperator;

  @override
  void initState() {
    super.initState();
    _keyPathController = TextEditingController(
      text: widget.existingRule?.keyPath ?? '',
    );
    _valueController = TextEditingController(
      text: widget.existingRule?.value ?? '',
    );
    _selectedOperator = widget.existingRule?.operator ?? FilterOperator.equals;
  }

  @override
  void dispose() {
    _keyPathController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final keyPath = _keyPathController.text.trim();
    final value = _valueController.text.trim();
    if (keyPath.isEmpty) return;

    widget.onRuleCreated(
      FilterRule(
        id:
            widget.existingRule?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        keyPath: keyPath,
        operator: _selectedOperator,
        value: value,
        enabled: widget.existingRule?.enabled ?? true,
      ),
    );
  }

  String _operatorLabel(FilterOperator op) {
    return switch (op) {
      FilterOperator.equals => '== (equals)',
      FilterOperator.notEquals => '!= (not equals)',
      FilterOperator.contains => '~ (contains)',
      FilterOperator.greaterThan => '> (greater than)',
      FilterOperator.lessThan => '< (less than)',
      FilterOperator.greaterThanOrEqual => '>= (greater or equal)',
      FilterOperator.lessThanOrEqual => '<= (less or equal)',
      FilterOperator.exists => 'exists',
      FilterOperator.regex => '=~ (regex)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeyPaths = widget.availableKeyPaths.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingRule != null
                ? 'Edit Filter Rule'
                : 'New Filter Rule',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Autocomplete<String>(
            initialValue: _keyPathController.value,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return sortedKeyPaths;
              }
              return sortedKeyPaths.where(
                (path) => path.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (selection) {
              _keyPathController.text = selection;
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Key Path',
                      hintText: 'e.g. request.method',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    onChanged: (value) {
                      _keyPathController.text = value;
                    },
                  );
                },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FilterOperator>(
            value: _selectedOperator,
            decoration: const InputDecoration(
              labelText: 'Operator',
              border: OutlineInputBorder(),
            ),
            items: FilterOperator.values
                .map(
                  (op) => DropdownMenuItem(
                    value: op,
                    child: Text(_operatorLabel(op)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedOperator = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: 'Value',
              hintText: 'Filter value',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.existingRule != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
