import 'package:equatable/equatable.dart';

/// A project or group label (`/:id/labels`).
class Label extends Equatable {
  const Label({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    this.textColor,
    this.openIssuesCount,
    this.openMergeRequestsCount,
    this.subscribed,
  });

  factory Label.fromJson(Map<String, dynamic> json) => Label(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    color: json['color'] as String? ?? '',
    description: json['description'] as String?,
    textColor: json['text_color'] as String?,
    openIssuesCount: json['open_issues_count'] as int?,
    openMergeRequestsCount: json['open_merge_requests_count'] as int?,
    subscribed: json['subscribed'] as bool?,
  );

  final int id;
  final String name;

  /// `#rrggbb`.
  final String color;
  final String? description;
  final String? textColor;
  final int? openIssuesCount;
  final int? openMergeRequestsCount;
  final bool? subscribed;

  @override
  List<Object?> get props => [id, name];
}
