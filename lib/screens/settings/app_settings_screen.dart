import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:json_log_inspector/screens/settings/widgets/settings_page_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatelessWidget {
  static const name = 'App Settings';
  static const path = 'app';
  static const fullPath = '${SettingsScreen.path}/$name';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedPrefs = context.read<SharedPreferences>();
    final appName = sharedPrefs.getString('APP_NAME');

    return DmSettingsPageShell(
      selectedKey: const Key(SettingsScreen.name),
      title: 'App Settings',
      subtitle: 'Read local metadata and quick diagnostics for this app.',
      hero: DmSettingsHeroCard(
        icon: Icons.apps_outlined,
        title: 'Application Metadata',
        description:
            'Values stored in local preferences are surfaced here for quick inspection.',
        footer: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DmSettingsMetaPill(
              icon: Icons.label_outline,
              label: appName == null ? 'APP_NAME: N/A' : 'APP_NAME: $appName',
            ),
          ],
        ),
      ),
      child: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Metadata'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.api_outlined),
                title: const Text('APP_NAME'),
                description: const Text(
                  'Stored application display name from preferences.',
                ),
                value: Text(appName ?? 'N/A'),
                onPressed: (context) {
                  showDmDialog(
                    context: context,
                    title: Text(context.l10n.appName),
                    content: Text(context.l10n.welcomeHome),
                    actions: [
                      DmDialogAction(
                        onPressed: (context) {
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.ok),
                      ),
                      DmDialogAction(
                        onPressed: (context) {
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.cancel),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
