import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum DmButtonVariant { filled, outlined, text, tonal }

class DmButton extends StatelessWidget {
  const DmButton({
    required this.onPressed,
    required this.child,
    this.variant = DmButtonVariant.filled,
    this.padding,
    this.leading,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final DmButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final Widget? leading;

  bool _isCupertino(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = theme.platform;

    if (_isCupertino(platform)) {
      final content = leading == null
          ? child
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [leading!, const SizedBox(width: 8), child],
            );

      final fillColor = switch (variant) {
        DmButtonVariant.filled => theme.colorScheme.primary,
        DmButtonVariant.tonal => theme.colorScheme.secondaryContainer,
        DmButtonVariant.outlined || DmButtonVariant.text => Colors.transparent,
      };

      final foregroundColor = switch (variant) {
        DmButtonVariant.filled => theme.colorScheme.onPrimary,
        DmButtonVariant.tonal => theme.colorScheme.onSecondaryContainer,
        DmButtonVariant.outlined ||
        DmButtonVariant.text => theme.colorScheme.primary,
      };

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: variant == DmButtonVariant.outlined
              ? Border.all(color: theme.colorScheme.outlineVariant)
              : null,
        ),
        child: CupertinoButton(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          color: fillColor == Colors.transparent ? null : fillColor,
          onPressed: onPressed,
          child: IconTheme(
            data: IconThemeData(color: foregroundColor, size: 18),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    final buttonStylePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14);

    return switch (variant) {
      DmButtonVariant.filled =>
        leading == null
            ? FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(padding: buttonStylePadding),
                child: child,
              )
            : FilledButton.icon(
                onPressed: onPressed,
                icon: leading!,
                label: child,
                style: FilledButton.styleFrom(padding: buttonStylePadding),
              ),
      DmButtonVariant.tonal =>
        leading == null
            ? FilledButton.tonal(
                onPressed: onPressed,
                style: FilledButton.styleFrom(padding: buttonStylePadding),
                child: child,
              )
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: leading!,
                label: child,
                style: FilledButton.styleFrom(padding: buttonStylePadding),
              ),
      DmButtonVariant.outlined =>
        leading == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(padding: buttonStylePadding),
                child: child,
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: leading!,
                label: child,
                style: OutlinedButton.styleFrom(padding: buttonStylePadding),
              ),
      DmButtonVariant.text =>
        leading == null
            ? TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(padding: buttonStylePadding),
                child: child,
              )
            : TextButton.icon(
                onPressed: onPressed,
                icon: leading!,
                label: child,
                style: TextButton.styleFrom(padding: buttonStylePadding),
              ),
    };
  }
}

class DmCard extends StatelessWidget {
  const DmCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor =
        backgroundColor ?? theme.colorScheme.surfaceContainerLow;

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
    );
  }
}

class DmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DmAppBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
    super.key,
  });

  final Widget title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  bool _isCupertino(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isCupertino(theme.platform)) {
      return CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        leading: leading,
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DefaultTextStyle.merge(
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              child: title,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: actions == null
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: actions!),
      );
    }

    return AppBar(
      toolbarHeight: preferredSize.height,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DefaultTextStyle.merge(
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            child: title,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
