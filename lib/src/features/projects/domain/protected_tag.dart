import 'package:equatable/equatable.dart';

/// A protected tag rule (`/projects/:id/protected_tags`). Tags matching
/// `name` (a wildcard like `v*`) can only be created by the listed
/// access levels.
class ProtectedTag extends Equatable {
  const ProtectedTag({required this.name, this.createLevels = const []});

  factory ProtectedTag.fromJson(Map<String, dynamic> json) => ProtectedTag(
    name: json['name'] as String? ?? '',
    createLevels: json['create_access_levels'] is List
        ? (json['create_access_levels'] as List)
              .whereType<Map<String, dynamic>>()
              .map((l) => l['access_level'] as int?)
              .nonNulls
              .toList()
        : const [],
  );

  final String name;

  /// Access levels allowed to create matching tags (0/30/40/60).
  final List<int> createLevels;

  bool get isWildcard => name.contains('*');

  @override
  List<Object?> get props => [name];
}
