import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/projects/domain/approval_rule.dart';
import 'package:glam/src/features/projects/domain/project_access_token.dart';
import 'package:glam/src/core/models/ci_variable.dart';
import 'package:glam/src/features/projects/domain/deploy_key.dart';
import 'package:glam/src/features/projects/domain/deploy_token.dart';
import 'package:glam/src/features/projects/domain/namespace.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';
import 'package:glam/src/features/projects/domain/protected_tag.dart';
import 'package:glam/src/features/projects/domain/runner.dart';
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

  /// Forks of this project visible to the user (`/projects/:id/forks`).
  Future<Paginated<Project>> forks(
    Object id, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(id)}/forks',
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// Namespaces the user can create projects in (`/namespaces`).
  Future<List<GitlabNamespace>> namespaces() {
    return _client.getAll(
      '/namespaces',
      decoder: (j) => GitlabNamespace.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Creates a project under [namespaceId] (or the user's own namespace).
  Future<Project> createProject({
    required String name,
    String? path,
    int? namespaceId,
    String? description,
    String? visibility,
    bool initializeWithReadme = false,
  }) {
    return _client.post(
      '/projects',
      body: {
        'name': name,
        'path': ?path,
        'namespace_id': ?namespaceId,
        'description': ?description,
        'visibility': ?visibility,
        if (initializeWithReadme) 'initialize_with_readme': true,
      },
      decoder: _decodeOne,
    );
  }

  /// Deletes a project. On SaaS this schedules delayed deletion.
  Future<void> deleteProject(Object id) {
    return _client.delete('/projects/${GitLabApiClient.encodeProject(id)}');
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
    bool? sharedRunnersEnabled,
    bool? groupRunnersEnabled,
    int? approvalsBeforeMerge,
    String? mergeMethod,
    String? squashOption,
    bool? onlyAllowMergeIfPipelineSucceeds,
    bool? allowMergeOnSkippedPipeline,
    bool? onlyAllowMergeIfAllDiscussionsAreResolved,
    bool? removeSourceBranchAfterMerge,
    String? mergeCommitTemplate,
    String? squashCommitTemplate,
    String? suggestionCommitMessage,
    bool? publicJobs,
    int? buildTimeout,
    String? autoCancelPendingPipelines,
    bool? ciForwardDeploymentEnabled,
    bool? ciSeparatedCaches,
    bool? keepLatestArtifact,
    String? ciConfigPath,
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
        'shared_runners_enabled': ?sharedRunnersEnabled,
        'group_runners_enabled': ?groupRunnersEnabled,
        'approvals_before_merge': ?approvalsBeforeMerge,
        'merge_method': ?mergeMethod,
        'squash_option': ?squashOption,
        'only_allow_merge_if_pipeline_succeeds':
            ?onlyAllowMergeIfPipelineSucceeds,
        'allow_merge_on_skipped_pipeline': ?allowMergeOnSkippedPipeline,
        'only_allow_merge_if_all_discussions_are_resolved':
            ?onlyAllowMergeIfAllDiscussionsAreResolved,
        'remove_source_branch_after_merge': ?removeSourceBranchAfterMerge,
        'merge_commit_template': ?mergeCommitTemplate,
        'squash_commit_template': ?squashCommitTemplate,
        'suggestion_commit_message': ?suggestionCommitMessage,
        'public_jobs': ?publicJobs,
        'build_timeout': ?buildTimeout,
        'auto_cancel_pending_pipelines': ?autoCancelPendingPipelines,
        'ci_forward_deployment_enabled': ?ciForwardDeploymentEnabled,
        'ci_separated_caches': ?ciSeparatedCaches,
        'keep_latest_artifact': ?keepLatestArtifact,
        'ci_config_path': ?ciConfigPath,
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

  /// Moves the project to another namespace. [namespace] takes a
  /// namespace id or a full path.
  Future<Project> transfer(Object id, {required Object namespace}) {
    return _client.put(
      '/projects/${GitLabApiClient.encodeProject(id)}/transfer',
      body: {'namespace': namespace},
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

  /// Protected tag rules (`/projects/:id/protected_tags`).
  Future<List<ProtectedTag>> protectedTags(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_tags',
      decoder: (j) => ProtectedTag.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ProtectedTag> protectTag(
    Object id, {
    required String name,
    int createAccessLevel = 40,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_tags',
      body: {'name': name, 'create_access_level': createAccessLevel},
      decoder: (j) => ProtectedTag.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> unprotectTag(Object id, String name) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/protected_tags/'
      '${Uri.encodeComponent(name)}',
    );
  }

  /// Deploy tokens (`/projects/:id/deploy_tokens`).
  Future<List<DeployToken>> deployTokens(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_tokens',
      decoder: (j) => DeployToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Creates a deploy token. The response carries `token` — the only
  /// time GitLab ever returns the secret, so keep the decoder field.
  Future<DeployToken> createDeployToken(
    Object id, {
    required String name,
    required List<String> scopes,
    String? username,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_tokens',
      body: {
        'name': name,
        'scopes': scopes,
        'username': ?username,
        'expires_at': ?expiresAt?.toIso8601String().substring(0, 10),
      },
      decoder: (j) => DeployToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Revokes (deletes) a deploy token.
  Future<void> deleteDeployToken(Object id, int tokenId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/deploy_tokens/$tokenId',
    );
  }

  /// Runners currently enabled on this project.
  Future<List<Runner>> projectRunners(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/runners',
      decoder: (j) => Runner.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Removes a project-type runner's association with this project.
  /// Shared and group runners can't be unassigned this way — those are
  /// controlled by `shared_runners_enabled` / `group_runners_enabled`.
  Future<void> disableRunner(Object id, int runnerId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/runners/$runnerId',
    );
  }

  /// Merge-request approval rules configured on the project.
  Future<List<ApprovalRule>> approvalRules(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/approval_rules',
      decoder: (j) => ApprovalRule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ApprovalRule> createApprovalRule(
    Object id, {
    required String name,
    required int approvalsRequired,
    List<int> userIds = const [],
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/approval_rules',
      body: {
        'name': name,
        'approvals_required': approvalsRequired,
        'user_ids': userIds,
      },
      decoder: (j) => ApprovalRule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ApprovalRule> updateApprovalRule(
    Object id,
    int ruleId, {
    required String name,
    required int approvalsRequired,
    List<int> userIds = const [],
  }) {
    return _client.put(
      '/projects/${GitLabApiClient.encodeProject(id)}/approval_rules/$ruleId',
      body: {
        'name': name,
        'approvals_required': approvalsRequired,
        'user_ids': userIds,
      },
      decoder: (j) => ApprovalRule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteApprovalRule(Object id, int ruleId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/approval_rules/$ruleId',
    );
  }

  /// Project access tokens; their `token` secret is only in the create
  /// response.
  Future<List<ProjectAccessToken>> accessTokens(Object id) {
    return _client.getAll(
      '/projects/${GitLabApiClient.encodeProject(id)}/access_tokens',
      decoder: (j) => ProjectAccessToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<ProjectAccessToken> createAccessToken(
    Object id, {
    required String name,
    required List<String> scopes,
    required int accessLevel,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/access_tokens',
      body: {
        'name': name,
        'scopes': scopes,
        'access_level': accessLevel,
        if (expiresAt != null)
          'expires_at': expiresAt.toIso8601String().substring(0, 10),
      },
      decoder: (j) => ProjectAccessToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> revokeAccessToken(Object id, int tokenId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/access_tokens/$tokenId',
    );
  }

  /// Shares the project with a group at [accessLevel]. Callers refetch
  /// the project to pick up `shared_with_groups`.
  Future<void> shareGroup(
    Object id, {
    required int groupId,
    required int accessLevel,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '/projects/${GitLabApiClient.encodeProject(id)}/share',
      body: {
        'group_id': groupId,
        'group_access': accessLevel,
        if (expiresAt != null)
          'expires_at': expiresAt.toIso8601String().substring(0, 10),
      },
      decoder: (_) {},
    );
  }

  Future<void> unshareGroup(Object id, int groupId) {
    return _client.delete(
      '/projects/${GitLabApiClient.encodeProject(id)}/share/$groupId',
    );
  }

  static Project _decodeOne(Object? json) => _decode(json);

  static Project _decode(Object? json) =>
      Project.fromJson(json! as Map<String, dynamic>);
}
