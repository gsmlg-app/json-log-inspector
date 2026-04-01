import 'package:app_theme/app_theme.dart';
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
    final statusColors = theme.statusColors;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : isError
        ? statusColors.errorContainer.withValues(alpha: 0.48)
        : colorScheme.surfaceContainerLow;

    final borderColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.35)
        : isError
        ? statusColors.error.withValues(alpha: 0.35)
        : colorScheme.outlineVariant;

    final linePillColor = isSelected
        ? colorScheme.primary
        : isError
        ? statusColors.error
        : colorScheme.surfaceContainerHigh;

    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : isError
        ? statusColors.onErrorContainer
        : colorScheme.onSurface;

    final lineColor = isSelected
        ? colorScheme.onPrimary
        : isError
        ? statusColors.onError
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: linePillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.codeTextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: lineColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                if (isError)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: statusColors.error,
                      semanticLabel: 'Parse error',
                    ),
                  ),
                Expanded(
                  child: Text(
                    rawLine,
                    style: theme.codeTextStyle(
                      fontSize: 12.5,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
