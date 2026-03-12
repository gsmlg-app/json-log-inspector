import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/app/error_screen.dart';
import 'package:json_log_inspector/screens/app/splash_screen.dart';
import 'package:json_log_inspector/screens/home/home_screen.dart';
import 'package:json_log_inspector/screens/log_viewer/log_viewer_screen.dart';
import 'package:json_log_inspector/screens/settings/accent_color_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/app_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/appearance_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/controller_settings_screen.dart';
import 'package:json_log_inspector/screens/settings/controller_test_screen.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>(
    debugLabel: 'routerKey',
  );

  static GoRouter router = GoRouter(
    navigatorKey: key,
    debugLogDiagnostics: true,
    initialLocation: LogViewerScreen.path,
    routes: routes,
    errorBuilder: (context, state) {
      return ErrorScreen(routerState: state);
    },
  );

  static List<GoRoute> routes = [
    GoRoute(
      name: SplashScreen.name,
      path: SplashScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      name: LogViewerScreen.name,
      path: LogViewerScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const LogViewerScreen(),
        );
      },
    ),
    GoRoute(
      name: HomeScreen.name,
      path: HomeScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      name: SettingsScreen.name,
      path: SettingsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SettingsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: AppSettingsScreen.name,
          path: AppSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AppearanceSettingsScreen.name,
          path: AppearanceSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppearanceSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AccentColorSettingsScreen.name,
          path: AccentColorSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AccentColorSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: ControllerSettingsScreen.name,
          path: ControllerSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const ControllerSettingsScreen(),
            );
          },
          routes: [
            GoRoute(
              name: ControllerTestScreen.name,
              path: ControllerTestScreen.path,
              pageBuilder: (context, state) {
                return NoTransitionPage<void>(
                  key: state.pageKey,
                  restorationId: state.pageKey.value,
                  child: const ControllerTestScreen(),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
