import 'package:equatable/equatable.dart';

/// A project deploy token (`/projects/:id/deploy_tokens`): a scoped
/// username/password pair for cloning or pulling packages and images.
class DeployToken extends Equatable {
  const DeployToken({
    required this.id,
    required this.name,
    this.username,
    this.expiresAt,
    this.revoked = false,
    this.scopes = const [],
    this.token,
  });

  factory DeployToken.fromJson(Map<String, dynamic> json) => DeployToken(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    username: json['username'] as String?,
    expiresAt: json['expires_at'] is String
        ? DateTime.tryParse(json['expires_at'] as String)?.toLocal()
        : null,
    revoked: json['revoked'] as bool? ?? false,
    scopes: json['scopes'] is List
        ? (json['scopes'] as List).map((e) => e.toString()).toList()
        : const [],
    token: json['token'] as String?,
  );

  final int id;
  final String name;
  final String? username;
  final DateTime? expiresAt;
  final bool revoked;
  final List<String> scopes;

  /// The secret value. Only present in the create response — never in
  /// list responses, so callers must copy it once and discard it.
  final String? token;

  bool get expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, name];
}
