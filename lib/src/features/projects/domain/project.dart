import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A GitLab project (`/projects/:id`).
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    required this.path,
    required this.pathWithNamespace,
    this.nameWithNamespace,
    this.description,
    this.defaultBranch,
    this.webUrl,
    this.avatarUrl,
    this.starCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.lastActivityAt,
    this.createdAt,
    this.visibility,
    this.namespaceKind,
    this.namespacePath,
    this.archived = false,
    this.topics = const [],
    this.sshUrl,
    this.httpUrl,
    this.readmeUrl,
    this.owner,
    this.forkedFromId,
    this.importStatus,
    this.emptyRepo = false,
    this.issuesEnabled = true,
    this.mergeRequestsEnabled = true,
    this.wikiEnabled = true,
    this.snippetsEnabled = true,
    this.jobsEnabled = true,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final namespace = json['namespace'];
    String? nsKind;
    String? nsPath;
    if (namespace is Map<String, dynamic>) {
      nsKind = namespace['kind'] as String?;
      nsPath = namespace['full_path'] as String?;
    }
    final ownerJson = json['owner'];
    final forked = json['forked_from_project'];

    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      pathWithNamespace: json['path_with_namespace'] as String? ?? '',
      nameWithNamespace: json['name_with_namespace'] as String?,
      description: json['description'] as String?,
      defaultBranch: json['default_branch'] as String?,
      webUrl: json['web_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      starCount: json['star_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      lastActivityAt: _date(json['last_activity_at']),
      createdAt: _date(json['created_at']),
      visibility: json['visibility'] as String?,
      namespaceKind: nsKind,
      namespacePath: nsPath,
      archived: json['archived'] as bool? ?? false,
      topics: _strings(json['topics'] ?? json['tag_list']),
      sshUrl: json['ssh_url_to_repo'] as String?,
      httpUrl: json['http_url_to_repo'] as String?,
      readmeUrl: json['readme_url'] as String?,
      owner: ownerJson is Map<String, dynamic>
          ? GitLabUser.fromJson(ownerJson)
          : null,
      forkedFromId: forked is Map<String, dynamic>
          ? forked['id'] as int?
          : null,
      importStatus: json['import_status'] as String?,
      emptyRepo: json['empty_repo'] as bool? ?? false,
      issuesEnabled: json['issues_enabled'] as bool? ?? true,
      mergeRequestsEnabled: json['merge_requests_enabled'] as bool? ?? true,
      wikiEnabled: json['wiki_enabled'] as bool? ?? true,
      snippetsEnabled: json['snippets_enabled'] as bool? ?? true,
      jobsEnabled: json['jobs_enabled'] as bool? ?? true,
    );
  }

  final int id;
  final String name;
  final String path;
  final String pathWithNamespace;
  final String? nameWithNamespace;
  final String? description;
  final String? defaultBranch;
  final String? webUrl;
  final String? avatarUrl;
  final int starCount;
  final int forksCount;
  final int openIssuesCount;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;
  final String? visibility;
  final String? namespaceKind;
  final String? namespacePath;
  final bool archived;
  final List<String> topics;
  final String? sshUrl;
  final String? httpUrl;
  final String? readmeUrl;
  final GitLabUser? owner;
  final int? forkedFromId;
  final String? importStatus;
  final bool emptyRepo;
  final bool issuesEnabled;
  final bool mergeRequestsEnabled;
  final bool wikiEnabled;
  final bool snippetsEnabled;
  final bool jobsEnabled;

  /// Display name: `namespace / project`.
  String get displayName => nameWithNamespace ?? pathWithNamespace;

  bool get isGroupNamespace => namespaceKind == 'group';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static List<String> _strings(Object? value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  @override
  List<Object?> get props => [
    id,
    pathWithNamespace,
    name,
    starCount,
    forksCount,
    lastActivityAt,
    archived,
  ];
}
