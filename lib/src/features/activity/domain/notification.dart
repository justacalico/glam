import 'package:equatable/equatable.dart';

/// A GitLab notification (`/notifications`).
class GlamNotification extends Equatable {
  const GlamNotification({
    required this.id,
    required this.reason,
    this.targetType,
    this.targetTitle,
    this.targetIid,
    this.projectId,
    this.projectPath,
    this.createdAt,
    this.updatedAt,
  });

  factory GlamNotification.fromJson(Map<String, dynamic> json) {
    final target = json['target'];
    final project = json['project'];
    return GlamNotification(
      id: json['id'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      targetType: target is Map<String, dynamic>
          ? target['type'] as String?
          : json['target_type'] as String?,
      targetTitle: target is Map<String, dynamic>
          ? target['title'] as String?
          : null,
      targetIid: target is Map<String, dynamic> ? target['iid'] as int? : null,
      projectId: project is Map<String, dynamic> ? project['id'] as int? : null,
      projectPath: project is Map<String, dynamic>
          ? project['path_with_namespace'] as String?
          : null,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final int id;

  /// `assigned`, `mentioned`, `review_requested`, `build_failed`, ...
  final String reason;
  final String? targetType;
  final String? targetTitle;
  final int? targetIid;
  final int? projectId;
  final String? projectPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get reasonLabel => switch (reason) {
    'assigned' => 'Assigned to you',
    'mentioned' => 'Mentioned you',
    'review_requested' => 'Review requested',
    'approval_required' => 'Approval required',
    'build_failed' => 'Build failed',
    'marked' => 'Marked',
    'subscribed' => 'Subscribed',
    _ => reason.replaceAll('_', ' '),
  };

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

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id];
}
