import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A GitLab project (`/projects/:id`).
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    required this.path,
    required this.pathWithNamespace,
    this.nameWithNamespace,
    this.description,
    this.defaultBranch,
    this.webUrl,
    this.avatarUrl,
    this.starCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.lastActivityAt,
    this.createdAt,
    this.visibility,
    this.namespaceKind,
    this.namespacePath,
    this.archived = false,
    this.topics = const [],
    this.sshUrl,
    this.httpUrl,
    this.readmeUrl,
    this.owner,
    this.forkedFromId,
    this.importStatus,
    this.emptyRepo = false,
    this.issuesEnabled = true,
    this.mergeRequestsEnabled = true,
    this.wikiEnabled = true,
    this.snippetsEnabled = true,
    this.jobsEnabled = true,
    this.sharedRunnersEnabled = true,
    this.groupRunnersEnabled = true,
    this.approvalsBeforeMerge,
    this.mergeMethod,
    this.squashOption,
    this.onlyAllowMergeIfPipelineSucceeds,
    this.allowMergeOnSkippedPipeline,
    this.onlyAllowMergeIfAllDiscussionsAreResolved,
    this.removeSourceBranchAfterMerge,
    this.mergeCommitTemplate,
    this.squashCommitTemplate,
    this.suggestionCommitMessage,
    this.sharedWithGroups = const [],
    this.publicJobs,
    this.buildTimeout,
    this.autoCancelPendingPipelines,
    this.ciForwardDeploymentEnabled,
    this.ciSeparatedCaches,
    this.keepLatestArtifact,
    this.ciConfigPath,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final namespace = json['namespace'];
    String? nsKind;
    String? nsPath;
    if (namespace is Map<String, dynamic>) {
      nsKind = namespace['kind'] as String?;
      nsPath = namespace['full_path'] as String?;
    }
    final ownerJson = json['owner'];
    final forked = json['forked_from_project'];

    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      pathWithNamespace: json['path_with_namespace'] as String? ?? '',
      nameWithNamespace: json['name_with_namespace'] as String?,
      description: json['description'] as String?,
      defaultBranch: json['default_branch'] as String?,
      webUrl: json['web_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      starCount: json['star_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      lastActivityAt: _date(json['last_activity_at']),
      createdAt: _date(json['created_at']),
      visibility: json['visibility'] as String?,
      namespaceKind: nsKind,
      namespacePath: nsPath,
      archived: json['archived'] as bool? ?? false,
      topics: _strings(json['topics'] ?? json['tag_list']),
      sshUrl: json['ssh_url_to_repo'] as String?,
      httpUrl: json['http_url_to_repo'] as String?,
      readmeUrl: json['readme_url'] as String?,
      owner: ownerJson is Map<String, dynamic>
          ? GitLabUser.fromJson(ownerJson)
          : null,
      forkedFromId: forked is Map<String, dynamic>
          ? forked['id'] as int?
          : null,
      importStatus: json['import_status'] as String?,
      emptyRepo: json['empty_repo'] as bool? ?? false,
      issuesEnabled: json['issues_enabled'] as bool? ?? true,
      mergeRequestsEnabled: json['merge_requests_enabled'] as bool? ?? true,
      wikiEnabled: json['wiki_enabled'] as bool? ?? true,
      snippetsEnabled: json['snippets_enabled'] as bool? ?? true,
      jobsEnabled: json['jobs_enabled'] as bool? ?? true,
      sharedRunnersEnabled: json['shared_runners_enabled'] as bool? ?? true,
      groupRunnersEnabled: json['group_runners_enabled'] as bool? ?? true,
      approvalsBeforeMerge: json['approvals_before_merge'] as int?,
      mergeMethod: json['merge_method'] as String?,
      squashOption: json['squash_option'] as String?,
      onlyAllowMergeIfPipelineSucceeds:
          json['only_allow_merge_if_pipeline_succeeds'] as bool?,
      allowMergeOnSkippedPipeline:
          json['allow_merge_on_skipped_pipeline'] as bool?,
      onlyAllowMergeIfAllDiscussionsAreResolved:
          json['only_allow_merge_if_all_discussions_are_resolved'] as bool?,
      removeSourceBranchAfterMerge:
          json['remove_source_branch_after_merge'] as bool?,
      mergeCommitTemplate: json['merge_commit_template'] as String?,
      squashCommitTemplate: json['squash_commit_template'] as String?,
      suggestionCommitMessage: json['suggestion_commit_message'] as String?,
      sharedWithGroups: _sharedWithGroups(json['shared_with_groups']),
      publicJobs: json['public_jobs'] as bool?,
      buildTimeout: json['build_timeout'] as int?,
      autoCancelPendingPipelines:
          json['auto_cancel_pending_pipelines'] as String?,
      ciForwardDeploymentEnabled:
          json['ci_forward_deployment_enabled'] as bool?,
      ciSeparatedCaches: json['ci_separated_caches'] as bool?,
      keepLatestArtifact: json['keep_latest_artifact'] as bool?,
      ciConfigPath: json['ci_config_path'] as String?,
    );
  }

  final int id;
  final String name;
  final String path;
  final String pathWithNamespace;
  final String? nameWithNamespace;
  final String? description;
  final String? defaultBranch;
  final String? webUrl;
  final String? avatarUrl;
  final int starCount;
  final int forksCount;
  final int openIssuesCount;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;
  final String? visibility;
  final String? namespaceKind;
  final String? namespacePath;
  final bool archived;
  final List<String> topics;
  final String? sshUrl;
  final String? httpUrl;
  final String? readmeUrl;
  final GitLabUser? owner;
  final int? forkedFromId;
  final String? importStatus;
  final bool emptyRepo;
  final bool issuesEnabled;
  final bool mergeRequestsEnabled;
  final bool wikiEnabled;
  final bool snippetsEnabled;
  final bool jobsEnabled;
  final bool sharedRunnersEnabled;
  final bool groupRunnersEnabled;

  /// Required approvals for a merge request, or null when unset.
  final int? approvalsBeforeMerge;

  /// `merge`, `rebase_merge` or `ff`.
  final String? mergeMethod;

  /// `never`, `always`, `default_on` or `default_off`.
  final String? squashOption;
  final bool? onlyAllowMergeIfPipelineSucceeds;
  final bool? allowMergeOnSkippedPipeline;
  final bool? onlyAllowMergeIfAllDiscussionsAreResolved;
  final bool? removeSourceBranchAfterMerge;
  final String? mergeCommitTemplate;
  final String? squashCommitTemplate;
  final String? suggestionCommitMessage;

  /// Groups this project is shared with (`shared_with_groups`).
  final List<SharedGroup> sharedWithGroups;

  /// Pipelines visible to everyone, including logged-out users.
  final bool? publicJobs;

  /// Job timeout in seconds.
  final int? buildTimeout;

  /// `enabled` or `disabled`.
  final String? autoCancelPendingPipelines;
  final bool? ciForwardDeploymentEnabled;
  final bool? ciSeparatedCaches;
  final bool? keepLatestArtifact;

  /// Path to the `.gitlab-ci.yml` file when it isn't the default.
  final String? ciConfigPath;

  /// Display name: `namespace / project`.
  String get displayName => nameWithNamespace ?? pathWithNamespace;

  bool get isGroupNamespace => namespaceKind == 'group';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static List<String> _strings(Object? value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  static List<SharedGroup> _sharedWithGroups(Object? value) => value is List
      ? value
            .whereType<Map<String, dynamic>>()
            .map(SharedGroup.fromJson)
            .toList()
      : const [];

  @override
  List<Object?> get props => [
    id,
    pathWithNamespace,
    name,
    starCount,
    forksCount,
    lastActivityAt,
    archived,
  ];
}

/// One entry of a project's `shared_with_groups` list.
class SharedGroup extends Equatable {
  const SharedGroup({
    required this.groupId,
    this.groupName,
    this.groupFullPath,
    this.accessLevel = 0,
    this.expiresAt,
  });

  factory SharedGroup.fromJson(Map<String, dynamic> json) {
    return SharedGroup(
      groupId: json['group_id'] as int? ?? 0,
      groupName: json['group_name'] as String?,
      groupFullPath: json['group_full_path'] as String?,
      accessLevel: json['group_access_level'] as int? ?? 0,
      expiresAt: Project._date(json['expires_at']),
    );
  }

  final int groupId;
  final String? groupName;
  final String? groupFullPath;
  final int accessLevel;
  final DateTime? expiresAt;

  String get displayName => groupFullPath ?? groupName ?? 'group $groupId';

  String get roleLabel => switch (accessLevel) {
    10 => 'Guest',
    15 => 'Planner',
    20 => 'Reporter',
    30 => 'Developer',
    40 => 'Maintainer',
    50 => 'Owner',
    _ => 'level $accessLevel',
  };

  @override
  List<Object?> get props => [groupId];
}
