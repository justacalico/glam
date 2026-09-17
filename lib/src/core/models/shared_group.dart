import 'package:equatable/equatable.dart';

/// One entry of a `shared_with_groups` list — shared by projects and
/// groups alike.
class SharedGroup extends Equatable {
  const SharedGroup({
    required this.groupId,
    this.groupName,
    this.groupFullPath,
    this.accessLevel = 0,
    this.expiresAt,
  });

  factory SharedGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['expires_at'];
    return SharedGroup(
      groupId: json['group_id'] as int? ?? 0,
      groupName: json['group_name'] as String?,
      groupFullPath: json['group_full_path'] as String?,
      accessLevel: json['group_access_level'] as int? ?? 0,
      expiresAt: raw is String ? DateTime.tryParse(raw)?.toLocal() : null,
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
