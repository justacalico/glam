import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A GitLab to-do item (`/todos`). The `target` is the issue, merge
/// request, or other object the item points at.
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.actionName,
    required this.targetType,
    required this.state,
    this.target,
    this.author,
    this.projectId,
    this.projectPath,
    this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    final target = json['target'];
    final project = json['project'];
    return Todo(
      id: json['id'] as int? ?? 0,
      actionName: json['action_name'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      state: json['state'] as String? ?? 'pending',
      target: target is Map<String, dynamic> ? target : null,
      author: json['author'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      projectId: project is Map<String, dynamic> ? project['id'] as int? : null,
      projectPath: project is Map<String, dynamic>
          ? project['path_with_namespace'] as String?
          : null,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final int id;

  /// `mentioned`, `assigned`, `approval_required`, `build_failed`, ...
  final String actionName;

  /// `Issue`, `MergeRequest`, `Commit`, `Epic`, ...
  final String targetType;
  final String state;
  final Map<String, dynamic>? target;
  final GitLabUser? author;
  final int? projectId;
  final String? projectPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `!42`-style reference for the target inside its project.
  String get reference {
    final t = target;
    if (t == null) {
      return '';
    }
    final iid = t['iid'];
    return switch (targetType) {
      'Issue' => '#$iid',
      'MergeRequest' => '!$iid',
      _ => targetType,
    };
  }

  /// Human label for [actionName].
  String get actionLabel => switch (actionName) {
    'assigned' => 'assigned you',
    'mentioned' => 'mentioned you',
    'approval_required' => 'needs your approval',
    'review_requested' => 'requested your review',
    'build_failed' => 'build failed',
    'directly_addressed' => 'addressed you',
    _ => actionName.replaceAll('_', ' '),
  };

  String get targetTitle => target?['title'] as String? ?? reference;

  /// Route path to open the target, or null when we can't link it.
  String? get route {
    final t = target;
    final pid = projectId;
    if (t == null || pid == null) {
      return null;
    }
    final iid = t['iid'];
    if (iid is! int) {
      return null;
    }
    return switch (targetType) {
      'Issue' => '/projects/$pid/issues/$iid',
      'MergeRequest' => '/projects/$pid/mrs/$iid',
      _ => null,
    };
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, state];
}
