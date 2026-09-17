import 'package:equatable/equatable.dart';

/// A named set of user IDs targeted by feature flag strategies
/// (`/projects/:id/feature_flags_user_lists`).
class FeatureFlagUserList extends Equatable {
  const FeatureFlagUserList({
    required this.id,
    required this.iid,
    required this.name,
    this.userXids = '',
    this.createdAt,
  });

  factory FeatureFlagUserList.fromJson(Map<String, dynamic> json) =>
      FeatureFlagUserList(
        id: json['id'] as int? ?? 0,
        iid: json['iid'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        userXids: json['user_xids'] as String? ?? '',
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
            : null,
      );

  final int id;

  /// Project-scoped id used by the update/delete endpoints.
  final int iid;
  final String name;

  /// Comma-separated user IDs (not usernames), as the API stores them.
  final String userXids;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, iid, name, userXids];
}
