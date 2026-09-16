import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An emoji reaction on an issue, MR, note, or snippet.
class AwardEmoji extends Equatable {
  const AwardEmoji({required this.id, required this.name, this.user});

  factory AwardEmoji.fromJson(Map<String, dynamic> json) => AwardEmoji(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    user: json['user'] is Map<String, dynamic>
        ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
        : null,
  );

  final int id;

  /// `thumbsup`, `tada`, ... — the emoji's API name.
  final String name;
  final GitLabUser? user;

  /// Common names shown in the picker, mapped to glyphs.
  static const glyphs = {
    'thumbsup': '👍',
    'thumbsdown': '👎',
    'smile': '😄',
    'tada': '🎉',
    'heart': '❤️',
    'rocket': '🚀',
    'eyes': '👀',
    'confused': '😕',
    'ok_hand': '👌',
    'fire': '🔥',
    '100': '💯',
  };

  String get glyph => glyphs[name] ?? name;

  @override
  List<Object?> get props => [id, name];
}
