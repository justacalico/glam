import 'package:equatable/equatable.dart';

/// A bridge job (`/projects/:id/pipelines/:id/bridges`) — a job that
/// triggers a downstream pipeline, either in this project or another.
class Bridge extends Equatable {
  const Bridge({
    required this.id,
    required this.name,
    this.stage,
    this.status = 'unknown',
    this.downstream,
  });

  factory Bridge.fromJson(Map<String, dynamic> json) {
    return Bridge(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      stage: json['stage'] as String?,
      status: json['status'] as String? ?? 'unknown',
      downstream: json['downstream_pipeline'] is Map<String, dynamic>
          ? DownstreamPipeline.fromJson(
              json['downstream_pipeline'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String name;
  final String? stage;
  final String status;

  /// The pipeline this bridge triggered; null until it starts.
  final DownstreamPipeline? downstream;

  @override
  List<Object?> get props => [id, name, downstream];
}

/// The pipeline a [Bridge] spawned. `projectId` is present when the
/// pipeline lives in a different project (multi-project pipelines).
class DownstreamPipeline extends Equatable {
  const DownstreamPipeline({
    required this.id,
    this.status = 'unknown',
    this.ref,
    this.sha,
    this.projectId,
    this.projectName,
    this.webUrl,
  });

  factory DownstreamPipeline.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    return DownstreamPipeline(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
      ref: json['ref'] as String?,
      sha: json['sha'] as String?,
      projectId: project is Map<String, dynamic> ? project['id'] as int? : null,
      projectName: project is Map<String, dynamic>
          ? project['name'] as String?
          : null,
      webUrl: json['web_url'] as String?,
    );
  }

  final int id;
  final String status;
  final String? ref;
  final String? sha;
  final int? projectId;
  final String? projectName;
  final String? webUrl;

  @override
  List<Object?> get props => [id, status, projectId];
}
