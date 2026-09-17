import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An add/remove label entry from `/resource_label_events`, shown
/// inline in an issue or merge request's activity stream.
class ResourceLabelEvent extends Equatable {
  const ResourceLabelEvent({
    required this.id,
    required this.action,
    this.labelName = '',
    this.labelColor,
    this.user,
    this.createdAt,
  });

  factory ResourceLabelEvent.fromJson(Map<String, dynamic> json) =>
      ResourceLabelEvent(
        id: json['id'] as int? ?? 0,
        action: json['action'] as String? ?? 'add',
        labelName: json['label'] is Map<String, dynamic>
            ? json['label']['name'] as String? ?? ''
            : '',
        labelColor: json['label'] is Map<String, dynamic>
            ? json['label']['color'] as String?
            : null,
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
  final String labelName;
  final String? labelColor;
  final GitLabUser? user;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, action];
}
