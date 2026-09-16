import 'package:equatable/equatable.dart';

/// A GitLab user as returned by `/user`, `/users/:id`, and the many
/// embedded `author`/`assignee` objects across the API.
class GitLabUser extends Equatable {
  const GitLabUser({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.state,
    this.webUrl,
    this.bio,
    this.location,
    this.publicEmail,
    this.followers,
    this.following,
    this.createdAt,
    this.statusMessage,
    this.statusEmoji,
    this.isAdmin,
    this.bot,
  });

  factory GitLabUser.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    String? emoji;
    String? message;
    if (status is Map<String, dynamic>) {
      emoji = status['emoji'] as String?;
      message = status['message'] as String?;
    }
    return GitLabUser(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      state: json['state'] as String?,
      webUrl: json['web_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      publicEmail: json['public_email'] as String?,
      followers: json['followers'] as int?,
      following: json['following'] as int?,
      createdAt: _date(json['created_at']),
      statusEmoji: emoji,
      statusMessage: message,
      isAdmin: json['is_admin'] as bool?,
      bot: json['bot'] as bool?,
    );
  }

  final int id;
  final String username;
  final String name;
  final String? avatarUrl;
  final String? state;
  final String? webUrl;
  final String? bio;
  final String? location;
  final String? publicEmail;
  final int? followers;
  final int? following;
  final DateTime? createdAt;
  final String? statusMessage;
  final String? statusEmoji;
  final bool? isAdmin;
  final bool? bot;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'avatar_url': avatarUrl,
    'state': state,
    'web_url': webUrl,
    'bio': bio,
    'location': location,
    'public_email': publicEmail,
    'followers': followers,
    'following': following,
    'created_at': createdAt?.toIso8601String(),
    'is_admin': isAdmin,
    'bot': bot,
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  @override
  List<Object?> get props => [id, username, name, avatarUrl];
}
