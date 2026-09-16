import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/ci_variable.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/webhook.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.watch(apiClientProvider)),
);

/// Filter state for the projects list. Updating it re-triggers the
/// paged list below.
final projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(
      ProjectFilterController.new,
    );

class ProjectFilterController extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => const ProjectFilter();

  void update(ProjectFilter filter) => state = filter;

  void setScope(ProjectScope scope) => state = state.copyWith(scope: scope);

  void setSort(ProjectSort sort) => state = state.copyWith(sort: sort);

  void setSearch(String search) => state = state.copyWith(search: search);
}

/// Paginated projects for the current filter.
final projectsListProvider =
    AsyncNotifierProvider<ProjectListNotifier, PagedListState<Project>>(
      ProjectListNotifier.new,
    );

class ProjectListNotifier extends PagedListNotifier<Project> {
  @override
  Future<Paginated<Project>> fetchPage(int page) {
    return ref
        .watch(projectsRepositoryProvider)
        .list(filter: ref.watch(projectFilterProvider), page: page);
  }
}

/// A single project by id or `namespace/path`.
final projectProvider = FutureProvider.family<Project, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).get(id),
);

/// CI/CD variables for a project.
final projectVariablesProvider =
    FutureProvider.family<List<CiVariable>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).variables(id),
    );

/// Project admin surfaces on the settings screen.
final projectHooksProvider = FutureProvider.family<List<Webhook>, Object>(
  (ref, id) => ref.watch(projectsRepositoryProvider).hooks(id),
);

final projectDeployKeysProvider =
    FutureProvider.family<List<DeployKey>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).deployKeys(id),
    );

final projectProtectedBranchesProvider =
    FutureProvider.family<List<ProtectedBranch>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).protectedBranches(id),
    );

/// Mutations for the admin lists; each refetches its list on success.
final projectAdminActionsProvider = Provider<ProjectAdminActions>(
  ProjectAdminActions.new,
);

class ProjectAdminActions {
  const ProjectAdminActions(this._ref);

  final Ref _ref;

  ProjectsRepository get _repo => _ref.read(projectsRepositoryProvider);

  Future<void> addHook(
    Object projectId, {
    required String url,
    String? token,
    Map<String, bool> events = const {},
    bool sslVerify = true,
  }) async {
    await _repo.createHook(
      projectId,
      url: url,
      token: token,
      events: events,
      enableSslVerification: sslVerify,
    );
    _ref.invalidate(projectHooksProvider(projectId));
  }

  Future<void> testHook(Object projectId, int hookId) =>
      _repo.testHook(projectId, hookId);

  Future<void> deleteHook(Object projectId, int hookId) async {
    await _repo.deleteHook(projectId, hookId);
    _ref.invalidate(projectHooksProvider(projectId));
  }

  Future<void> addDeployKey(
    Object projectId, {
    required String title,
    required String key,
    bool canPush = false,
  }) async {
    await _repo.addDeployKey(
      projectId,
      title: title,
      key: key,
      canPush: canPush,
    );
    _ref.invalidate(projectDeployKeysProvider(projectId));
  }

  Future<void> deleteDeployKey(Object projectId, int keyId) async {
    await _repo.deleteDeployKey(projectId, keyId);
    _ref.invalidate(projectDeployKeysProvider(projectId));
  }

  Future<void> protectBranch(
    Object projectId, {
    required String name,
    int pushLevel = 40,
    int mergeLevel = 40,
    bool allowForcePush = false,
  }) async {
    await _repo.protectBranch(
      projectId,
      name: name,
      pushAccessLevel: pushLevel,
      mergeAccessLevel: mergeLevel,
      allowForcePush: allowForcePush,
    );
    _ref.invalidate(projectProtectedBranchesProvider(projectId));
  }

  Future<void> unprotectBranch(Object projectId, String name) async {
    await _repo.unprotectBranch(projectId, name);
    _ref.invalidate(projectProtectedBranchesProvider(projectId));
  }
}

/// Star/unstar actions that keep the list in sync optimistically.
final projectActionsProvider = Provider<ProjectActions>(ProjectActions.new);

class ProjectActions {
  const ProjectActions(this._ref);

  final Ref _ref;

  Future<void> toggleStar(Project project, {required bool starred}) async {
    final repo = _ref.read(projectsRepositoryProvider);
    if (starred) {
      await repo.unstar(project.id);
    } else {
      await repo.star(project.id);
    }
    _ref
      ..invalidate(projectProvider(project.id.toString()))
      ..invalidate(projectsListProvider);
  }
}
