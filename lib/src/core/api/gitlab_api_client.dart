import 'package:dio/dio.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paginated_response.dart';

/// Thin wrapper over [Dio] that speaks to a GitLab instance's REST v4 API.
///
/// All JSON decoding goes through the caller-provided `decoder` so the
/// client itself stays free of model knowledge.
class GitLabApiClient {
  GitLabApiClient({required String baseUrl, String? token, Dio? dio})
    : _baseUrl = normalizeInstanceUrl(baseUrl),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _apiBase(normalizeInstanceUrl(baseUrl)),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ),
          ) {
    _dio.options.baseUrl = _apiBase(_baseUrl);
    if (token != null) {
      _dio.options.headers['PRIVATE-TOKEN'] = token;
    }
  }

  final Dio _dio;
  final String _baseUrl;

  Dio get dio => _dio;

  /// The instance's root URL without a trailing slash, e.g.
  /// `https://gitlab.com`.
  String get baseUrl => _baseUrl;

  /// Normalizes user input into a bare instance URL.
  ///
  /// Accepts `gitlab.com`, `https://gitlab.com/`, and URLs that already
  /// point at `/api/v4`.
  static String normalizeInstanceUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) {
      return 'https://gitlab.com';
    }
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api/v4')) {
      url = url.substring(0, url.length - '/api/v4'.length);
    }
    return url;
  }

  static String _apiBase(String baseUrl) => '$baseUrl/api/v4';

  /// Sets or clears the token used for every request.
  set token(String? value) {
    if (value == null) {
      _dio.options.headers.remove('PRIVATE-TOKEN');
    } else {
      _dio.options.headers['PRIVATE-TOKEN'] = value;
    }
  }

  /// Encodes a project id or `namespace/path` for use in a URL segment.
  static String encodeProject(Object idOrPath) =>
      Uri.encodeComponent(idOrPath.toString());

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    required T Function(Object? json) decoder,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: _clean(query),
        options: options,
      );
      return decoder(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<T>> getList<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Object? json) decoder,
  }) async {
    return get<List<T>>(
      path,
      query: query,
      decoder: (json) => _decodeList(json, decoder),
    );
  }

  /// GET a list endpoint and expose GitLab's pagination headers.
  Future<Paginated<T>> getPage<T>(
    String path, {
    Map<String, dynamic>? query,
    int page = 1,
    int perPage = 20,
    required T Function(Object? json) decoder,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: _clean({...?query, 'page': page, 'per_page': perPage}),
      );
      final headers = response.headers.map.map(
        (key, values) => MapEntry(key.toLowerCase(), values),
      );
      int? headerInt(String name) =>
          int.tryParse(headers[name]?.firstOrNull ?? '');
      return Paginated<T>(
        items: _decodeList(response.data, decoder),
        page: headerInt('x-page') ?? page,
        perPage: headerInt('x-per-page') ?? perPage,
        nextPage: headerInt('x-next-page'),
        total: headerInt('x-total'),
        totalPages: headerInt('x-total-pages'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Fetches every page of a list endpoint. Use for small, bounded lists
  /// (labels, members of a small group) — not for commit history.
  Future<List<T>> getAll<T>(
    String path, {
    Map<String, dynamic>? query,
    int perPage = 100,
    int maxPages = 20,
    required T Function(Object? json) decoder,
  }) async {
    final items = <T>[];
    var page = 1;
    while (page <= maxPages) {
      final result = await getPage<T>(
        path,
        query: query,
        page: page,
        perPage: perPage,
        decoder: decoder,
      );
      items.addAll(result.items);
      if (!result.hasMore) {
        break;
      }
      page = result.nextPage!;
    }
    return items;
  }

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required T Function(Object? json) decoder,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        queryParameters: _clean(query),
        data: body,
      );
      return decoder(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> put<T>(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required T Function(Object? json) decoder,
  }) async {
    try {
      final response = await _dio.put<Object?>(
        path,
        queryParameters: _clean(query),
        data: body,
      );
      return decoder(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T?> delete<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? json)? decoder,
  }) async {
    try {
      final response = await _dio.delete<Object?>(
        path,
        queryParameters: _clean(query),
      );
      if (decoder == null) {
        return null;
      }
      return decoder(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET a raw response body (job traces, raw files, plain text).
  Future<String> getRaw(
    String path, {
    Map<String, dynamic>? query,
    String? ref,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: _clean({...?query, 'ref': ?ref}),
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) {
      return null;
    }
    final cleaned = Map<String, dynamic>.from(query)
      ..removeWhere((_, value) => value == null);
    return cleaned.isEmpty ? null : cleaned;
  }

  List<T> _decodeList<T>(Object? json, T Function(Object?) decoder) {
    if (json is! List) {
      return const [];
    }
    return json.map(decoder).toList();
  }
}
