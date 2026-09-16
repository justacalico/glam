import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A GitLab snippet (personal or project-scoped).
class Snippet extends Equatable {
  const Snippet({
    required this.id,
    required this.title,
    this.description,
    this.fileName,
    this.author,
    this.visibility,
    this.webUrl,
    this.rawUrl,
    this.projectId,
    this.files = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Snippet.fromJson(Map<String, dynamic> json) {
    final files = json['files'];
    return Snippet(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fileName: json['file_name'] as String?,
      author: json['author'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      visibility: json['visibility'] as String?,
      webUrl: json['web_url'] as String?,
      rawUrl: json['raw_url'] as String?,
      projectId: json['project_id'] as int?,
      files: files is List
          ? files
                .whereType<Map<String, dynamic>>()
                .map(SnippetFile.fromJson)
                .toList()
          : const [],
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String? fileName;
  final GitLabUser? author;
  final String? visibility;
  final String? webUrl;
  final String? rawUrl;
  final int? projectId;
  final List<SnippetFile> files;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, title, updatedAt];
}

/// One file inside a multi-file snippet.
class SnippetFile extends Equatable {
  const SnippetFile({required this.path, this.rawUrl});

  factory SnippetFile.fromJson(Map<String, dynamic> json) => SnippetFile(
    path: json['path'] as String? ?? '',
    rawUrl: json['raw_url'] as String?,
  );

  final String path;
  final String? rawUrl;

  @override
  List<Object?> get props => [path];
}
