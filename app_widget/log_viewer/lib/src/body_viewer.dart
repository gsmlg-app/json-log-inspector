import 'dart:convert';

import 'package:flutter/material.dart';

import 'json_tree_view.dart';

/// A content-type-aware body renderer for HTTP request/response bodies.
///
/// Renders the body based on content type:
/// - `application/json` is parsed and rendered with [JsonTreeView]
/// - `text/*` is displayed as monospaced text
/// - Base64-encoded bodies show a placeholder with byte count
/// - Truncated bodies display a warning indicator
class BodyViewer extends StatelessWidget {
  const BodyViewer({
    super.key,
    required this.body,
    this.contentType,
    this.bodyEncoding,
    this.bodyTruncated = false,
  });

  final String? body;
  final String? contentType;
  final String? bodyEncoding;
  final bool bodyTruncated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (body == null || body!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '(empty body)',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBody(context),
        if (bodyTruncated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                  semanticLabel: 'Warning',
                ),
                const SizedBox(width: 6),
                Text(
                  'Body was truncated',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    // Base64 encoded binary content
    if (bodyEncoding == 'base64') {
      final byteCount = _estimateBase64Bytes(body!);
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '[base64 binary, $byteCount bytes]',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // JSON content
    if (contentType != null &&
        contentType!.toLowerCase().contains('application/json')) {
      try {
        final parsed = jsonDecode(body!);
        return Padding(
          padding: const EdgeInsets.all(8),
          child: JsonTreeView(data: parsed, initiallyExpanded: true),
        );
      } on FormatException {
        // Fall through to plain text rendering
      }
    }

    // Text content (text/* or fallback)
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        body!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  int _estimateBase64Bytes(String base64String) {
    final padding = base64String.endsWith('==')
        ? 2
        : base64String.endsWith('=')
        ? 1
        : 0;
    return (base64String.length * 3 ~/ 4) - padding;
  }
}
