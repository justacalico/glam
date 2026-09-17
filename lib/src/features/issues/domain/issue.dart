import 'package:equatable/equatable.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An issue (`/issues`, `/projects/:id/issues`).
class Issue extends Equatable {
  const Issue({
    required this.id,
    required this.iid,
    required this.projectId,
    required this.title,
    required this.state,
    this.description,
    this.author,
    this.assignees = const [],
    this.labels = const [],
    this.milestone,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userNotesCount = 0,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.closedBy,
    this.dueDate,
    this.weight,
    this.confidential = false,
    this.blockingIssuesCount = 0,
    this.taskStatus,
    this.taskCompletion,
    this.webUrl,
    this.references,
    this.subscribed = false,
    this.timeEstimate,
    this.timeSpent,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as int? ?? 0,
      iid: json['iid'] as int? ?? 0,
      projectId: json['project_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? 'opened',
      description: json['description'] as String?,
      author: json['author'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      assignees: json['assignees'] is List
          ? (json['assignees'] as List)
                .whereType<Map<String, dynamic>>()
                .map(GitLabUser.fromJson)
                .toList()
          : const [],
      labels: json['labels'] is List
          ? (json['labels'] as List).map((e) => e.toString()).toList()
          : const [],
      milestone: json['milestone'] is Map<String, dynamic>
          ? Milestone.fromJson(json['milestone'] as Map<String, dynamic>)
          : null,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      userNotesCount: json['user_notes_count'] as int? ?? 0,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      closedAt: _date(json['closed_at']),
      closedBy: json['closed_by'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['closed_by'] as Map<String, dynamic>)
          : null,
      dueDate: _date(json['due_date']),
      // GitLab stores cleared weights as 0 — treat it as unset.
      weight: switch (json['weight']) {
        0 => null,
        final int w => w,
        _ => null,
      },
      confidential: json['confidential'] as bool? ?? false,
      blockingIssuesCount: json['blocking_issues_count'] as int? ?? 0,
      taskStatus: _taskStatus(json['task_completion_status']),
      taskCompletion: json['task_completion_status'] is Map<String, dynamic>
          ? (json['task_completion_status']
                    as Map<String, dynamic>)['completed_count']
                as int?
          : null,
      webUrl: json['web_url'] as String?,
      references: json['references'] is Map<String, dynamic>
          ? (json['references'] as Map<String, dynamic>)['full'] as String?
          : null,
      subscribed: json['subscribed'] as bool? ?? false,
      timeEstimate: json['time_estimate'] as int?,
      timeSpent: json['total_time_spent'] as int?,
    );
  }

  final int id;
  final int iid;
  final int projectId;
  final String title;

  /// `opened`, `closed`, `reopened`.
  final String state;
  final String? description;
  final GitLabUser? author;
  final List<GitLabUser> assignees;
  final List<String> labels;
  final Milestone? milestone;
  final int upvotes;
  final int downvotes;
  final int userNotesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final GitLabUser? closedBy;
  final DateTime? dueDate;
  final int? weight;
  final bool confidential;
  final int blockingIssuesCount;

  /// `2/5` style task progress parsed from task_completion_status.
  final String? taskStatus;

  /// Number of completed tasks for the progress bar.
  final int? taskCompletion;
  final String? webUrl;

  /// `group/project#iid` — handy for lists that span projects.
  final String? references;

  final bool subscribed;

  /// Seconds. `time_estimate` / `total_time_spent` from the API.
  final int? timeEstimate;
  final int? timeSpent;

  bool get isOpen => state == 'opened' || state == 'reopened';

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static String? _taskStatus(Object? v) {
    if (v is! Map<String, dynamic>) {
      return null;
    }
    final count = v['count'] as int?;
    final done = v['completed_count'] as int?;
    return count == null ? null : '${done ?? 0}/$count';
  }

  @override
  List<Object?> get props => [id, iid, projectId, state, subscribed];
}
