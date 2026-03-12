import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/log_viewer/log_viewer_screen.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class Destinations {
  /// List of route names corresponding to navigation destinations
  static const List<String> routeNames = [
    LogViewerScreen.name,
    SettingsScreen.name,
  ];

  static List<NavigationDestination> navs(BuildContext context) =>
      <NavigationDestination>[
        NavigationDestination(
          key: const Key(LogViewerScreen.name),
          icon: const Icon(Icons.article_outlined),
          selectedIcon: const Icon(Icons.article),
          label: 'Log Viewer',
        ),
        NavigationDestination(
          key: const Key(SettingsScreen.name),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: context.l10n.navSetting,
        ),
      ];

  static int indexOf(Key key, BuildContext context) {
    return navs(context).indexWhere((element) => element.key == key);
  }

  /// Handle navigation index change using GoRouter
  static void changeHandler(int idx, BuildContext context) {
    if (idx >= 0 && idx < routeNames.length) {
      context.goNamed(routeNames[idx]);
    }
  }
}
