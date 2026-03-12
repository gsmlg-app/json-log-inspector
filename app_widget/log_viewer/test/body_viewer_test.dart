import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';

void main() {
  Widget buildBodyViewer({
    String? body,
    String? contentType,
    String? bodyEncoding,
    bool bodyTruncated = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BodyViewer(
          body: body,
          contentType: contentType,
          bodyEncoding: bodyEncoding,
          bodyTruncated: bodyTruncated,
        ),
      ),
    );
  }

  group('BodyViewer', () {
    testWidgets('shows empty body message for null body', (tester) async {
      await tester.pumpWidget(buildBodyViewer(body: null));
      expect(find.text('(empty body)'), findsOneWidget);
    });

    testWidgets('shows empty body message for empty string', (tester) async {
      await tester.pumpWidget(buildBodyViewer(body: ''));
      expect(find.text('(empty body)'), findsOneWidget);
    });

    testWidgets('renders plain text body', (tester) async {
      await tester.pumpWidget(buildBodyViewer(body: 'hello world'));
      expect(find.text('hello world'), findsOneWidget);
    });

    testWidgets('renders JSON body as tree when content-type is application/json', (tester) async {
      await tester.pumpWidget(buildBodyViewer(
        body: '{"key":"value"}',
        contentType: 'application/json',
      ));
      expect(find.text('Object'), findsOneWidget);
    });

    testWidgets('falls back to text for invalid JSON with json content-type', (tester) async {
      await tester.pumpWidget(buildBodyViewer(
        body: 'not valid json',
        contentType: 'application/json',
      ));
      expect(find.text('not valid json'), findsOneWidget);
    });

    testWidgets('shows base64 placeholder', (tester) async {
      await tester.pumpWidget(buildBodyViewer(
        body: 'aGVsbG8=',
        bodyEncoding: 'base64',
      ));
      expect(find.textContaining('base64 binary'), findsOneWidget);
    });

    testWidgets('shows truncation warning when bodyTruncated is true', (tester) async {
      await tester.pumpWidget(buildBodyViewer(
        body: 'some data',
        bodyTruncated: true,
      ));
      expect(find.text('Body was truncated'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('does not show truncation warning when bodyTruncated is false', (tester) async {
      await tester.pumpWidget(buildBodyViewer(
        body: 'some data',
        bodyTruncated: false,
      ));
      expect(find.text('Body was truncated'), findsNothing);
    });
  });
}
