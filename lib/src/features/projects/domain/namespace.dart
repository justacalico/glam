import 'package:equatable/equatable.dart';

/// A namespace the user can create projects in (`/namespaces`).
class GitlabNamespace extends Equatable {
  const GitlabNamespace({
    required this.id,
    required this.path,
    this.name,
    this.kind,
    this.fullPath,
  });

  factory GitlabNamespace.fromJson(Map<String, dynamic> json) =>
      GitlabNamespace(
        id: json['id'] as int? ?? 0,
        path: json['path'] as String? ?? '',
        name: json['name'] as String?,
        kind: json['kind'] as String?,
        fullPath: json['full_path'] as String?,
      );

  final int id;
  final String path;
  final String? name;
  final String? kind;
  final String? fullPath;

  String get label => fullPath ?? path;

  @override
  List<Object?> get props => [id, path];
}
