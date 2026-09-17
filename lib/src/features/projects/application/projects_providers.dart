import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/approval_rule.dart';
import 'package:glam/src/features/projects/domain/ci_variable.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/deploy_token.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_access_token.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/protected_tag.dart';
import 'package:glam/src/features/projects/domain/runner.dart';
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

final projectProtectedTagsProvider =
    FutureProvider.family<List<ProtectedTag>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).protectedTags(id),
    );

final projectDeployTokensProvider =
    FutureProvider.family<List<DeployToken>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).deployTokens(id),
    );

/// Runners available to this project: its own runners plus group and
/// shared runners the project allows.
final projectRunnersProvider = FutureProvider.family<List<Runner>, Object>(
  (ref, id) => ref.watch(projectsRepositoryProvider).projectRunners(id),
);

/// Merge-request approval rules configured on the project. Empty on
/// instances where the endpoint is absent or feature-gated.
final projectApprovalRulesProvider =
    FutureProvider.family<List<ApprovalRule>, Object>((ref, id) async {
      try {
        return await ref.watch(projectsRepositoryProvider).approvalRules(id);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          return const [];
        }
        rethrow;
      }
    });

/// Project access tokens; secrets are only in the create response.
final projectAccessTokensProvider =
    FutureProvider.family<List<ProjectAccessToken>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).accessTokens(id),
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

  Future<void> protectTag(
    Object projectId, {
    required String name,
    int createLevel = 40,
  }) async {
    await _repo.protectTag(
      projectId,
      name: name,
      createAccessLevel: createLevel,
    );
    _ref.invalidate(projectProtectedTagsProvider(projectId));
  }

  Future<void> unprotectTag(Object projectId, String name) async {
    await _repo.unprotectTag(projectId, name);
    _ref.invalidate(projectProtectedTagsProvider(projectId));
  }

  /// Returns the created token — the only time its secret is readable.
  Future<DeployToken> addDeployToken(
    Object projectId, {
    required String name,
    required List<String> scopes,
    String? username,
    DateTime? expiresAt,
  }) async {
    final token = await _repo.createDeployToken(
      projectId,
      name: name,
      scopes: scopes,
      username: username,
      expiresAt: expiresAt,
    );
    _ref.invalidate(projectDeployTokensProvider(projectId));
    return token;
  }

  Future<void> deleteDeployToken(Object projectId, int tokenId) async {
    await _repo.deleteDeployToken(projectId, tokenId);
    _ref.invalidate(projectDeployTokensProvider(projectId));
  }

  Future<void> disableRunner(Object projectId, int runnerId) async {
    await _repo.disableRunner(projectId, runnerId);
    _ref.invalidate(projectRunnersProvider(projectId));
  }

  /// Creates or updates a rule; `ruleId` selects update over create.
  Future<void> saveApprovalRule(
    Object projectId, {
    int? ruleId,
    required String name,
    required int approvalsRequired,
    List<int> userIds = const [],
  }) async {
    if (ruleId == null) {
      await _repo.createApprovalRule(
        projectId,
        name: name,
        approvalsRequired: approvalsRequired,
        userIds: userIds,
      );
    } else {
      await _repo.updateApprovalRule(
        projectId,
        ruleId,
        name: name,
        approvalsRequired: approvalsRequired,
        userIds: userIds,
      );
    }
    _ref.invalidate(projectApprovalRulesProvider(projectId));
  }

  Future<void> deleteApprovalRule(Object projectId, int ruleId) async {
    await _repo.deleteApprovalRule(projectId, ruleId);
    _ref.invalidate(projectApprovalRulesProvider(projectId));
  }

  /// The project-wide `approvals_before_merge` setting.
  Future<void> setApprovalsBeforeMerge(
    Project project,
    int approvalsBeforeMerge,
  ) async {
    await _repo.updateProject(
      project.id,
      approvalsBeforeMerge: approvalsBeforeMerge,
    );
    _ref.invalidate(projectProvider(project.id.toString()));
  }

  /// Returns the created token — the only time its secret is readable.
  Future<ProjectAccessToken> addAccessToken(
    Object projectId, {
    required String name,
    required List<String> scopes,
    required int accessLevel,
    DateTime? expiresAt,
  }) async {
    final token = await _repo.createAccessToken(
      projectId,
      name: name,
      scopes: scopes,
      accessLevel: accessLevel,
      expiresAt: expiresAt,
    );
    _ref.invalidate(projectAccessTokensProvider(projectId));
    return token;
  }

  Future<void> revokeAccessToken(Object projectId, int tokenId) async {
    await _repo.revokeAccessToken(projectId, tokenId);
    _ref.invalidate(projectAccessTokensProvider(projectId));
  }

  Future<void> shareProject(
    Project project, {
    required int groupId,
    required int accessLevel,
    DateTime? expiresAt,
  }) async {
    await _repo.shareGroup(
      project.id,
      groupId: groupId,
      accessLevel: accessLevel,
      expiresAt: expiresAt,
    );
    _ref.invalidate(projectProvider(project.id.toString()));
  }

  Future<void> unshareProject(Project project, int groupId) async {
    await _repo.unshareGroup(project.id, groupId);
    _ref.invalidate(projectProvider(project.id.toString()));
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
