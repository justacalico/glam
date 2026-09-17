import 'package:equatable/equatable.dart';

/// Storage usage returned by `GET /projects/:id?statistics=true`.
/// All sizes are bytes; any may be absent on older instances.
class ProjectStatistics extends Equatable {
  const ProjectStatistics({
    this.commitCount = 0,
    this.storageSize = 0,
    this.repositorySize = 0,
    this.lfsObjectsSize = 0,
    this.jobArtifactsSize = 0,
    this.packagesSize = 0,
    this.uploadsSize = 0,
    this.wikiSize = 0,
    this.snippetsSize = 0,
    this.containerRegistrySize = 0,
  });

  factory ProjectStatistics.fromJson(Map<String, dynamic> json) {
    int size(String key) => json[key] is num ? (json[key]! as num).toInt() : 0;
    return ProjectStatistics(
      commitCount: size('commit_count'),
      storageSize: size('storage_size'),
      repositorySize: size('repository_size'),
      lfsObjectsSize: size('lfs_objects_size'),
      jobArtifactsSize: size('job_artifacts_size'),
      packagesSize: size('packages_size'),
      uploadsSize: size('uploads_size'),
      wikiSize: size('wiki_size'),
      snippetsSize: size('snippets_size'),
      containerRegistrySize: size('container_registry_size'),
    );
  }

  final int commitCount;
  final int storageSize;
  final int repositorySize;
  final int lfsObjectsSize;
  final int jobArtifactsSize;
  final int packagesSize;
  final int uploadsSize;
  final int wikiSize;
  final int snippetsSize;
  final int containerRegistrySize;

  @override
  List<Object?> get props => [
    commitCount,
    storageSize,
    repositorySize,
    lfsObjectsSize,
    jobArtifactsSize,
    packagesSize,
    uploadsSize,
    wikiSize,
    snippetsSize,
    containerRegistrySize,
  ];
}
