import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/environments/domain/environment.dart';
import 'package:glam/src/features/environments/domain/feature_flag.dart';

/// `/projects/:id/environments` and `/projects/:id/deployments`.
class EnvironmentsRepository {
  const EnvironmentsRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  Future<Paginated<GlEnvironment>> environments(
    Object projectId, {
    String? states,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/environments',
      query: {'states': ?states},
      page: page,
      perPage: perPage,
      decoder: (j) => GlEnvironment.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<GlEnvironment> environment(Object projectId, int envId) {
    return _client.get(
      '${_p(projectId)}/environments/$envId',
      decoder: (j) => GlEnvironment.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<GlEnvironment> createEnvironment(
    Object projectId, {
    required String name,
    String? externalUrl,
  }) {
    return _client.post(
      '${_p(projectId)}/environments',
      body: {'name': name, 'external_url': ?externalUrl},
      decoder: (j) => GlEnvironment.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<GlEnvironment> stop(Object projectId, int envId) {
    return _client.post(
      '${_p(projectId)}/environments/$envId/stop',
      decoder: (j) => GlEnvironment.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Permanently deletes a stopped environment.
  Future<void> destroy(Object projectId, int envId) {
    return _client.delete('${_p(projectId)}/environments/$envId');
  }

  Future<Paginated<Deployment>> deployments(
    Object projectId, {
    int? environmentId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/deployments',
      query: {
        'environment': ?environmentId?.toString(),
        'status': ?status,
        'order_by': 'id',
        'sort': 'desc',
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Deployment.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Feature flags (`/projects/:id/feature_flags`).
  Future<List<FeatureFlag>> featureFlags(Object projectId) {
    return _client.getAll(
      '${_p(projectId)}/feature_flags',
      decoder: (j) => FeatureFlag.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Toggles a flag on or off for all its scopes.
  Future<FeatureFlag> updateFeatureFlag(
    Object projectId,
    String name, {
    required bool active,
  }) {
    return _client.put(
      '${_p(projectId)}/feature_flags/${Uri.encodeComponent(name)}',
      body: {'active': active},
      decoder: (j) => FeatureFlag.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteFeatureFlag(Object projectId, String name) {
    return _client.delete(
      '${_p(projectId)}/feature_flags/${Uri.encodeComponent(name)}',
    );
  }
}
