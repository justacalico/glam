import 'package:equatable/equatable.dart';

/// A protected environment rule (`/projects/:id/protected_environments`).
/// Only listed access levels may deploy to the environment.
class ProtectedEnvironment extends Equatable {
  const ProtectedEnvironment({
    required this.name,
    this.deployLevels = const [],
  });

  factory ProtectedEnvironment.fromJson(Map<String, dynamic> json) {
    final levels = json['deploy_access_levels'];
    return ProtectedEnvironment(
      name: json['name'] as String? ?? '',
      deployLevels: levels is List
          ? levels
                .whereType<Map<String, dynamic>>()
                .map((l) => l['access_level'] as int?)
                .nonNulls
                .toList()
          : const [],
    );
  }

  final String name;
  final List<int> deployLevels;

  @override
  List<Object?> get props => [name, deployLevels];
}
