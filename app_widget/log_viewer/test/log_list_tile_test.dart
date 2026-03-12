import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';

void main() {
  Widget buildTile({
    String rawLine = '{"ts":"2024-01-01"}',
    int index = 0,
    bool isSelected = false,
    bool isError = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LogListTile(
          rawLine: rawLine,
          index: index,
          isSelected: isSelected,
          isError: isError,
          onTap: onTap,
        ),
      ),
    );
  }

  group('LogListTile', () {
    testWidgets('renders raw line text', (tester) async {
      await tester.pumpWidget(buildTile(rawLine: '{"test":"value"}'));
      expect(find.text('{"test":"value"}'), findsOneWidget);
    });

    testWidgets('shows 1-based line number', (tester) async {
      await tester.pumpWidget(buildTile(index: 5));
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTile(onTap: () => tapped = true));
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows error icon when isError is true', (tester) async {
      await tester.pumpWidget(buildTile(isError: true));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('does not show error icon when isError is false', (tester) async {
      await tester.pumpWidget(buildTile(isError: false));
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
