import 'package:equatable/equatable.dart';

/// A protected tag rule (`/projects/:id/protected_tags`). Tags matching
/// `name` (a wildcard like `v*`) can only be created by the listed
/// access levels.
class ProtectedTag extends Equatable {
  const ProtectedTag({
    required this.name,
    this.createLevels = const [],
    this.createRules = const [],
  });

  factory ProtectedTag.fromJson(Map<String, dynamic> json) {
    final levels = <int>[];
    final rules = <ProtectedTagRule>[];
    if (json['create_access_levels'] is List) {
      for (final l in json['create_access_levels'] as List) {
        if (l is! Map<String, dynamic>) {
          continue;
        }
        final level = l['access_level'] as int?;
        if (level != null) {
          levels.add(level);
        }
        rules.add((
          level: level,
          description: l['access_level_description'] as String?,
        ));
      }
    }
    return ProtectedTag(
      name: json['name'] as String? ?? '',
      createLevels: levels,
      createRules: rules,
    );
  }

  final String name;

  /// Access levels allowed to create matching tags (0/30/40/60).
  final List<int> createLevels;

  /// Raw create rules — the UI resolves levels to localized labels.
  final List<ProtectedTagRule> createRules;

  bool get isWildcard => name.contains('*');

  @override
  List<Object?> get props => [name];
}

/// One create rule on a protected tag: either an access level or a
/// group/user-scoped entry described by [description].
typedef ProtectedTagRule = ({int? level, String? description});
