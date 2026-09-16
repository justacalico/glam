import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/wiki/domain/wiki_page.dart';

/// `/projects/:id/wikis` CRUD.
class WikiRepository {
  const WikiRepository(this._client);

  final GitLabApiClient _client;

  String _base(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}/wikis';

  WikiPage _decode(Object? j) => WikiPage.fromJson(j! as Map<String, dynamic>);

  Future<Paginated<WikiPage>> pages(
    Object projectId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      _base(projectId),
      query: {'search': ?search, 'with_content': false},
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// One page with its content.
  Future<WikiPage> page(Object projectId, String slug) {
    return _client.get(
      '${_base(projectId)}/${Uri.encodeComponent(slug)}',
      decoder: _decode,
    );
  }

  Future<WikiPage> create(
    Object projectId, {
    required String title,
    required String content,
    String format = 'markdown',
  }) {
    return _client.post(
      _base(projectId),
      body: {'title': title, 'content': content, 'format': format},
      decoder: _decode,
    );
  }

  Future<WikiPage> update(
    Object projectId,
    String slug, {
    String? title,
    String? content,
  }) {
    return _client.put(
      '${_base(projectId)}/${Uri.encodeComponent(slug)}',
      body: {'title': ?title, 'content': ?content},
      decoder: _decode,
    );
  }

  Future<void> delete(Object projectId, String slug) {
    return _client.delete('${_base(projectId)}/${Uri.encodeComponent(slug)}');
  }
}
