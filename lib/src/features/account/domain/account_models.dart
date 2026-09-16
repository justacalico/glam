import 'package:equatable/equatable.dart';

/// An SSH key on the account (`/user/keys`).
class SshKey extends Equatable {
  const SshKey({
    required this.id,
    required this.title,
    required this.key,
    this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
  });

  factory SshKey.fromJson(Map<String, dynamic> json) => SshKey(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    key: json['key'] as String? ?? '',
    createdAt: _date(json['created_at']),
    expiresAt: _date(json['expires_at']),
    lastUsedAt: _date(json['last_used_at']),
  );

  final int id;
  final String title;
  final String key;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;

  /// Trailing chunk of the key material for display.
  String get fingerprint {
    final parts = key.trim().split(RegExp(r'\s+'));
    final material = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : key.trim();
    return material.length <= 12
        ? material
        : '…${material.substring(material.length - 12)}';
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id];
}

/// A personal access token (`/personal_access_tokens`). The token
/// string itself is never returned on list, only metadata.
class PersonalAccessToken extends Equatable {
  const PersonalAccessToken({
    required this.id,
    required this.name,
    this.scopes = const [],
    this.active = true,
    this.revoked = false,
    this.expiresAt,
    this.lastUsedAt,
    this.createdAt,
  });

  factory PersonalAccessToken.fromJson(Map<String, dynamic> json) =>
      PersonalAccessToken(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        scopes: json['scopes'] is List
            ? (json['scopes'] as List).whereType<String>().toList()
            : const [],
        active: json['active'] as bool? ?? true,
        revoked: json['revoked'] as bool? ?? false,
        expiresAt: _date(json['expires_at']),
        lastUsedAt: _date(json['last_used_at']),
        createdAt: _date(json['created_at']),
      );

  final int id;
  final String name;
  final List<String> scopes;
  final bool active;
  final bool revoked;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  bool get expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id];
}

/// The user's global notification level (`/notification_settings`).
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.level = 'global',
    this.notificationEmail,
    this.events = const {},
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    const eventKeys = {
      'new_note',
      'new_issue',
      'reopen_issue',
      'close_issue',
      'reassign_issue',
      'issue_due',
      'new_merge_request',
      'push_to_merge_request',
      'reopen_merge_request',
      'close_merge_request',
      'reassign_merge_request',
      'merge_merge_request',
      'failed_pipeline',
      'fixed_pipeline',
      'success_pipeline',
      'moved_project',
      'new_epic',
    };
    return NotificationSettings(
      level: json['level'] as String? ?? 'global',
      notificationEmail: json['notification_email'] as String?,
      events: {
        for (final k in eventKeys)
          if (json[k] is bool) k: json[k] as bool,
      },
    );
  }

  /// `disabled`, `participating`, `watch`, `global`, `custom`.
  final String level;
  final String? notificationEmail;

  /// Per-event toggles, only meaningful when [level] is `custom`.
  final Map<String, bool> events;

  static const levelLabels = {
    'global': 'Global default',
    'watch': 'Watch',
    'participating': 'Participate',
    'on mention': 'On mention',
    'disabled': 'Disabled',
    'custom': 'Custom',
  };

  @override
  List<Object?> get props => [level, notificationEmail];
}
