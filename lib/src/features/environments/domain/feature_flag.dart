import 'package:equatable/equatable.dart';

/// An environment scope on a feature flag.
class FlagScope extends Equatable {
  const FlagScope({
    required this.id,
    this.environmentScope = '*',
    this.active = false,
  });

  factory FlagScope.fromJson(Map<String, dynamic> json) {
    return FlagScope(
      id: json['id'] as int? ?? 0,
      environmentScope: json['environment_scope'] as String? ?? '*',
      active: json['active'] as bool? ?? false,
    );
  }

  final int id;
  final String environmentScope;
  final bool active;

  @override
  List<Object?> get props => [id, environmentScope, active];
}

/// A project feature flag (`/projects/:id/feature_flags`). Version 2
/// flags carry per-scope strategies; version 1 is a single toggle.
class FeatureFlag extends Equatable {
  const FeatureFlag({
    required this.id,
    required this.name,
    this.description = '',
    this.active = false,
    this.version = 1,
    this.scopes = const [],
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    final scopes = json['scopes'];
    return FeatureFlag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      scopes: scopes is List
          ? scopes
                .whereType<Map<String, dynamic>>()
                .map(FlagScope.fromJson)
                .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final String description;
  final bool active;
  final int version;
  final List<FlagScope> scopes;

  @override
  List<Object?> get props => [id, name, active, version, scopes];
}
