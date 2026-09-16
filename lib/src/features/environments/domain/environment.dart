import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A deployment environment (`/projects/:id/environments`).
class GlEnvironment extends Equatable {
  const GlEnvironment({
    required this.id,
    required this.name,
    this.slug,
    this.state = 'available',
    this.externalUrl,
    this.lastDeployment,
    this.createdAt,
    this.updatedAt,
  });

  factory GlEnvironment.fromJson(Map<String, dynamic> json) => GlEnvironment(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String?,
    state: json['state'] as String? ?? 'available',
    externalUrl: json['external_url'] as String?,
    lastDeployment: json['last_deployment'] is Map<String, dynamic>
        ? Deployment.fromJson(json['last_deployment'] as Map<String, dynamic>)
        : null,
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  final int id;
  final String name;
  final String? slug;

  /// `available`, `stopped`.
  final String state;
  final String? externalUrl;
  final Deployment? lastDeployment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAvailable => state == 'available';

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, name, state];
}

/// A deployment (`/projects/:id/deployments`), also embedded as
/// `last_deployment` on environments.
class Deployment extends Equatable {
  const Deployment({
    required this.id,
    required this.iid,
    this.ref,
    this.sha,
    this.status,
    this.user,
    this.deployableName,
    this.createdAt,
    this.updatedAt,
  });

  factory Deployment.fromJson(Map<String, dynamic> json) => Deployment(
    id: json['id'] as int? ?? 0,
    iid: json['iid'] as int? ?? 0,
    ref: json['ref'] as String?,
    sha: json['sha'] as String?,
    status: json['status'] as String?,
    user: json['user'] is Map<String, dynamic>
        ? GitLabUser.fromJson(json['user'] as Map<String, dynamic>)
        : null,
    deployableName: json['deployable'] is Map<String, dynamic>
        ? (json['deployable'] as Map<String, dynamic>)['name'] as String?
        : null,
    createdAt: GlEnvironment._date(json['created_at']),
    updatedAt: GlEnvironment._date(json['updated_at']),
  );

  final int id;
  final int iid;
  final String? ref;
  final String? sha;

  /// `created`, `running`, `success`, `failed`, `canceled`.
  final String? status;
  final GitLabUser? user;
  final String? deployableName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, iid, status];
}
