import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:log_models/log_models.dart';

import 'body_viewer.dart';
import 'json_tree_view.dart';

/// A stacked request/response detail panel for viewing HTTP log records.
///
/// Displays request (top) and response (below) sections, each with
/// a summary line, collapsible headers tree, and body viewer.
/// Both sections are independently collapsible and the entire panel
/// is scrollable. For SSE paired records, shows both request and
/// response from paired records.
class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key, required this.record, this.pairedRecord});

  final LogRecord record;
  final LogRecord? pairedRecord;

  @override
  Widget build(BuildContext context) {
    final requestData = record.request ?? pairedRecord?.request;
    final responseData = record.response ?? pairedRecord?.response;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetadataBar(record: record),
          const SizedBox(height: 12),
          if (requestData != null) ...[
            _RequestSection(request: requestData),
            const SizedBox(height: 12),
          ],
          if (responseData != null)
            _ResponseSection(
              response: responseData,
              durationMs: record.durationMs ?? pairedRecord?.durationMs,
            ),
          if (requestData == null && responseData == null)
            _RawJsonSection(json: record.json),
        ],
      ),
    );
  }
}

class _MetadataBar extends StatelessWidget {
  const _MetadataBar({required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              record.recordType.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Text(
            record.ts,
            style: theme.codeTextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ID: ${record.requestId}',
              style: theme.codeTextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.request});

  final RequestData request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CollapsibleSection(
      title: 'Request',
      icon: Icons.arrow_upward,
      iconColor: theme.colorScheme.primary,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(
            content: '${request.method} ${request.uri} ${request.proto}',
          ),
          if (request.headers.isNotEmpty)
            _CollapsibleSection(
              title: 'Headers (${request.headers.length})',
              initiallyExpanded: false,
              compact: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: JsonTreeView(
                  data: request.headers,
                  initiallyExpanded: true,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: BodyViewer(
              body: request.body,
              contentType: request.contentType,
              bodyEncoding: request.bodyEncoding,
              bodyTruncated: request.bodyTruncated,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseSection extends StatelessWidget {
  const _ResponseSection({required this.response, this.durationMs});

  final ResponseData response;
  final double? durationMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.statusColors;

    final statusColor = switch (response.status) {
      >= 200 && < 300 => statusColors.success,
      >= 300 && < 400 => statusColors.warning,
      >= 400 => statusColors.error,
      _ => theme.colorScheme.onSurface,
    };

    final durationText = durationMs != null
        ? ' (${durationMs!.toStringAsFixed(1)} ms)'
        : '';

    return _CollapsibleSection(
      title: 'Response',
      icon: Icons.arrow_downward,
      iconColor: statusColor,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(
            content: '${response.status}$durationText',
            textColor: statusColor,
          ),
          if (response.headers.isNotEmpty)
            _CollapsibleSection(
              title: 'Headers (${response.headers.length})',
              initiallyExpanded: false,
              compact: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: JsonTreeView(
                  data: response.headers,
                  initiallyExpanded: true,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: BodyViewer(
              body: response.body,
              contentType: response.contentType,
              bodyEncoding: response.bodyEncoding,
              bodyTruncated: response.bodyTruncated,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.content, this.textColor});

  final String content;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        content,
        style: theme.codeTextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    this.icon,
    this.iconColor,
    this.initiallyExpanded = true,
    this.compact = false,
    required this.child,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final bool initiallyExpanded;
  final bool compact;
  final Widget child;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        widget.iconColor?.withValues(alpha: 0.24) ??
        theme.colorScheme.outlineVariant;
    final radius = widget.compact ? 16.0 : 22.0;
    final padding = widget.compact ? 12.0 : 14.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.compact
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                    semanticLabel: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                  if (widget.icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(widget.icon, size: 16, color: widget.iconColor),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) widget.child,
        ],
      ),
    );
  }
}

class _RawJsonSection extends StatelessWidget {
  const _RawJsonSection({required this.json});

  final Map<String, dynamic> json;

  @override
  Widget build(BuildContext context) {
    return _CollapsibleSection(
      title: 'JSON Data',
      icon: Icons.data_object,
      iconColor: Theme.of(context).colorScheme.primary,
      initiallyExpanded: true,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: JsonTreeView(data: json, initiallyExpanded: true),
      ),
    );
  }
}
