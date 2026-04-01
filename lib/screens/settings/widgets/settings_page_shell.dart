import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:json_log_inspector/destination.dart';

class DmSettingsPageShell extends StatelessWidget {
  const DmSettingsPageShell({
    required this.selectedKey,
    required this.title,
    required this.subtitle,
    required this.child,
    this.hero,
    super.key,
  });

  final Key selectedKey;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(selectedKey, context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: DmAppBar(title: Text(title), subtitle: subtitle),
      body: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.12),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hero != null) ...[hero!, const SizedBox(height: 16)],
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}

class DmSettingsHeroCard extends StatelessWidget {
  const DmSettingsHeroCard({
    required this.icon,
    required this.title,
    required this.description,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DmCard(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class DmSettingsMetaPill extends StatelessWidget {
  const DmSettingsMetaPill({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
