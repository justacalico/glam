import 'package:equatable/equatable.dart';
import 'package:glam/src/features/projects/domain/protected_branch.dart';

/// A protected tag rule (`/projects/:id/protected_tags`). Tags matching
/// `name` (a wildcard like `v*`) can only be created by the listed
/// access levels.
class ProtectedTag extends Equatable {
  const ProtectedTag({
    required this.name,
    this.createLevels = const [],
    this.createLabels = const [],
  });

  factory ProtectedTag.fromJson(Map<String, dynamic> json) {
    final levels = <int>[];
    final labels = <String>[];
    if (json['create_access_levels'] is List) {
      for (final l in json['create_access_levels'] as List) {
        if (l is! Map<String, dynamic>) {
          continue;
        }
        final level = l['access_level'] as int?;
        if (level != null) {
          levels.add(level);
        }
        // Group/user-scoped entries carry a null level plus a
        // description like a group name — keep it readable.
        labels.add(
          l['access_level_description'] as String? ??
              (level == null ? 'Custom' : ProtectedBranch.levelLabel(level)),
        );
      }
    }
    return ProtectedTag(
      name: json['name'] as String? ?? '',
      createLevels: levels,
      createLabels: labels,
    );
  }

  final String name;

  /// Access levels allowed to create matching tags (0/30/40/60).
  final List<int> createLevels;

  /// Display strings per rule — `access_level_description` values.
  final List<String> createLabels;

  bool get isWildcard => name.contains('*');

  @override
  List<Object?> get props => [name];
}
