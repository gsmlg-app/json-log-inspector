import 'dart:convert';

import 'package:app_theme/app_theme.dart';
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
      return _BodySurface(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            '(empty body)',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodySurface(child: _buildBody(context)),
        if (bodyTruncated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _TruncatedBanner(),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (bodyEncoding == 'base64') {
      final byteCount = _estimateBase64Bytes(body!);
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          '[base64 binary, $byteCount bytes]',
          style: theme.codeTextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (contentType != null &&
        contentType!.toLowerCase().contains('application/json')) {
      try {
        final parsed = jsonDecode(body!);
        return Padding(
          padding: const EdgeInsets.all(10),
          child: JsonTreeView(data: parsed, initiallyExpanded: true),
        );
      } on FormatException {
        // Fall through to plain text rendering.
      }
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: SelectableText(
        body!,
        style: theme.codeTextStyle(
          fontSize: 12.5,
          height: 1.45,
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

class _BodySurface extends StatelessWidget {
  const _BodySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _TruncatedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.statusColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColors.warningContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: statusColors.warning,
            semanticLabel: 'Warning',
          ),
          const SizedBox(width: 8),
          Text(
            'Body was truncated',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: statusColors.onWarningContainer,
            ),
          ),
        ],
      ),
    );
  }
}
