import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:json_log_inspector/screens/settings/widgets/settings_page_shell.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';

class AccentColorSettingsScreen extends StatelessWidget {
  static const name = 'Accent Color Settings';
  static const path = 'accent-color';

  const AccentColorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DmSettingsPageShell(
      selectedKey: const Key(SettingsScreen.name),
      title: context.l10n.accentColor,
      subtitle: 'Select the active Duskmoon palette for the whole app.',
      hero: BlocBuilder<ThemeBloc, ThemeState>(
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
                  label: 'Current: ${state.theme.name}',
                ),
              ],
            ),
          );
        },
      ),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          final currentTheme = state.theme;

          return SettingsList(
            sections: [
              SettingsSection(
                title: Text(context.l10n.accentColor),
                tiles: <AbstractSettingsTile>[
                  CustomSettingsTile(
                    child: _AccentColorPicker(
                      themes: themeList,
                      currentTheme: currentTheme,
                      isLight: isLight,
                      onThemeChanged: (theme) {
                        themeBloc.add(ChangeTheme(theme));
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
    required this.currentTheme,
    required this.isLight,
    required this.onThemeChanged,
  });

  final List<AppTheme> themes;
  final AppTheme currentTheme;
  final bool isLight;
  final ValueChanged<AppTheme> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: themes.map((theme) {
          final colorScheme = isLight
              ? theme.lightTheme.colorScheme
              : theme.darkTheme.colorScheme;
          final isSelected = currentTheme.name == theme.name;

          return SizedBox(
            width: 180,
            child: DmCard(
              onTap: () => onThemeChanged(theme),
              backgroundColor: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.52)
                  : Theme.of(context).colorScheme.surface,
              borderColor: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : Theme.of(context).colorScheme.outlineVariant,
              padding: const EdgeInsets.all(16),
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
