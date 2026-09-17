import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A close/reopen entry from `/resource_state_events`, shown inline in
/// an issue or merge request's activity stream.
class ResourceStateEvent extends Equatable {
  const ResourceStateEvent({
    required this.id,
    required this.state,
    this.user,
    this.createdAt,
  });

  factory ResourceStateEvent.fromJson(Map<String, dynamic> json) =>
      ResourceStateEvent(
        id: json['id'] as int? ?? 0,
        state: json['state'] as String? ?? '',
        user: json['user'] is Map<String, dynamic>
            ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
            : null,
      );

  final int id;

  /// `closed` or `reopened`.
  final String state;
  final GitLabUser? user;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, state];
}
