import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_models/log_models.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';

void main() {
  group('FilterBar', () {
    late List<FilterRule> capturedRules;
    late List<String> capturedSearches;

    setUp(() {
      capturedRules = [];
      capturedSearches = [];
    });

    Widget buildFilterBar({List<FilterRule> activeRules = const []}) {
      return MaterialApp(
        home: Scaffold(
          body: FilterBar(
            onFilterAdded: (rule) => capturedRules.add(rule),
            onSearchChanged: (query) => capturedSearches.add(query),
            activeRules: activeRules,
          ),
        ),
      );
    }

    testWidgets('renders filter and search inputs', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('submitting filter text creates rule', (tester) async {
      await tester.pumpWidget(buildFilterBar());

      final filterInput = find.byType(TextField).first;
      await tester.enterText(filterInput, 'request.method:==:POST');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(capturedRules, hasLength(1));
      expect(capturedRules.first.keyPath, 'request.method');
      expect(capturedRules.first.operator, FilterOperator.equals);
      expect(capturedRules.first.value, 'POST');
    });

    testWidgets('does not create rule for invalid input', (tester) async {
      await tester.pumpWidget(buildFilterBar());

      final filterInput = find.byType(TextField).first;
      await tester.enterText(filterInput, 'invalid');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(capturedRules, isEmpty);
    });

    testWidgets('shows active rules as chips', (tester) async {
      final rules = [
        const FilterRule(
          id: '1',
          keyPath: 'response.status',
          operator: FilterOperator.greaterThanOrEqual,
          value: '400',
          enabled: true,
        ),
      ];
      await tester.pumpWidget(buildFilterBar(activeRules: rules));
      expect(find.byType(FilterChip), findsOneWidget);
    });

    testWidgets('handles values containing colons', (tester) async {
      await tester.pumpWidget(buildFilterBar());

      final filterInput = find.byType(TextField).first;
      await tester.enterText(
        filterInput,
        'request.uri:contains:http://example.com',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(capturedRules, hasLength(1));
      expect(capturedRules.first.value, 'http://example.com');
    });
  });
}
