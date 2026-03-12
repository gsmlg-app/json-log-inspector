import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents the response portion of an HTTP log record.
@immutable
class ResponseData extends Equatable {
  const ResponseData({
    required this.status,
    required this.headers,
    this.body,
    this.bodyEncoding,
    required this.bodyTruncated,
    this.contentType,
  });

  final int status;
  final Map<String, List<String>> headers;
  final String? body;
  final String? bodyEncoding;
  final bool bodyTruncated;
  final String? contentType;

  ResponseData copyWith({
    int? status,
    Map<String, List<String>>? headers,
    String? Function()? body,
    String? Function()? bodyEncoding,
    bool? bodyTruncated,
    String? Function()? contentType,
  }) {
    return ResponseData(
      status: status ?? this.status,
      headers: headers ?? this.headers,
      body: body != null ? body() : this.body,
      bodyEncoding: bodyEncoding != null ? bodyEncoding() : this.bodyEncoding,
      bodyTruncated: bodyTruncated ?? this.bodyTruncated,
      contentType: contentType != null ? contentType() : this.contentType,
    );
  }

  @override
  List<Object?> get props => [
    status,
    headers,
    body,
    bodyEncoding,
    bodyTruncated,
    contentType,
  ];
}
