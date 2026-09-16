import 'package:equatable/equatable.dart';

/// A project wiki page (`/projects/:id/wikis`).
class WikiPage extends Equatable {
  const WikiPage({
    required this.slug,
    required this.title,
    this.format,
    this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory WikiPage.fromJson(Map<String, dynamic> json) => WikiPage(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    format: json['format'] as String?,
    content: json['content'] as String?,
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  /// URL-safe identifier used by the API.
  final String slug;
  final String title;

  /// `markdown`, `rdoc`, `asciidoc`, `org`.
  final String? format;

  /// Only present on the single-page endpoint.
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [slug, title, updatedAt];
}
