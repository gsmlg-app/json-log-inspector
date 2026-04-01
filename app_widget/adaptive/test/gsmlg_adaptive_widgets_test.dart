import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DmCard renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DmCard(child: Text('Adaptive card'))),
      ),
    );

    expect(find.text('Adaptive card'), findsOneWidget);
  });

  testWidgets('DmButton calls callback when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DmButton(
            onPressed: () => tapped = true,
            child: const Text('Press'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Press'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('DmAppBar shows title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: DmAppBar(
            title: Text('Settings'),
            subtitle: 'Adaptive page chrome',
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Adaptive page chrome'), findsOneWidget);
  });
}
