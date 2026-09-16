import 'package:equatable/equatable.dart';

/// A protected branch rule (`/projects/:id/protected_branches`).
/// Access levels: 0 no access, 30 developer, 40 maintainer, 60 admin.
class ProtectedBranch extends Equatable {
  const ProtectedBranch({
    required this.id,
    required this.name,
    this.pushLevels = const [],
    this.mergeLevels = const [],
    this.allowForcePush = false,
  });

  factory ProtectedBranch.fromJson(Map<String, dynamic> json) =>
      ProtectedBranch(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        pushLevels: _levels(json['push_access_levels']),
        mergeLevels: _levels(json['merge_access_levels']),
        allowForcePush: json['allow_force_push'] as bool? ?? false,
      );

  final int id;
  final String name;

  /// Access levels allowed to push (0/30/40/60 or a group/user id).
  final List<int> pushLevels;
  final List<int> mergeLevels;
  final bool allowForcePush;

  bool get isWildcard => name.contains('*');

  static String levelLabel(int level) => switch (level) {
    0 => 'No one',
    30 => 'Developers + maintainers',
    40 => 'Maintainers',
    60 => 'Admins',
    _ => 'Level $level',
  };

  static List<int> _levels(Object? json) => json is List
      ? json
            .whereType<Map<String, dynamic>>()
            .map((l) => l['access_level'] as int? ?? 0)
            .toList()
      : const [];

  @override
  List<Object?> get props => [id, name];
}
