import 'dart:convert';

import 'package:log_models/log_models.dart';
import 'package:test/test.dart';

void main() {
  group('LogRecord.fromJson', () {
    test('parses a complete request log record', () {
      final json = {
        'ts': '2024-01-15T10:30:00.123Z',
        'request_id': 'abc-123',
        'record_type': 'request',
        'request': {
          'method': 'GET',
          'scheme': 'https',
          'host': 'example.com',
          'uri': '/api/v1/users',
          'proto': 'HTTP/2.0',
          'remote_addr': '192.168.1.1:54321',
          'headers': {
            'Accept': ['application/json'],
            'Authorization': ['Bearer token123'],
          },
          'body': null,
          'body_encoding': null,
          'body_truncated': false,
          'content_type': 'application/json',
          'content_length': 0,
        },
      };

      final rawLine = jsonEncode(json);
      final record = LogRecord.fromJson(json, rawLine: rawLine);

      expect(record.ts, '2024-01-15T10:30:00.123Z');
      expect(record.requestId, 'abc-123');
      expect(record.recordType, 'request');
      expect(record.durationMs, isNull);
      expect(record.response, isNull);
      expect(record.rawLine, rawLine);

      final request = record.request!;
      expect(request.method, 'GET');
      expect(request.scheme, 'https');
      expect(request.host, 'example.com');
      expect(request.uri, '/api/v1/users');
      expect(request.proto, 'HTTP/2.0');
      expect(request.remoteAddr, '192.168.1.1:54321');
      expect(request.headers['Accept'], ['application/json']);
      expect(request.headers['Authorization'], ['Bearer token123']);
      expect(request.body, isNull);
      expect(request.bodyTruncated, false);
      expect(request.contentType, 'application/json');
      expect(request.contentLength, 0);
    });

    test('parses a complete response log record', () {
      final json = {
        'ts': '2024-01-15T10:30:00.456Z',
        'request_id': 'abc-123',
        'record_type': 'response',
        'duration_ms': 42.5,
        'response': {
          'status': 200,
          'headers': {
            'Content-Type': ['application/json; charset=utf-8'],
          },
          'body': '{"users": []}',
          'body_encoding': 'utf-8',
          'body_truncated': false,
          'content_type': 'application/json',
        },
      };

      final rawLine = jsonEncode(json);
      final record = LogRecord.fromJson(json, rawLine: rawLine);

      expect(record.ts, '2024-01-15T10:30:00.456Z');
      expect(record.requestId, 'abc-123');
      expect(record.recordType, 'response');
      expect(record.durationMs, 42.5);
      expect(record.request, isNull);

      final response = record.response!;
      expect(response.status, 200);
      expect(response.headers['Content-Type'], [
        'application/json; charset=utf-8',
      ]);
      expect(response.body, '{"users": []}');
      expect(response.bodyEncoding, 'utf-8');
      expect(response.bodyTruncated, false);
      expect(response.contentType, 'application/json');
    });

    test('parses a record with both request and response', () {
      final json = {
        'ts': '2024-01-15T10:30:00.789Z',
        'request_id': 'def-456',
        'record_type': 'handled_response',
        'duration_ms': 150.0,
        'request': {
          'method': 'POST',
          'scheme': 'https',
          'host': 'api.example.com',
          'uri': '/data',
          'proto': 'HTTP/1.1',
          'remote_addr': '10.0.0.1:12345',
          'headers': {},
          'body': '{"key": "value"}',
          'body_encoding': 'utf-8',
          'body_truncated': false,
          'content_type': 'application/json',
          'content_length': 16,
        },
        'response': {'status': 201, 'headers': {}, 'body_truncated': false},
      };

      final rawLine = jsonEncode(json);
      final record = LogRecord.fromJson(json, rawLine: rawLine);

      expect(record.request, isNotNull);
      expect(record.response, isNotNull);
      expect(record.request!.method, 'POST');
      expect(record.request!.body, '{"key": "value"}');
      expect(record.response!.status, 201);
      expect(record.durationMs, 150.0);
    });

    test('supports equality via Equatable', () {
      final json = {
        'ts': '2024-01-15T10:30:00.123Z',
        'request_id': 'abc-123',
        'record_type': 'request',
      };
      const rawLine = '{"ts":"2024-01-15T10:30:00.123Z"}';

      final record1 = LogRecord.fromJson(json, rawLine: rawLine);
      final record2 = LogRecord.fromJson(json, rawLine: rawLine);

      expect(record1, equals(record2));
    });

    test('copyWith creates a modified copy', () {
      final json = {
        'ts': '2024-01-15T10:30:00.123Z',
        'request_id': 'abc-123',
        'record_type': 'request',
      };
      const rawLine = 'original';

      final record = LogRecord.fromJson(json, rawLine: rawLine);
      final modified = record.copyWith(recordType: 'response');

      expect(modified.recordType, 'response');
      expect(modified.ts, record.ts);
      expect(modified.requestId, record.requestId);
    });
  });

  group('FilterRule', () {
    test('supports equality', () {
      const rule1 = FilterRule(
        id: '1',
        keyPath: 'status',
        operator: FilterOperator.equals,
        value: '200',
        enabled: true,
      );
      const rule2 = FilterRule(
        id: '1',
        keyPath: 'status',
        operator: FilterOperator.equals,
        value: '200',
        enabled: true,
      );

      expect(rule1, equals(rule2));
    });

    test('copyWith works correctly', () {
      const rule = FilterRule(
        id: '1',
        keyPath: 'status',
        operator: FilterOperator.equals,
        value: '200',
        enabled: true,
      );

      final disabled = rule.copyWith(enabled: false);
      expect(disabled.enabled, false);
      expect(disabled.id, '1');
      expect(disabled.keyPath, 'status');
    });
  });

  group('FilterPreset', () {
    test('holds a list of rules', () {
      const preset = FilterPreset(
        name: 'Errors Only',
        rules: [
          FilterRule(
            id: '1',
            keyPath: 'response.status',
            operator: FilterOperator.greaterThanOrEqual,
            value: '400',
            enabled: true,
          ),
        ],
      );

      expect(preset.name, 'Errors Only');
      expect(preset.rules, hasLength(1));
    });
  });
}
