import 'package:equatable/equatable.dart';

/// A published package (`/projects/:id/packages`).
class GitLabPackage extends Equatable {
  const GitLabPackage({
    required this.id,
    required this.name,
    this.version = '',
    this.packageType = '',
    this.status = 'default',
    this.createdAt,
  });

  factory GitLabPackage.fromJson(Map<String, dynamic> json) => GitLabPackage(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '',
    packageType: json['package_type'] as String? ?? '',
    status: json['status'] as String? ?? 'default',
    createdAt: _date(json['created_at']),
  );

  final int id;
  final String name;
  final String version;
  final String packageType;
  final String status;
  final DateTime? createdAt;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id];
}

/// A file inside a package (`/packages/:id/package_files`).
class PackageFile extends Equatable {
  const PackageFile({
    required this.id,
    required this.fileName,
    this.size,
    this.fileSha256,
    this.createdAt,
  });

  factory PackageFile.fromJson(Map<String, dynamic> json) => PackageFile(
    id: json['id'] as int? ?? 0,
    fileName: json['file_name'] as String? ?? '',
    size: json['size'] as int?,
    fileSha256: json['file_sha256'] as String?,
    createdAt: GitLabPackage._date(json['created_at']),
  );

  final int id;
  final String fileName;
  final int? size;
  final String? fileSha256;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}

/// A container repository (`/projects/:id/registry/repositories`).
class ContainerRepo extends Equatable {
  const ContainerRepo({
    required this.id,
    required this.name,
    required this.path,
    this.location = '',
    this.tagsCount,
    this.createdAt,
  });

  factory ContainerRepo.fromJson(Map<String, dynamic> json) => ContainerRepo(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    location: json['location'] as String? ?? '',
    tagsCount: json['tags_count'] as int?,
    createdAt: GitLabPackage._date(json['created_at']),
  );

  final int id;
  final String name;
  final String path;
  final String location;
  final int? tagsCount;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, path];
}

/// A tag inside a container repository
/// (`/registry/repositories/:id/tags`).
class RegistryTag extends Equatable {
  const RegistryTag({
    required this.name,
    required this.path,
    this.location = '',
    this.revision = '',
    this.shortRevision = '',
    this.digest = '',
    this.totalSize,
    this.createdAt,
  });

  factory RegistryTag.fromJson(Map<String, dynamic> json) => RegistryTag(
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    location: json['location'] as String? ?? '',
    revision: json['revision'] as String? ?? '',
    shortRevision: json['short_revision'] as String? ?? '',
    digest: json['digest'] as String? ?? '',
    totalSize: json['total_size'] as int?,
    createdAt: GitLabPackage._date(json['created_at']),
  );

  final String name;
  final String path;
  final String location;
  final String revision;
  final String shortRevision;
  final String digest;
  final int? totalSize;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [path, name];
}
