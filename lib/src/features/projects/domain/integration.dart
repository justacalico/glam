import 'package:equatable/equatable.dart';

/// A project integration (`/projects/:id/services`), e.g. Slack or
/// Jira. [properties] is the configured key/value set; secret fields
/// may come back masked.
class Integration extends Equatable {
  const Integration({
    required this.slug,
    this.title = '',
    this.active = false,
    this.properties = const {},
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    return Integration(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      properties: props is Map
          ? {
              for (final e in props.entries)
                if (e.value != null) '${e.key}': '${e.value}',
            }
          : const {},
    );
  }

  final String slug;
  final String title;
  final bool active;
  final Map<String, String> properties;

  @override
  List<Object?> get props => [slug, title, active, properties];
}
