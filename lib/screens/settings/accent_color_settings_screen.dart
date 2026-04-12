import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:json_log_inspector/screens/settings/widgets/settings_page_shell.dart';

class AccentColorSettingsScreen extends StatelessWidget {
  static const name = 'Accent Color Settings';
  static const path = 'accent-color';

  const AccentColorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<DmThemeBloc>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DmSettingsPageShell(
      selectedKey: const Key(SettingsScreen.name),
      title: context.l10n.accentColor,
      subtitle: 'Select the active Duskmoon palette for the whole app.',
      hero: BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          return DmSettingsHeroCard(
            icon: Icons.palette_outlined,
            title: 'Accent Palette',
            description:
                'Each palette includes a matching light and dark variant tuned for layered surfaces.',
            footer: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DmSettingsMetaPill(
                  icon: Icons.color_lens_outlined,
                  label: 'Current: ${state.themeName}',
                ),
              ],
            ),
          );
        },
      ),
      child: BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: Text(context.l10n.accentColor),
                tiles: <AbstractSettingsTile>[
                  CustomSettingsTile(
                    child: _AccentColorPicker(
                      themes: DmThemeData.themes,
                      currentThemeName: state.themeName,
                      isLight: isLight,
                      onThemeChanged: (name) {
                        themeBloc.add(DmSetTheme(name));
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.themes,
    required this.currentThemeName,
    required this.isLight,
    required this.onThemeChanged,
  });

  final List<DmThemeEntry> themes;
  final String currentThemeName;
  final bool isLight;
  final ValueChanged<String> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: themes.map((theme) {
          final colorScheme = isLight
              ? theme.light.colorScheme
              : theme.dark.colorScheme;
          final isSelected = currentThemeName == theme.name;

          return SizedBox(
            width: 180,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onThemeChanged(theme.name),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.52)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.35)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ColorDot(color: colorScheme.primary),
                          const SizedBox(width: 8),
                          _ColorDot(color: colorScheme.secondary),
                          const SizedBox(width: 8),
                          _ColorDot(color: colorScheme.tertiary),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        theme.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${colorScheme.brightness == Brightness.light ? 'Light' : 'Dark'} adaptive palette',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
