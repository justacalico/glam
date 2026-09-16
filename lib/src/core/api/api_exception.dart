import 'package:dio/dio.dart';

/// Kinds of failure the API layer can surface.
enum ApiErrorKind {
  network,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  server,
  unknown,
}

/// A normalized error coming out of [GitLabApiClient].
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = switch (data) {
      {'message': final m} => m.toString(),
      {'error': final e} => e.toString(),
      _ => null,
    };

    final code = status ?? -1;
    final kind = switch (code) {
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      >= 500 => ApiErrorKind.server,
      _
          when error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout =>
        ApiErrorKind.network,
      _ => ApiErrorKind.unknown,
    };

    return ApiException(
      kind: kind,
      statusCode: status,
      message: serverMessage ?? _defaultMessage(kind),
    );
  }

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  static String _defaultMessage(ApiErrorKind kind) => switch (kind) {
    ApiErrorKind.network => 'Could not reach the server',
    ApiErrorKind.unauthorized => 'Session expired, sign in again',
    ApiErrorKind.forbidden => 'You do not have access to this',
    ApiErrorKind.notFound => 'Not found',
    ApiErrorKind.conflict => 'Request conflicts with current state',
    ApiErrorKind.server => 'The server ran into a problem',
    ApiErrorKind.unknown => 'Something went wrong',
  };

  bool get isAuthFailure => kind == ApiErrorKind.unauthorized;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
