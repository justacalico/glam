import 'package:equatable/equatable.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A merge request (`/merge_requests`, `/projects/:id/merge_requests`).
class MergeRequest extends Equatable {
  const MergeRequest({
    required this.id,
    required this.iid,
    required this.projectId,
    required this.title,
    required this.state,
    required this.sourceBranch,
    required this.targetBranch,
    this.description,
    this.author,
    this.assignees = const [],
    this.reviewers = const [],
    this.labels = const [],
    this.milestone,
    this.draft = false,
    this.sha,
    this.mergeStatus,
    this.detailedMergeStatus,
    this.hasConflicts = false,
    this.blockingDiscussionsResolved = true,
    this.userNotesCount = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.createdAt,
    this.updatedAt,
    this.mergedAt,
    this.closedAt,
    this.mergedBy,
    this.mergeCommitSha,
    this.squashCommitSha,
    this.diffRefs,
    this.headPipeline,
    this.webUrl,
    this.references,
    this.squash = false,
    this.mergeWhenPipelineSucceeds = false,
    this.sourceProjectId,
    this.targetProjectId,
    this.subscribed = false,
  });

  factory MergeRequest.fromJson(Map<String, dynamic> json) {
    return MergeRequest(
      id: json['id'] as int? ?? 0,
      iid: json['iid'] as int? ?? 0,
      projectId: json['project_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? 'opened',
      sourceBranch: json['source_branch'] as String? ?? '',
      targetBranch: json['target_branch'] as String? ?? '',
      description: json['description'] as String?,
      author: _user(json['author']),
      assignees: _users(json['assignees']),
      reviewers: _users(json['reviewers']),
      labels: json['labels'] is List
          ? (json['labels'] as List).map((e) => e.toString()).toList()
          : const [],
      milestone: json['milestone'] is Map<String, dynamic>
          ? Milestone.fromJson(json['milestone'] as Map<String, dynamic>)
          : null,
      draft:
          json['draft'] as bool? ??
          (json['work_in_progress'] as bool? ?? false),
      sha: json['sha'] as String?,
      mergeStatus: json['merge_status'] as String?,
      detailedMergeStatus: json['detailed_merge_status'] as String?,
      hasConflicts: json['has_conflicts'] as bool? ?? false,
      blockingDiscussionsResolved:
          json['blocking_discussions_resolved'] as bool? ?? true,
      userNotesCount: json['user_notes_count'] as int? ?? 0,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      mergedAt: _date(json['merged_at']),
      closedAt: _date(json['closed_at']),
      mergedBy: _user(json['merged_by'] ?? json['merge_user']),
      mergeCommitSha: json['merge_commit_sha'] as String?,
      squashCommitSha: json['squash_commit_sha'] as String?,
      diffRefs: json['diff_refs'] is Map<String, dynamic>
          ? DiffRefs.fromJson(json['diff_refs'] as Map<String, dynamic>)
          : null,
      headPipeline: json['head_pipeline'] is Map<String, dynamic>
          ? PipelineStatus.fromJson(
              json['head_pipeline'] as Map<String, dynamic>,
            )
          : null,
      webUrl: json['web_url'] as String?,
      references: json['references'] is Map<String, dynamic>
          ? (json['references'] as Map<String, dynamic>)['full'] as String?
          : null,
      squash: json['squash'] as bool? ?? false,
      mergeWhenPipelineSucceeds:
          json['merge_when_pipeline_succeeds'] as bool? ?? false,
      sourceProjectId: json['source_project_id'] as int?,
      targetProjectId: json['target_project_id'] as int?,
      subscribed: json['subscribed'] as bool? ?? false,
    );
  }

  final int id;
  final int iid;
  final int projectId;
  final String title;

  /// `opened`, `merged`, `closed`, `locked`.
  final String state;
  final String sourceBranch;
  final String targetBranch;
  final String? description;
  final GitLabUser? author;
  final List<GitLabUser> assignees;
  final List<GitLabUser> reviewers;
  final List<String> labels;
  final Milestone? milestone;
  final bool draft;
  final String? sha;
  final String? mergeStatus;
  final String? detailedMergeStatus;
  final bool hasConflicts;
  final bool blockingDiscussionsResolved;
  final int userNotesCount;
  final int upvotes;
  final int downvotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? mergedAt;
  final DateTime? closedAt;
  final GitLabUser? mergedBy;
  final String? mergeCommitSha;
  final String? squashCommitSha;
  final DiffRefs? diffRefs;
  final PipelineStatus? headPipeline;
  final String? webUrl;
  final String? references;
  final bool squash;
  final bool mergeWhenPipelineSucceeds;
  final int? sourceProjectId;
  final int? targetProjectId;
  final bool subscribed;

  bool get isOpen => state == 'opened';
  bool get isMerged => state == 'merged';

  /// The user-facing merge readiness hint.
  String get mergeabilityLabel => switch (detailedMergeStatus) {
    'mergeable' => 'Ready to merge',
    'broken_status' || 'not_open' => 'Cannot merge',
    'conflict' => 'Has conflicts',
    'need_rebase' => 'Needs rebase',
    'ci_must_pass' || 'ci_still_running' => 'Pipeline must pass',
    'discussions_not_resolved' => 'Unresolved discussions',
    'draft_status' => 'Draft',
    'not_approved' => 'Needs approval',
    'blocked_status' => 'Blocked',
    'external_status_checks' => 'Waiting on status checks',
    'checking' || 'unchecked' => 'Checking…',
    _ => mergeStatus == 'can_be_merged' ? 'Ready to merge' : 'Unknown',
  };

  static GitLabUser? _user(Object? v) =>
      v is Map<String, dynamic> ? GitLabUser.fromJson(v) : null;

  static List<GitLabUser> _users(Object? v) => v is List
      ? v.whereType<Map<String, dynamic>>().map(GitLabUser.fromJson).toList()
      : const [];

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, iid, projectId, state];
}

