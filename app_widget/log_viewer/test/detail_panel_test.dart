import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_models/log_models.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';

void main() {
  LogRecord makeRecord({
    String ts = '2024-01-01T00:00:00Z',
    String requestId = 'req-1',
    String recordType = 'exchange',
    double? durationMs,
    RequestData? request,
    ResponseData? response,
  }) {
    return LogRecord(
      ts: ts,
      requestId: requestId,
      recordType: recordType,
      durationMs: durationMs,
      request: request,
      response: response,
      rawLine: '{}',
    );
  }

  RequestData makeRequest({
    String method = 'GET',
    String uri = '/api/test',
    String proto = 'HTTP/2.0',
  }) {
    return RequestData(
      method: method,
      scheme: 'https',
      host: 'example.com',
      uri: uri,
      proto: proto,
      remoteAddr: '127.0.0.1:1234',
      headers: const {'Content-Type': ['application/json']},
      bodyTruncated: false,
    );
  }

  ResponseData makeResponse({int status = 200}) {
    return ResponseData(
      status: status,
      headers: const {'Content-Type': ['application/json']},
      bodyTruncated: false,
    );
  }

  Widget buildDetailPanel(LogRecord record, {LogRecord? pairedRecord}) {
    return MaterialApp(
      home: Scaffold(
        body: DetailPanel(record: record, pairedRecord: pairedRecord),
      ),
    );
  }

  group('DetailPanel', () {
    testWidgets('shows record type in metadata bar', (tester) async {
      final record = makeRecord(recordType: 'exchange');
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('EXCHANGE'), findsOneWidget);
    });

    testWidgets('shows timestamp', (tester) async {
      final record = makeRecord(ts: '2024-06-15T10:30:00Z');
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('2024-06-15T10:30:00Z'), findsOneWidget);
    });

    testWidgets('shows request ID', (tester) async {
      final record = makeRecord(requestId: 'abc-123');
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('ID: abc-123'), findsOneWidget);
    });

    testWidgets('shows request section when request data present', (tester) async {
      final record = makeRecord(
        request: makeRequest(method: 'POST', uri: '/api/messages'),
      );
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('Request'), findsOneWidget);
      expect(find.text('POST /api/messages HTTP/2.0'), findsOneWidget);
    });

    testWidgets('shows response section with status', (tester) async {
      final record = makeRecord(
        durationMs: 42.5,
        response: makeResponse(status: 200),
      );
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('Response'), findsOneWidget);
      expect(find.text('200 (42.5 ms)'), findsOneWidget);
    });

    testWidgets('handles record with neither request nor response', (tester) async {
      final record = makeRecord();
      await tester.pumpWidget(buildDetailPanel(record));
      expect(find.text('EXCHANGE'), findsOneWidget);
      expect(find.text('Request'), findsNothing);
      expect(find.text('Response'), findsNothing);
    });

    testWidgets('uses paired record for missing request data', (tester) async {
      final record = makeRecord(recordType: 'response');
      final paired = makeRecord(
        recordType: 'request',
        request: makeRequest(method: 'PUT', uri: '/api/update'),
      );
      await tester.pumpWidget(buildDetailPanel(record, pairedRecord: paired));
      expect(find.text('PUT /api/update HTTP/2.0'), findsOneWidget);
    });
  });
}
