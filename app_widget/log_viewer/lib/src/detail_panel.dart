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
    // Determine request/response sources, supporting SSE paired records.
    final requestData = record.request ?? pairedRecord?.request;
    final responseData = record.response ?? pairedRecord?.response;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetadataBar(record: record),
          const SizedBox(height: 8),
          if (requestData != null) ...[
            _RequestSection(request: requestData),
            const SizedBox(height: 8),
          ],
          if (responseData != null)
            _ResponseSection(
              response: responseData,
              durationMs: record.durationMs ?? pairedRecord?.durationMs,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            record.recordType.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            record.ts,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            'ID: ${record.requestId}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          // Summary line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Text(
              '${request.method} ${request.uri} ${request.proto}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Headers
          if (request.headers.isNotEmpty)
            _CollapsibleSection(
              title: 'Headers (${request.headers.length})',
              initiallyExpanded: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: JsonTreeView(
                  data: request.headers,
                  initiallyExpanded: true,
                ),
              ),
            ),
          // Body
          BodyViewer(
            body: request.body,
            contentType: request.contentType,
            bodyEncoding: request.bodyEncoding,
            bodyTruncated: request.bodyTruncated,
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

    final statusColor = switch (response.status) {
      >= 200 && < 300 => Colors.green,
      >= 300 && < 400 => Colors.orange,
      >= 400 && < 500 => Colors.red.shade700,
      >= 500 => Colors.red,
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
          // Summary line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Text(
              '${response.status}$durationText',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          // Headers
          if (response.headers.isNotEmpty)
            _CollapsibleSection(
              title: 'Headers (${response.headers.length})',
              initiallyExpanded: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: JsonTreeView(
                  data: response.headers,
                  initiallyExpanded: true,
                ),
              ),
            ),
          // Body
          BodyViewer(
            body: response.body,
            contentType: response.contentType,
            bodyEncoding: response.bodyEncoding,
            bodyTruncated: response.bodyTruncated,
          ),
        ],
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
    required this.child,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final bool initiallyExpanded;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  semanticLabel: _isExpanded ? 'Collapse' : 'Expand',
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(widget.icon, size: 16, color: widget.iconColor),
                ],
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) widget.child,
      ],
    );
  }
}
