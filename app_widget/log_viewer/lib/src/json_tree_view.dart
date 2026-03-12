import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A recursive JSON tree viewer that renders Map, List, and leaf values
/// with collapsible nodes and syntax highlighting.
class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    super.key,
    required this.data,
    this.initiallyExpanded = false,
  });

  final dynamic data;
  final bool initiallyExpanded;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _JsonNode(
        keyName: null,
        value: widget.data,
        initiallyExpanded: widget.initiallyExpanded,
      ),
    );
  }
}

class _JsonNode extends StatefulWidget {
  const _JsonNode({
    required this.keyName,
    required this.value,
    this.initiallyExpanded = false,
  });

  final String? keyName;
  final dynamic value;
  final bool initiallyExpanded;

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;

    if (value is Map) {
      return _buildCollapsibleNode(
        context,
        typeLabel: 'Object',
        typeColor: Colors.orange,
        preview: '{${value.length}}',
        children: value.entries
            .map(
              (entry) => _JsonNode(
                keyName: entry.key.toString(),
                value: entry.value,
                initiallyExpanded: widget.initiallyExpanded,
              ),
            )
            .toList(),
      );
    }

    if (value is List) {
      return _buildCollapsibleNode(
        context,
        typeLabel: 'Array',
        typeColor: Colors.blue,
        preview: '[${value.length}]',
        children: List.generate(
          value.length,
          (index) => _JsonNode(
            keyName: '[$index]',
            value: value[index],
            initiallyExpanded: widget.initiallyExpanded,
          ),
        ),
      );
    }

    return _buildLeafNode(context, value);
  }

  Widget _buildCollapsibleNode(
    BuildContext context, {
    required String typeLabel,
    required Color typeColor,
    required String preview,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final keyWidget = widget.keyName != null
        ? Text(
            '${widget.keyName}: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                ),
                const SizedBox(width: 4),
                keyWidget,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  preview,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    );
  }

  Widget _buildLeafNode(BuildContext context, dynamic value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color valueColor;
    final String displayValue;

    if (value is String) {
      valueColor = colorScheme.primary;
      displayValue = '"$value"';
    } else if (value is num) {
      valueColor = colorScheme.tertiary;
      displayValue = value.toString();
    } else if (value is bool) {
      valueColor = colorScheme.secondary;
      displayValue = value.toString();
    } else {
      valueColor = Colors.grey;
      displayValue = 'null';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          if (widget.keyName != null)
            Text(
              '${widget.keyName}: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: value?.toString() ?? 'null'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  displayValue,
                  style: TextStyle(color: valueColor, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