/// base/head/start SHAs used to fetch the MR diff.
class DiffRefs extends Equatable {
  const DiffRefs({this.baseSha, this.headSha, this.startSha});

  factory DiffRefs.fromJson(Map<String, dynamic> json) {
    return DiffRefs(
      baseSha: json['base_sha'] as String?,
      headSha: json['head_sha'] as String?,
      startSha: json['start_sha'] as String?,
    );
  }

  final String? baseSha;
  final String? headSha;
  final String? startSha;

  @override
  List<Object?> get props => [baseSha, headSha, startSha];
}

/// The pipeline attached to the MR head — status only.
class PipelineStatus extends Equatable {
  const PipelineStatus({this.id, this.status, this.webUrl});

  factory PipelineStatus.fromJson(Map<String, dynamic> json) {
    return PipelineStatus(
      id: json['id'] as int?,
      status: json['status'] as String?,
      webUrl: json['web_url'] as String?,
    );
  }

  final int? id;
  final String? status;
  final String? webUrl;

  @override
  List<Object?> get props => [id, status];
}

/// Approval state from `/approvals` (separate endpoint).
class ApprovalState extends Equatable {
  const ApprovalState({
    this.approved = false,
    this.approvalsRequired = 0,
    this.approvalsLeft = 0,
    this.approvedBy = const [],
    this.userHasApproved,
    this.userCanApprove,
  });

  factory ApprovalState.fromJson(Map<String, dynamic> json) {
    final approvedBy = json['approved_by'];
    return ApprovalState(
      approved: json['approved'] as bool? ?? false,
      approvalsRequired: json['approvals_required'] as int? ?? 0,
      approvalsLeft: json['approvals_left'] as int? ?? 0,
      approvedBy: approvedBy is List
          ? approvedBy
                .whereType<Map<String, dynamic>>()
                .map(_userOf)
                .whereType<GitLabUser>()
                .toList()
          : const [],
      userHasApproved: json['user_has_approved'] as bool?,
      userCanApprove: json['user_can_approve'] as bool?,
    );
  }

  final bool approved;
  final int approvalsRequired;
  final int approvalsLeft;
  final List<GitLabUser> approvedBy;

  /// Whether the current user already approved. Null on API versions
  /// that don't return it — fall back to scanning [approvedBy].
  final bool? userHasApproved;

  /// Whether the current user is allowed to approve (false for the
  /// author when author-approval is disabled, for example).
  final bool? userCanApprove;

  static GitLabUser? _userOf(Map<String, dynamic> e) {
    final u = e['user'];
    return u is Map<String, dynamic> ? GitLabUser.fromJson(u) : null;
  }

  @override
  List<Object?> get props => [approved, approvalsLeft];
}

/// One entry from `/merge_requests/:iid/versions` — the diff state at
/// each push, so reviewers can look at changes since an earlier head.
class MrVersion extends Equatable {
  const MrVersion({
    required this.id,
    required this.headCommitSha,
    required this.baseCommitSha,
    required this.startCommitSha,
    this.createdAt,
    this.state,
    this.realSize = 0,
  });

  factory MrVersion.fromJson(Map<String, dynamic> json) {
    return MrVersion(
      id: json['id'] as int? ?? 0,
      headCommitSha: json['head_commit_sha'] as String? ?? '',
      baseCommitSha: json['base_commit_sha'] as String? ?? '',
      startCommitSha: json['start_commit_sha'] as String? ?? '',
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      state: json['state'] as String?,
      realSize: json['real_size'] is num
          ? (json['real_size'] as num).toInt()
          : int.tryParse('${json['real_size']}') ?? 0,
    );
  }

  final int id;
  final String headCommitSha;
  final String baseCommitSha;
  final String startCommitSha;
  final DateTime? createdAt;
  final String? state;
  final int realSize;

  String get shortSha =>
      headCommitSha.length > 8 ? headCommitSha.substring(0, 8) : headCommitSha;

  @override
  List<Object?> get props => [id, headCommitSha];
}

/// Removes a leading `Draft:`/`WIP:` marker, including GitLab's
/// bracketed spellings (`[Draft]`, `(wip)`). GitLab accepts stacked
/// prefixes, so the marker is stripped repeatedly.
String stripDraftPrefix(String title) {
  final prefix = RegExp(
    r'^\s*(\[(draft|wip)\]|\((draft|wip)\)|(draft|wip)\s*[:-])\s*',
    caseSensitive: false,
  );
  var t = title;
  while (prefix.hasMatch(t)) {
    t = t.replaceFirst(prefix, '');
  }
  return t;
}
