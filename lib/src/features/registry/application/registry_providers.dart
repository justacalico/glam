import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/registry/data/registry_repository.dart';
import 'package:glam/src/features/registry/domain/registry_models.dart';

final registryRepositoryProvider = Provider<RegistryRepository>(
  (ref) => RegistryRepository(ref.watch(apiClientProvider)),
);

typedef PackageFilter = ({Object project, String? type, String? name});

final projectPackagesProvider =
    AsyncNotifierProvider.family<
      ProjectPackagesNotifier,
      PagedListState<GitLabPackage>,
      PackageFilter
    >(ProjectPackagesNotifier.new);

class ProjectPackagesNotifier extends PagedListNotifier<GitLabPackage> {
  ProjectPackagesNotifier(this.filter);

  final PackageFilter filter;

  @override
  Future<Paginated<GitLabPackage>> fetchPage(int page) {
    return ref
        .watch(registryRepositoryProvider)
        .packages(
          filter.project,
          page: page,
          packageType: filter.type,
          name: filter.name,
        );
  }

  Future<void> deletePackage(int packageId) async {
    await ref
        .read(registryRepositoryProvider)
        .deletePackage(filter.project, packageId);
    updateItems((items) => items.where((p) => p.id != packageId).toList());
  }
}

final packageFilesProvider =
    FutureProvider.family<List<PackageFile>, (Object, int)>((ref, loc) {
      final (projectId, packageId) = loc;
      return ref
          .watch(registryRepositoryProvider)
          .packageFiles(projectId, packageId);
    });

final containerReposProvider =
    AsyncNotifierProvider.family<
      ContainerReposNotifier,
      PagedListState<ContainerRepo>,
      Object
    >(ContainerReposNotifier.new);

class ContainerReposNotifier extends PagedListNotifier<ContainerRepo> {
  ContainerReposNotifier(this.projectId);

  final Object projectId;

  @override
  Future<Paginated<ContainerRepo>> fetchPage(int page) {
    return ref
        .watch(registryRepositoryProvider)
        .containerRepos(projectId, page: page);
  }

  Future<void> deleteRepo(int repoId) async {
    await ref
        .read(registryRepositoryProvider)
        .deleteContainerRepo(projectId, repoId);
    updateItems((items) => items.where((r) => r.id != repoId).toList());
  }
}

typedef RegistryLoc = ({Object project, int repoId});

final registryTagsProvider =
    AsyncNotifierProvider.family<
      RegistryTagsNotifier,
      PagedListState<RegistryTag>,
      RegistryLoc
    >(RegistryTagsNotifier.new);

class RegistryTagsNotifier extends PagedListNotifier<RegistryTag> {
  RegistryTagsNotifier(this.loc);

  final RegistryLoc loc;

  @override
  Future<Paginated<RegistryTag>> fetchPage(int page) {
    return ref
        .watch(registryRepositoryProvider)
        .registryTags(loc.project, loc.repoId, page: page);
  }

  Future<void> deleteTag(String tag) async {
    await ref
        .read(registryRepositoryProvider)
        .deleteTag(loc.project, loc.repoId, tag);
    updateItems((items) => items.where((t) => t.name != tag).toList());
    // Tag count (and the repo itself, when its last tag is gone) lives on
    // the repos list behind this screen.
    ref.invalidate(containerReposProvider(loc.project));
  }
}

typedef RegistryTagLoc = ({Object project, int repoId, String tag});

final registryTagDetailProvider =
    FutureProvider.family<RegistryTag, RegistryTagLoc>((ref, loc) {
      return ref
          .watch(registryRepositoryProvider)
          .registryTag(loc.project, loc.repoId, loc.tag);
    });
