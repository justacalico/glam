import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';

/// Package and container registries: `/projects/:id/packages` and
/// `/projects/:id/registry/repositories`.
class RegistryRepository {
  const RegistryRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object id) => '/projects/${GitLabApiClient.encodeProject(id)}';

  Future<Paginated<GitLabPackage>> packages(
    Object projectId, {
    int page = 1,
    String? packageType,
    String? name,
  }) {
    return _client.getPage(
      '${_p(projectId)}/packages',
      query: {
        'package_type': ?packageType,
        'package_name': ?name,
        'order_by': 'created_at',
        'sort': 'desc',
        'include_versionless': true,
      },
      page: page,
      decoder: (j) => GitLabPackage.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<List<PackageFile>> packageFiles(Object projectId, int packageId) {
    return _client.getAll(
      '${_p(projectId)}/packages/$packageId/package_files',
      decoder: (j) => PackageFile.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deletePackage(Object projectId, int packageId) {
    return _client.delete('${_p(projectId)}/packages/$packageId');
  }

  Future<Paginated<ContainerRepo>> containerRepos(
    Object projectId, {
    int page = 1,
  }) {
    return _client.getPage(
      '${_p(projectId)}/registry/repositories',
      query: {'tags_count': true},
      page: page,
      decoder: (j) => ContainerRepo.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Paginated<RegistryTag>> registryTags(
    Object projectId,
    int repoId, {
    int page = 1,
  }) {
    return _client.getPage(
      '${_p(projectId)}/registry/repositories/$repoId/tags',
      page: page,
      decoder: (j) => RegistryTag.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Tag detail (`GET .../tags/:tag`) — the list payload only carries
  /// name/path/location; size, revision and dates live here.
  Future<RegistryTag> registryTag(Object projectId, int repoId, String tag) {
    return _client.get(
      '${_p(projectId)}/registry/repositories/$repoId/tags/'
      '${Uri.encodeComponent(tag)}',
      decoder: (j) => RegistryTag.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Deletes the whole repository (all tags).
  Future<void> deleteContainerRepo(Object projectId, int repoId) {
    return _client.delete('${_p(projectId)}/registry/repositories/$repoId');
  }

  Future<void> deleteTag(Object projectId, int repoId, String tag) {
    return _client.delete(
      '${_p(projectId)}/registry/repositories/$repoId/tags/'
      '${Uri.encodeComponent(tag)}',
    );
  }
}
