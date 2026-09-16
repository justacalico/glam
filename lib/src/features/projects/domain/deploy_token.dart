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
    this.expired = false,
    this.scopes = const [],
    this.token,
  });

  factory DeployToken.fromJson(Map<String, dynamic> json) {
    // GitLab treats expires_at as a date (valid through that day), so
    // keep the raw UTC value instead of shifting it into local time.
    final expiry = json['expires_at'] is String
        ? DateTime.tryParse(json['expires_at'] as String)
        : null;
    return DeployToken(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String?,
      expiresAt: expiry,
      revoked: json['revoked'] as bool? ?? false,
      expired: json['expired'] as bool? ?? _pastDay(expiry),
      scopes: json['scopes'] is List
          ? (json['scopes'] as List).map((e) => e.toString()).toList()
          : const [],
      token: json['token'] as String?,
    );
  }

  /// Day-granular fallback when the payload lacks `expired`.
  static bool _pastDay(DateTime? expiry) {
    if (expiry == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return DateTime.utc(expiry.year, expiry.month, expiry.day).isBefore(today);
  }

  final int id;
  final String name;
  final String? username;

  /// The expiry day (UTC); valid through this date.
  final DateTime? expiresAt;
  final bool revoked;
  final bool expired;
  final List<String> scopes;

  /// The secret value. Only present in the create response — never in
  /// list responses, so callers must copy it once and discard it.
  final String? token;

  @override
  List<Object?> get props => [id, name];
}
