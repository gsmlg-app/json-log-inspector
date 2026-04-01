import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'request_data.dart';
import 'response_data.dart';

/// Represents a single parsed JSON log record.
@immutable
class LogRecord extends Equatable {
  const LogRecord({
    required this.ts,
    required this.requestId,
    required this.recordType,
    this.durationMs,
    this.request,
    this.response,
    required this.rawLine,
    this.json = const {},
  });

  /// Parses a [LogRecord] from a JSON map.
  ///
  /// The [rawLine] parameter should contain the original JSON string.
  factory LogRecord.fromJson(
    Map<String, dynamic> json, {
    required String rawLine,
  }) {
    return LogRecord(
      ts: json['ts'] as String? ?? json['time'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      recordType: json['record_type'] as String? ??
          json['level'] as String? ??
          'log',
      durationMs: (json['duration_ms'] as num?)?.toDouble(),
      request: json['request'] != null
          ? _parseRequest(json['request'] as Map<String, dynamic>)
          : null,
      response: json['response'] != null
          ? _parseResponse(json['response'] as Map<String, dynamic>)
          : null,
      rawLine: rawLine,
      json: json,
    );
  }

  final String ts;
  final String requestId;
  final String recordType;
  final double? durationMs;
  final RequestData? request;
  final ResponseData? response;
  final String rawLine;

  /// The original parsed JSON map.
  final Map<String, dynamic> json;

  LogRecord copyWith({
    String? ts,
    String? requestId,
    String? recordType,
    double? Function()? durationMs,
    RequestData? Function()? request,
    ResponseData? Function()? response,
    String? rawLine,
    Map<String, dynamic>? json,
  }) {
    return LogRecord(
      ts: ts ?? this.ts,
      requestId: requestId ?? this.requestId,
      recordType: recordType ?? this.recordType,
      durationMs: durationMs != null ? durationMs() : this.durationMs,
      request: request != null ? request() : this.request,
      response: response != null ? response() : this.response,
      rawLine: rawLine ?? this.rawLine,
      json: json ?? this.json,
    );
  }

  @override
  List<Object?> get props => [
    ts,
    requestId,
    recordType,
    durationMs,
    request,
    response,
    rawLine,
    json,
  ];

  static RequestData _parseRequest(Map<String, dynamic> json) {
    return RequestData(
      method: json['method'] as String,
      scheme: json['scheme'] as String,
      host: json['host'] as String,
      uri: json['uri'] as String,
      proto: json['proto'] as String,
      remoteAddr: json['remote_addr'] as String,
      headers: _parseHeaders(json['headers']),
      body: json['body'] as String?,
      bodyEncoding: json['body_encoding'] as String?,
      bodyTruncated: json['body_truncated'] as bool? ?? false,
      contentType: json['content_type'] as String?,
      contentLength: json['content_length'] as int?,
    );
  }

  static ResponseData _parseResponse(Map<String, dynamic> json) {
    return ResponseData(
      status: json['status'] as int,
      headers: _parseHeaders(json['headers']),
      body: json['body'] as String?,
      bodyEncoding: json['body_encoding'] as String?,
      bodyTruncated: json['body_truncated'] as bool? ?? false,
      contentType: json['content_type'] as String?,
    );
  }

  static Map<String, List<String>> _parseHeaders(dynamic headers) {
    if (headers == null) return {};
    final map = Map<String, dynamic>.from(headers as Map);
    return map.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
    );
  }
}
