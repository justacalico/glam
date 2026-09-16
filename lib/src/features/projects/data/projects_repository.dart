import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/projects/domain/ci_variable.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';

/// Talks to `/projects` and related endpoints.
class ProjectsRepository {
  const ProjectsRepository(this._client);

  final GitLabApiClient _client;

  /// Paginated project list honoring [filter].
  Future<Paginated<Project>> list({
    required ProjectFilter filter,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/projects',
      query: filter.toQuery(),
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  Future<Project> get(Object id) {
    return _client.get(
      '/projects/${GitLabApiClient.encodeProject(id)}',
      decoder: _decodeOne,
    );
  }

  /// `PUT /projects/:id/star` — returns the updated project.
  Future<Project> star(Object id) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/star',
      decoder: _decodeOne,
    );
  }

  Future<Project> unstar(Object id) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/unstar',
      decoder: _decodeOne,
    );
  }

  /// `POST /projects/:id/fork`.
  Future<Project> fork(Object id) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/fork',
      decoder: _decodeOne,
    );
  }

  /// General settings: name, description, visibility, topics.
  Future<Project> updateProject(
    Object id, {
    String? name,
    String? description,
    String? visibility,
    List<String>? topics,
    bool? issuesEnabled,
    bool? mergeRequestsEnabled,
    bool? wikiEnabled,
    bool? snippetsEnabled,
  }) {
    return _client.put(
      '/projects/${GitLabApiClient.encodeProject(id)}',
      body: {
        'name': ?name,
        'description': ?description,
        'visibility': ?visibility,
        'topics': ?topics,
        'issues_enabled': ?issuesEnabled,
        'merge_requests_enabled': ?mergeRequestsEnabled,
        'wiki_enabled': ?wikiEnabled,
        'snippets_enabled': ?snippetsEnabled,
      },
      decoder: _decodeOne,
    );
  }

  Future<Project> archive(Object id) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/archive',
      decoder: _decodeOne,
    );
  }

  Future<Project> unarchive(Object id) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/unarchive',
      decoder: _decodeOne,
    );
  }

  /// CI/CD variables (`/projects/:id/variables`).
  Future<List<CiVariable>> variables(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/variables',
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<CiVariable> createVariable(
    Object id, {
    required String key,
    required String value,
    bool protected_ = false,
    bool masked = false,
    String environmentScope = '*',
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/variables',
      body: {
        'key': key,
        'value': value,
        'protected': protected_,
        'masked': masked,
        'environment_scope': environmentScope,
      },
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<CiVariable> updateVariable(
    Object id,
    String key, {
    required String value,
    bool? protected_,
    bool? masked,
    String? environmentScope,
  }) {
    return _client.put(
      '/projects/${GitLabApiClient.encodeProject(id)}/variables/$key',
      body: {
        'value': value,
        'protected': ?protected_,
        'masked': ?masked,
        'environment_scope': ?environmentScope,
      },
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteVariable(Object id, String key) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/variables/$key',
    );
  }

  Future<List<Project>> groupProjects(Object groupId, {String? search}) {
    return _client
        .getPage(
          '/groups/${Uri.encodeComponent(groupId.toString())}/projects',
          query: {
            'include_subgroups': true,
            'order_by': 'last_activity_at',
            if (search != null && search.isNotEmpty) 'search': search,
          },
          decoder: _decode,
        )
        .then((p) => p.items);
  }

  /// A user's starred projects (profile pages).
  Future<List<Project>> starredBy(int userId) {
    return _client.getList('/users/$userId/starred_projects', decoder: _decode);
  }

  /// A user's own/contributed projects (profile pages).
  Future<List<Project>> byUser(int userId) {
    return _client
        .getPage(
          '/users/$userId/projects',
          query: {'order_by': 'last_activity_at', 'per_page': 50},
          decoder: _decode,
        )
        .then((p) => p.items);
  }

  static Project _decodeOne(Object? json) => _decode(json);

  static Project _decode(Object? json) =>
      Project.fromJson(json! as Map<String, dynamic>);
}
