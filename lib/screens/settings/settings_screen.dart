import 'package:app_locale/app_locale.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:json_log_inspector/screens/settings/accent_color_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/app_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/appearance_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/controller_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/widgets/settings_page_shell.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';

class SettingsScreen extends StatelessWidget {
  static const name = 'Settings';
  static const path = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();

    return DmSettingsPageShell(
      selectedKey: const Key(name),
      title: context.l10n.settingsTitle,
      subtitle: 'Tune appearance, app metadata, and controller behavior.',
      hero: BlocBuilder<ThemeBloc, ThemeState>(
        bloc: themeBloc,
        builder: (context, themeState) {
          return BlocBuilder<GamepadBloc, GamepadState>(
            builder: (context, gamepadState) {
              return DmSettingsHeroCard(
                icon: Icons.tune,
                title: 'Workspace Preferences',
                description:
                    'Theme mode, palette, local app metadata, and controller configuration live here.',
                footer: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DmSettingsMetaPill(
                      icon: Icons.brightness_6_outlined,
                      label: themeState.themeMode.title,
                    ),
                    DmSettingsMetaPill(
                      icon: Icons.palette_outlined,
                      label: themeState.theme.name,
                    ),
                    DmSettingsMetaPill(
                      icon: Icons.gamepad_outlined,
                      label: gamepadState.config.enabled
                          ? 'Controller enabled'
                          : 'Controller disabled',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        bloc: themeBloc,
        builder: (context, themeState) {
          return BlocBuilder<GamepadBloc, GamepadState>(
            builder: (context, gamepadState) {
              return SettingsList(
                sections: [
                  SettingsSection(
                    title: const Text('App'),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: const Icon(Icons.apps_outlined),
                        title: const Text('App Settings'),
                        description: const Text(
                          'Inspect local app metadata and diagnostics.',
                        ),
                        onPressed: (context) {
                          context.goNamed(AppSettingsScreen.name);
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: Text(context.l10n.smenuTheme),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: const Icon(Icons.brightness_medium_outlined),
                        title: Text(context.l10n.appearance),
                        description: const Text(
                          'Follow the system or force a specific mode.',
                        ),
                        value: themeState.themeMode.icon,
                        onPressed: (context) {
                          context.goNamed(AppearanceSettingsScreen.name);
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(Icons.palette_outlined),
                        title: Text(context.l10n.accentColor),
                        description: const Text(
                          'Choose the active Duskmoon palette.',
                        ),
                        value: Text(themeState.theme.name),
                        onPressed: (context) {
                          context.goNamed(AccentColorSettingsScreen.name);
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: Text(context.l10n.controllerSettings),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: const Icon(Icons.gamepad_outlined),
                        title: Text(context.l10n.controllerSettings),
                        description: const Text(
                          'Connected pads, mappings, deadzone, and live testing.',
                        ),
                        value: Text(
                          gamepadState.config.enabled ? 'Enabled' : 'Disabled',
                        ),
                        onPressed: (context) {
                          context.goNamed(ControllerSettingsScreen.name);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
