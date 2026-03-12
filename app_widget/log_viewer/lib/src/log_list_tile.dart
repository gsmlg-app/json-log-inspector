import 'package:flutter/material.dart';

/// A row widget for displaying a log entry in a list.
///
/// Shows a truncated raw JSON preview in monospace font with
/// visual indicators for selection state and error status.
class LogListTile extends StatelessWidget {
  const LogListTile({
    super.key,
    required this.rawLine,
    required this.index,
    this.isSelected = false,
    this.isError = false,
    this.onTap,
  });

  final String rawLine;
  final int index;
  final bool isSelected;
  final bool isError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : isError
        ? colorScheme.errorContainer.withValues(alpha: 0.3)
        : null;

    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            if (isError)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: colorScheme.error,
                ),
              ),
            Expanded(
              child: Text(
                rawLine,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
