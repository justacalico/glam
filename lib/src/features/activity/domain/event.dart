import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An activity feed entry (`/events`, `/projects/:id/events`).
class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.actionName,
    this.targetType,
    this.targetTitle,
    this.targetIid,
    this.author,
    this.projectId,
    this.projectPath,
    this.pushData,
    this.note,
    this.createdAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    final push = json['push_data'];
    final note = json['note'];
    return ActivityEvent(
      id: json['id'] as int? ?? 0,
      actionName: json['action_name'] as String? ?? '',
      targetType: json['target_type'] as String?,
      targetTitle: json['target_title'] as String?,
      targetIid: json['target_iid'] as int?,
      author: json['author'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      projectId: project is Map<String, dynamic> ? project['id'] as int? : null,
      projectPath: project is Map<String, dynamic>
          ? project['path_with_namespace'] as String?
          : null,
      pushData: push is Map<String, dynamic> ? PushData.fromJson(push) : null,
      note: note is Map<String, dynamic> ? note['body'] as String? : null,
      createdAt: _date(json['created_at']),
    );
  }

  final int id;

  /// `pushed to`, `created`, `closed`, `merged`, `commented on`, ...
  final String actionName;
  final String? targetType;
  final String? targetTitle;
  final int? targetIid;
  final GitLabUser? author;
  final int? projectId;
  final String? projectPath;
  final PushData? pushData;

  /// Comment body when the event is a `commented on` action.
  final String? note;
  final DateTime? createdAt;

  /// `!9`-style target reference.
  String get reference {
    final iid = targetIid;
    if (iid == null) {
      return '';
    }
    return switch (targetType) {
      'Issue' => '#$iid',
      'MergeRequest' => '!$iid',
      _ => '',
    };
  }

  /// Route to the target, when it maps to a screen we have.
  String? get route {
    final pid = projectId;
    final iid = targetIid;
    if (pid == null || iid == null) {
      return null;
    }
    return switch (targetType) {
      'Issue' => '/projects/$pid/issues/$iid',
      'MergeRequest' => '/projects/$pid/mrs/$iid',
      _ => null,
    };
  }

  /// One-line summary, e.g. `pushed to main` or `commented on !9`.
  String describe() {
    final parts = [
      if (author != null) author!.name,
      actionName,
      if (pushData?.ref != null) pushData!.ref!,
      if (targetTitle?.isNotEmpty ?? false) targetTitle!,
      if (reference.isNotEmpty) reference,
      if (projectPath != null) 'in $projectPath',
    ];
    return parts.join(' ');
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id];
}

/// Extra fields on `pushed` events: branch, commit count, head sha.
class PushData extends Equatable {
  const PushData({this.ref, this.commitCount, this.commitTo, this.action});

  factory PushData.fromJson(Map<String, dynamic> json) => PushData(
    ref: json['ref'] as String?,
    commitCount: json['commit_count'] as int?,
    commitTo: json['commit_to'] as String?,
    action: json['action'] as String?,
  );

  final String? ref;
  final int? commitCount;
  final String? commitTo;
  final String? action;

  @override
  List<Object?> get props => [ref, commitCount, commitTo];
}
