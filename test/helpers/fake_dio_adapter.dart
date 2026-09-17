import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A [HttpClientAdapter] that answers requests from a routing table
/// instead of the network. Repositories under test run through the real
/// Dio pipeline (headers, query encoding, response decoding), only the
/// socket is faked.
class FakeDioAdapter implements HttpClientAdapter {
  /// Maps `METHOD /path` (no query) to a queue of canned responses.
  /// Repeated calls to the same route pop the next response, then keep
  /// returning the last one — handy for pagination stubs.
  final Map<String, List<StubbedResponse>> routes = {};

  /// Every request that came through, for assertions.
  final List<RequestOptions> requests = [];

  void _add(String method, String path, StubbedResponse response) {
    routes.putIfAbsent('$method $path', () => []).add(response);
  }

  /// Register a JSON response for `GET [path]`.
  void get(
    String path,
    Object? body, {
    int status = 200,
    Map<String, List<String>> headers = const {},
  }) {
    _add(
      'GET',
      path,
      StubbedResponse(status: status, body: body, headers: headers),
    );
  }

  void post(
    String path,
    Object? body, {
    int status = 200,
    Map<String, List<String>> headers = const {},
  }) {
    _add(
      'POST',
      path,
      StubbedResponse(status: status, body: body, headers: headers),
    );
  }

  void put(String path, Object? body, {int status = 200}) {
    _add('PUT', path, StubbedResponse(status: status, body: body));
  }

  void delete(String path, {int status = 204}) {
    _add('DELETE', path, StubbedResponse(status: status, body: null));
  }

  /// Throw a [DioException] for `[method] [path]` (default GET).
  void fail(
    String path, {
    int status = 500,
    String method = 'GET',
    Object? body,
  }) {
    _add(
      method,
      path,
      StubbedResponse(
        status: status,
        body: body ?? {'message': 'server error'},
      ),
    );
  }

  RequestOptions? get lastRequest => requests.lastOrNull;

  List<RequestOptions> requestsTo(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final queue = routes['${options.method} ${options.path}'];
    if (queue == null || queue.isEmpty) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'message': 'no stub for ${options.method} ${options.path}'},
        ),
      );
    }
    final stub = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (stub.status >= 400) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: stub.status,
          data: stub.body,
        ),
      );
    }
    final isRedirect = stub.status >= 300 && stub.status < 400;
    if (stub.body is Uint8List) {
      return ResponseBody.fromBytes(
        stub.body! as Uint8List,
        stub.status,
        headers: stub.headers,
        isRedirect: isRedirect,
      );
    }
    final isJson = stub.body is! String;
    return ResponseBody.fromString(
      isJson ? jsonEncode(stub.body) : stub.body! as String,
      stub.status,
      headers: {
        if (isJson) Headers.contentTypeHeader: ['application/json'],
        ...stub.headers,
      },
      isRedirect: isRedirect,
    );
  }

  @override
  void close({bool force = false}) {}
}

class StubbedResponse {
  const StubbedResponse({
    required this.status,
    required this.body,
    this.headers = const {},
  });

  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
}
