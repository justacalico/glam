import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/projects/domain/ci_variable.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/webhook.dart';

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

  /// Webhooks (`/projects/:id/hooks`).
  Future<List<Webhook>> hooks(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/hooks',
      decoder: (j) => Webhook.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Webhook> createHook(
    Object id, {
    required String url,
    String? token,
    Map<String, bool> events = const {},
    bool enableSslVerification = true,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/hooks',
      body: {
        'url': url,
        'token': ?token,
        ...events,
        'enable_ssl_verification': enableSslVerification,
      },
      decoder: (j) => Webhook.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Fires a test event (`test/:trigger` accepts every event type;
  /// the UI sends `push_events`).
  Future<void> testHook(Object id, int hookId) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/hooks/$hookId/'
      'test/push_events',
      decoder: (j) => j,
    );
  }

  Future<void> deleteHook(Object id, int hookId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/hooks/$hookId',
    );
  }

  /// Deploy keys enabled on the project (`/projects/:id/deploy_keys`).
  Future<List<DeployKey>> deployKeys(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_keys',
      decoder: (j) => DeployKey.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<DeployKey> addDeployKey(
    Object id, {
    required String title,
    required String key,
    bool canPush = false,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_keys',
      body: {'title': title, 'key': key, 'can_push': canPush},
      decoder: (j) => DeployKey.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteDeployKey(Object id, int keyId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_keys/$keyId',
    );
  }

  /// Protected branch rules (`/projects/:id/protected_branches`).
  Future<List<ProtectedBranch>> protectedBranches(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_branches',
      decoder: (j) => ProtectedBranch.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ProtectedBranch> protectBranch(
    Object id, {
    required String name,
    int pushAccessLevel = 40,
    int mergeAccessLevel = 40,
    bool allowForcePush = false,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_branches',
      body: {
        'name': name,
        'push_access_level': pushAccessLevel,
        'merge_access_level': mergeAccessLevel,
        'allow_force_push': allowForcePush,
      },
      decoder: (j) => ProtectedBranch.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> unprotectBranch(Object id, String name) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_branches/'
      '${Uri.encodeComponent(name)}',
    );
  }

  static Project _decodeOne(Object? json) => _decode(json);

  static Project _decode(Object? json) =>
      Project.fromJson(json! as Map<String, dynamic>);
}
