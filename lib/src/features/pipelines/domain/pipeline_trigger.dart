import 'package:equatable/equatable.dart';

/// A pipeline trigger token (`/projects/:id/triggers`).
class PipelineTrigger extends Equatable {
  const PipelineTrigger({
    required this.id,
    required this.description,
    this.token,
    this.lastUsedAt,
    this.owner,
  });

  factory PipelineTrigger.fromJson(Map<String, dynamic> json) {
    return PipelineTrigger(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      token: json['token'] as String?,
      lastUsedAt: json['last_used'] is String
          ? DateTime.tryParse(json['last_used'] as String)?.toLocal()
          : null,
      owner: json['owner'] is Map<String, dynamic>
          ? (json['owner'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  final int id;
  final String description;

  /// Full for triggers owned by the caller; only the first four
  /// characters for triggers owned by others.
  final String? token;
  final DateTime? lastUsedAt;
  final String? owner;

  @override
  List<Object?> get props => [id, description, token, lastUsedAt, owner];
}

/// Result of `POST /projects/:id/ci/lint`.
class CiLintResult extends Equatable {
  const CiLintResult({
    required this.valid,
    this.errors = const [],
    this.warnings = const [],
    this.jobs = const [],
  });

  factory CiLintResult.fromJson(Map<String, dynamic> json) {
    List<String> strs(String key) => json[key] is List
        ? [for (final e in json[key] as List) e.toString()]
        : const [];
    List<String> names(Object? v) => v is List
        ? [
            for (final e in v)
              e is Map<String, dynamic>
                  ? (e['name'] as String? ?? '')
                  : e.toString(),
          ]
        : const [];
    return CiLintResult(
      valid: json['valid'] as bool? ?? json['status'] == 'valid',
      errors: strs('errors'),
      warnings: strs('warnings'),
      jobs: names(json['jobs']),
    );
  }

  final bool valid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> jobs;

  @override
  List<Object?> get props => [valid, errors, warnings, jobs];
}
