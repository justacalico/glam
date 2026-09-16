import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/api/api_exception.dart';

void main() {
  DioException dioError(int? status, {Object? data, DioExceptionType? type}) {
    final options = RequestOptions();
    return DioException(
      requestOptions: options,
      type:
          type ??
          (status == null
              ? DioExceptionType.connectionError
              : DioExceptionType.badResponse),
      response: status == null
          ? null
          : Response(requestOptions: options, statusCode: status, data: data),
    );
  }

  group('kind mapping', () {
    final cases = {
      401: ApiErrorKind.unauthorized,
      403: ApiErrorKind.forbidden,
      404: ApiErrorKind.notFound,
      409: ApiErrorKind.conflict,
      500: ApiErrorKind.server,
      503: ApiErrorKind.server,
      418: ApiErrorKind.unknown,
    };
    cases.forEach((status, kind) {
      test('$status → $kind', () {
        expect(ApiException.fromDio(dioError(status)).kind, kind);
      });
    });

    test('connection error → network', () {
      expect(ApiException.fromDio(dioError(null)).kind, ApiErrorKind.network);
    });
  });

  group('message extraction', () {
    test('reads message field', () {
      final e = ApiException.fromDio(
        dioError(400, data: {'message': 'bad request'}),
      );
      expect(e.message, 'bad request');
    });

    test('reads error field', () {
      final e = ApiException.fromDio(dioError(400, data: {'error': 'oops'}));
      expect(e.message, 'oops');
    });

    test('falls back to a default per kind', () {
      final e = ApiException.fromDio(dioError(404));
      expect(e.message, 'Not found');
    });
  });

  test('isAuthFailure', () {
    expect(ApiException.fromDio(dioError(401)).isAuthFailure, isTrue);
    expect(ApiException.fromDio(dioError(403)).isAuthFailure, isFalse);
  });

  test('toString includes kind and status', () {
    final e = ApiException.fromDio(dioError(404));
    expect(e.toString(), contains('notFound'));
    expect(e.toString(), contains('404'));
  });
}
