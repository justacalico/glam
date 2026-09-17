import 'package:equatable/equatable.dart';

/// A project access token (`/projects/:id/access_tokens`): a bot
/// credential scoped to this project. `token` is returned only on
/// creation.
class ProjectAccessToken extends Equatable {
  const ProjectAccessToken({
    required this.id,
    required this.name,
    this.userId,
    this.scopes = const [],
    this.accessLevel = 0,
    this.expiresAt,
    this.active = false,
    this.revoked = false,
    this.lastUsedAt,
    this.token,
  });

  factory ProjectAccessToken.fromJson(Map<String, dynamic> json) {
    final scopes = json['scopes'];
    return ProjectAccessToken(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      userId: json['user_id'] as int?,
      scopes: scopes is List ? scopes.whereType<String>().toList() : const [],
      accessLevel: json['access_level'] as int? ?? 0,
      expiresAt: _date(json['expires_at']),
      active: json['active'] as bool? ?? false,
      revoked: json['revoked'] as bool? ?? false,
      lastUsedAt: _date(json['last_used_at']),
      token: json['token'] as String?,
    );
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  final int id;
  final String name;
  final int? userId;
  final List<String> scopes;

  /// 10 Guest, 20 Reporter, 30 Developer, 40 Maintainer, 50 Owner.
  final int accessLevel;
  final DateTime? expiresAt;
  final bool active;
  final bool revoked;
  final DateTime? lastUsedAt;

  /// Present only in the create response.
  final String? token;

  String get roleLabel => switch (accessLevel) {
    10 => 'Guest',
    15 => 'Planner',
    20 => 'Reporter',
    30 => 'Developer',
    40 => 'Maintainer',
    50 => 'Owner',
    _ => 'level $accessLevel',
  };

  bool get expired =>
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  @override
  List<Object?> get props => [id, name];
}
