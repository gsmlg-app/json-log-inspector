import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

void main() {
  group('SettingsScreen', () {
    late ThemeBloc themeBloc;
    late GamepadBloc gamepadBloc;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeBloc = ThemeBloc(sharedPreferences);
      gamepadBloc = GamepadBloc(
        navigatorKey: GlobalKey<NavigatorState>(),
        routeNames: ['Log Viewer', 'Settings'],
      );
    });

    tearDown(() {
      themeBloc.close();
      gamepadBloc.close();
      sharedPreferences.clear();
    });

    Widget buildSettingsScreen() {
      return RepositoryProvider<SharedPreferences>(
        create: (context) => sharedPreferences,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeBloc>(create: (context) => themeBloc),
            BlocProvider<GamepadBloc>(create: (context) => gamepadBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildSettingsScreen());

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Workspace Preferences'), findsOneWidget);
    });

    testWidgets('displays settings sections', (WidgetTester tester) async {
      await tester.pumpWidget(buildSettingsScreen());

      expect(find.text('App Settings'), findsOneWidget);
    });

    testWidgets('shows appearance option', (WidgetTester tester) async {
      await tester.pumpWidget(buildSettingsScreen());

      expect(find.byIcon(Icons.brightness_medium_outlined), findsOneWidget);
    });

    testWidgets('shows accent color option', (WidgetTester tester) async {
      await tester.pumpWidget(buildSettingsScreen());

      expect(find.byIcon(Icons.palette_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('app settings tile has correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildSettingsScreen());

      expect(find.byIcon(Icons.apps_outlined), findsOneWidget);
    });
  });
}
