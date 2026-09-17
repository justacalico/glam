import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An add/remove milestone entry from `/resource_milestone_events`,
/// shown inline in an issue or merge request's activity stream.
class ResourceMilestoneEvent extends Equatable {
  const ResourceMilestoneEvent({
    required this.id,
    required this.action,
    this.milestoneTitle = '',
    this.user,
    this.createdAt,
  });

  factory ResourceMilestoneEvent.fromJson(Map<String, dynamic> json) =>
      ResourceMilestoneEvent(
        id: json['id'] as int? ?? 0,
        action: json['action'] as String? ?? 'add',
        milestoneTitle: json['milestone'] is Map<String, dynamic>
            ? json['milestone']['title'] as String? ?? ''
            : '',
        user: json['user'] is Map<String, dynamic>
            ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
            : null,
      );

  final int id;

  /// `add` or `remove`.
  final String action;
  final String milestoneTitle;
  final GitLabUser? user;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, action];
}
