import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A CI/CD pipeline (`/projects/:id/pipelines`).
class Pipeline extends Equatable {
  const Pipeline({
    required this.id,
    required this.status,
    this.iid,
    this.ref,
    this.sha,
    this.source,
    this.createdAt,
    this.updatedAt,
    this.startedAt,
    this.finishedAt,
    this.duration,
    this.user,
    this.webUrl,
  });

  factory Pipeline.fromJson(Map<String, dynamic> json) {
    return Pipeline(
      id: json['id'] as int? ?? 0,
      iid: json['iid'] as int?,
      status: json['status'] as String? ?? 'unknown',
      ref: json['ref'] as String?,
      sha: json['sha'] as String?,
      source: json['source'] as String?,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      startedAt: _date(json['started_at']),
      finishedAt: _date(json['finished_at']),
      duration: json['duration'] as num?,
      user: json['user'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      webUrl: json['web_url'] as String?,
    );
  }

  final int id;
  final int? iid;

  /// `success`, `running`, `failed`, `canceled`, `pending`,
  /// `skipped`, `manual`, `created`, `waiting_for_resource`,
  /// `preparing`, `scheduled`.
  final String status;
  final String? ref;
  final String? sha;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Seconds — the API returns a float.
  final num? duration;
  final GitLabUser? user;
  final String? webUrl;

  bool get isRunning =>
      status == 'running' ||
      status == 'pending' ||
      status == 'preparing' ||
      status == 'waiting_for_resource';

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, status];
}

/// A single job inside a pipeline.
class Job extends Equatable {
  const Job({
    required this.id,
    required this.name,
    required this.status,
    this.stage,
    this.ref,
    this.startedAt,
    this.finishedAt,
    this.duration,
    this.user,
    this.allowFailure = false,
    this.tagList = const [],
    this.webUrl,
    this.artifactsSize,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      stage: json['stage'] as String?,
      ref: json['ref'] as String?,
      startedAt: _date(json['started_at']),
      finishedAt: _date(json['finished_at']),
      duration: json['duration'] as num?,
      user: json['user'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      allowFailure: json['allow_failure'] as bool? ?? false,
      tagList: json['tag_list'] is List
          ? (json['tag_list'] as List).map((e) => e.toString()).toList()
          : const [],
      webUrl: json['web_url'] as String?,
      artifactsSize: json['artifacts_file'] is Map<String, dynamic>
          ? (json['artifacts_file'] as Map<String, dynamic>)['size'] as int?
          : null,
    );
  }

  final int id;
  final String name;
  final String status;
  final String? stage;
  final String? ref;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final num? duration;
  final GitLabUser? user;
  final bool allowFailure;
  final List<String> tagList;
  final String? webUrl;

  /// Size of `artifacts_file`, when the job produced artifacts.
  final int? artifactsSize;

  bool get hasArtifacts => artifactsSize != null;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, status];
}
