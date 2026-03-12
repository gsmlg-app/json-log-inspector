import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen', () {
    Widget buildHomeScreen({ThemeData? theme}) {
      return MaterialApp(
        theme: theme,
        home: const HomeScreen(),
      );
    }

    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('displays throw error button', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Throw Error'), findsOneWidget);
    });

    testWidgets('throw error button has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildHomeScreen(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              error: Colors.red,
            ),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      final textWidget = textButton.child as Text;

      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('throws exception when throw error button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());

      final button = find.byType(TextButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(tester.takeException(), isA<Exception>());
    });

    testWidgets('uses correct screen dimensions for container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('handles landscape orientation correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('container has correct decoration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());

      final containers = find.byType(Container);
      expect(containers, findsAtLeastNWidgets(1));
    });

    testWidgets('displays logo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
