import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';

void main() {
  Widget buildTree(dynamic data, {bool initiallyExpanded = false}) {
    return MaterialApp(
      home: Scaffold(
        body: JsonTreeView(data: data, initiallyExpanded: initiallyExpanded),
      ),
    );
  }

  group('JsonTreeView', () {
    testWidgets('renders string leaf value', (tester) async {
      await tester.pumpWidget(buildTree('hello'));
      expect(find.text('"hello"'), findsOneWidget);
    });

    testWidgets('renders number leaf value', (tester) async {
      await tester.pumpWidget(buildTree(42));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders boolean leaf value', (tester) async {
      await tester.pumpWidget(buildTree(true));
      expect(find.text('true'), findsOneWidget);
    });

    testWidgets('renders null leaf value', (tester) async {
      await tester.pumpWidget(buildTree(null));
      expect(find.text('null'), findsOneWidget);
    });

    testWidgets('renders object type label', (tester) async {
      await tester.pumpWidget(buildTree({'key': 'value'}));
      expect(find.text('Object'), findsOneWidget);
    });

    testWidgets('renders array type label', (tester) async {
      await tester.pumpWidget(buildTree([1, 2, 3]));
      expect(find.text('Array'), findsOneWidget);
    });

    testWidgets('shows object count preview', (tester) async {
      await tester.pumpWidget(buildTree({'a': 1, 'b': 2}));
      expect(find.text('{2}'), findsOneWidget);
    });

    testWidgets('shows array count preview', (tester) async {
      await tester.pumpWidget(buildTree([1, 2, 3]));
      expect(find.text('[3]'), findsOneWidget);
    });

    testWidgets('expands map when initiallyExpanded is true', (tester) async {
      await tester.pumpWidget(buildTree({'name': 'test'}, initiallyExpanded: true));
      expect(find.text('name: '), findsOneWidget);
      expect(find.text('"test"'), findsOneWidget);
    });

    testWidgets('does not show children when collapsed', (tester) async {
      await tester.pumpWidget(buildTree({'name': 'test'}, initiallyExpanded: false));
      expect(find.text('"test"'), findsNothing);
    });

    testWidgets('toggles expand/collapse on tap', (tester) async {
      await tester.pumpWidget(buildTree({'name': 'test'}, initiallyExpanded: false));
      expect(find.text('"test"'), findsNothing);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('"test"'), findsOneWidget);
    });
  });
}
