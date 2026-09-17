import 'package:equatable/equatable.dart';
import 'package:glam/src/features/labels/domain/label.dart';

/// An issue board (`/projects/:id/boards`).
class Board extends Equatable {
  const Board({
    required this.id,
    required this.name,
    this.milestoneId,
    this.labels = const [],
    this.weight,
    this.lists = const [],
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    final lists = json['lists'];
    return Board(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      milestoneId: json['milestone'] is Map<String, dynamic>
          ? json['milestone']['id'] as int?
          : null,
      labels: json['labels'] is List
          ? (json['labels'] as List)
                .whereType<Map<String, dynamic>>()
                .map((l) => l['name'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList()
          : const [],
      weight: json['weight'] as int?,
      lists: lists is List
          ? lists
                .whereType<Map<String, dynamic>>()
                .map(BoardList.fromJson)
                .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final int? milestoneId;

  /// Scope filters from the board settings.
  final List<String> labels;
  final int? weight;

  /// Populated on the detail endpoint (`/boards/:id`).
  final List<BoardList> lists;

  @override
  List<Object?> get props => [id, name];
}

/// A column on a board. `list_type` is `backlog`, `label`, `closed`,
/// `assignee`, or `milestone`.
class BoardList extends Equatable {
  const BoardList({
    required this.id,
    required this.listType,
    this.label,
    this.position = 0,
    this.issuesCount,
  });

  factory BoardList.fromJson(Map<String, dynamic> json) => BoardList(
    id: json['id'] as int? ?? 0,
    listType: json['list_type'] as String? ?? '',
    label: json['label'] is Map<String, dynamic>
        ? Label.fromJson(json['label'] as Map<String, dynamic>)
        : null,
    position: json['position'] as int? ?? 0,
    issuesCount: json['issues_count'] as int?,
  );

  final int id;
  final String listType;
  final Label? label;
  final int position;
  final int? issuesCount;

  String get title => switch (listType) {
    'backlog' => 'Open',
    'closed' => 'Closed',
    _ => label?.name ?? listType,
  };

  @override
  List<Object?> get props => [id, position];
}
