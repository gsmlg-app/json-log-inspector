import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents the request portion of an HTTP log record.
@immutable
class RequestData extends Equatable {
  const RequestData({
    required this.method,
    required this.scheme,
    required this.host,
    required this.uri,
    required this.proto,
    required this.remoteAddr,
    required this.headers,
    this.body,
    this.bodyEncoding,
    required this.bodyTruncated,
    this.contentType,
    this.contentLength,
  });

  final String method;
  final String scheme;
  final String host;
  final String uri;
  final String proto;
  final String remoteAddr;
  final Map<String, List<String>> headers;
  final String? body;
  final String? bodyEncoding;
  final bool bodyTruncated;
  final String? contentType;
  final int? contentLength;

  RequestData copyWith({
    String? method,
    String? scheme,
    String? host,
    String? uri,
    String? proto,
    String? remoteAddr,
    Map<String, List<String>>? headers,
    String? Function()? body,
    String? Function()? bodyEncoding,
    bool? bodyTruncated,
    String? Function()? contentType,
    int? Function()? contentLength,
  }) {
    return RequestData(
      method: method ?? this.method,
      scheme: scheme ?? this.scheme,
      host: host ?? this.host,
      uri: uri ?? this.uri,
      proto: proto ?? this.proto,
      remoteAddr: remoteAddr ?? this.remoteAddr,
      headers: headers ?? this.headers,
      body: body != null ? body() : this.body,
      bodyEncoding: bodyEncoding != null ? bodyEncoding() : this.bodyEncoding,
      bodyTruncated: bodyTruncated ?? this.bodyTruncated,
      contentType: contentType != null ? contentType() : this.contentType,
      contentLength: contentLength != null
          ? contentLength()
          : this.contentLength,
    );
  }

  @override
  List<Object?> get props => [
    method,
    scheme,
    host,
    uri,
    proto,
    remoteAddr,
    headers,
    body,
    bodyEncoding,
    bodyTruncated,
    contentType,
    contentLength,
  ];
}
