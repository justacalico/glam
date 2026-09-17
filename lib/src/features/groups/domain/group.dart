import 'package:equatable/equatable.dart';
import 'package:glam/src/core/models/shared_group.dart';

/// A GitLab group (`/groups`).
class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.path,
    required this.fullPath,
    this.description,
    this.visibility,
    this.avatarUrl,
    this.webUrl,
    this.parentId,
    this.projectCount,
    this.subgroupCount,
    this.createdAt,
    this.sharedWithGroups = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'];
    return Group(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      fullPath: json['full_path'] as String? ?? '',
      description: json['description'] as String?,
      visibility: json['visibility'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      webUrl: json['web_url'] as String?,
      parentId: json['parent_id'] as int?,
      projectCount: stats is Map<String, dynamic>
          ? stats['project_count'] as int?
          : null,
      subgroupCount: stats is Map<String, dynamic>
          ? stats['subgroup_count'] as int?
          : null,
      createdAt: _date(json['created_at']),
      sharedWithGroups: json['shared_with_groups'] is List
          ? (json['shared_with_groups'] as List)
                .whereType<Map<String, dynamic>>()
                .map(SharedGroup.fromJson)
                .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final String path;
  final String fullPath;
  final String? description;
  final String? visibility;
  final String? avatarUrl;
  final String? webUrl;
  final int? parentId;
  final int? projectCount;
  final int? subgroupCount;
  final DateTime? createdAt;
  final List<SharedGroup> sharedWithGroups;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, fullPath];
}

/// A group or project member with an access level.
class Member extends Equatable {
  const Member({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.accessLevel = 0,
    this.state,
    this.expiresAt,
    this.webUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      accessLevel: json['access_level'] as int? ?? 0,
      state: json['state'] as String?,
      expiresAt: _date(json['expires_at']),
      webUrl: json['web_url'] as String?,
    );
  }

  final int id;
  final String username;
  final String name;
  final String? avatarUrl;

  /// 10 Guest, 20 Reporter, 30 Developer, 40 Maintainer, 50 Owner.
  final int accessLevel;
  final String? state;
  final DateTime? expiresAt;
  final String? webUrl;

  String get roleLabel => switch (accessLevel) {
    10 => 'Guest',
    15 => 'Planner',
    20 => 'Reporter',
    30 => 'Developer',
    40 => 'Maintainer',
    50 => 'Owner',
    _ => 'Minimal',
  };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, accessLevel];
}

/// A pending email invitation (`/:scope/:id/invitations`). Distinct from
/// `Member`: the invitee may not have an account yet, so there's no
/// user id — `inviteEmail` is the address, and `username`/`name` fill
/// in once GitLab can link the invite to a user.
class Invitation extends Equatable {
  const Invitation({
    required this.id,
    required this.inviteEmail,
    this.username,
    this.name,
    this.accessLevel = 0,
    this.expiresAt,
    this.createdAt,
    this.createdByName,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    id: json['id'] as int? ?? 0,
    inviteEmail:
        json['invite_email'] as String? ?? json['email'] as String? ?? '',
    username: json['username'] as String?,
    name: json['user_name'] as String? ?? json['name'] as String?,
    accessLevel: json['access_level'] as int? ?? 0,
    expiresAt: Member._date(json['expires_at']),
    createdAt: Member._date(json['created_at']),
    createdByName: json['created_by_name'] as String?,
  );

  final int id;
  final String inviteEmail;
  final String? username;
  final String? name;
  final int accessLevel;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? createdByName;

  @override
  List<Object?> get props => [id, inviteEmail];
}
