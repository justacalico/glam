import 'package:dio/dio.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';

import 'fake_dio_adapter.dart';

/// Builds a [GitLabApiClient] backed by a [FakeDioAdapter].
(GitLabApiClient, FakeDioAdapter) testClient({String? token}) {
  final adapter = FakeDioAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://gitlab.example.com/api/v4'))
    ..httpClientAdapter = adapter;
  final client = GitLabApiClient(
    baseUrl: 'https://gitlab.example.com',
    token: token ?? 'test-token',
    dio: dio,
  );
  return (client, adapter);
}
