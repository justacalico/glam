import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// The stored credentials needed to talk to a GitLab instance.
class StoredSession extends Equatable {
  const StoredSession({required this.baseUrl, required this.token});

  factory StoredSession.fromJson(Map<String, dynamic> json) {
    return StoredSession(
      baseUrl: json['base_url'] as String? ?? 'https://gitlab.com',
      token: json['token'] as String? ?? '',
    );
  }

  final String baseUrl;
  final String token;

  Map<String, dynamic> toJson() => {'base_url': baseUrl, 'token': token};

  @override
  List<Object?> get props => [baseUrl, token];
}

/// A live, validated session: the credentials plus the user they belong
/// to.
class Session extends Equatable {
  const Session({
    required this.baseUrl,
    required this.token,
    required this.user,
  });

  final String baseUrl;
  final String token;
  final GitLabUser user;

  @override
  List<Object?> get props => [baseUrl, token, user];
}
