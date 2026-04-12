import 'theme_helpers.dart';
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
    final statusColors = Theme.of(context).statusColors;

    if (value is Map) {
      return _buildCollapsibleNode(
        context,
        typeLabel: 'Object',
        badgeColor: statusColors.warningContainer,
        labelColor: statusColors.onWarningContainer,
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
        badgeColor: statusColors.infoContainer,
        labelColor: statusColors.onInfoContainer,
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
    required Color badgeColor,
    required Color labelColor,
    required String preview,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final keyWidget = widget.keyName != null
        ? Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '${widget.keyName}: ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                  semanticLabel: _isExpanded ? 'Collapse' : 'Expand',
                ),
                const SizedBox(width: 4),
                keyWidget,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    typeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: labelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  preview,
                  style: theme.codeTextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
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
    final statusColors = theme.statusColors;

    final Color valueColor;
    final String displayValue;

    if (value is String) {
      valueColor = colorScheme.primary;
      displayValue = '"$value"';
    } else if (value is num) {
      valueColor = colorScheme.tertiary;
      displayValue = value.toString();
    } else if (value is bool) {
      valueColor = statusColors.success;
      displayValue = value.toString();
    } else {
      valueColor = colorScheme.onSurfaceVariant;
      displayValue = 'null';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          if (widget.keyName != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${widget.keyName}: ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          Expanded(
            child: Tooltip(
              message: 'Click to copy',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    displayValue,
                    style: theme.codeTextStyle(
                      fontSize: 12.5,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
