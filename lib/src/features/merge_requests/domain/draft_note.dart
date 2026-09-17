import 'package:equatable/equatable.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// An unpublished review comment (`/merge_requests/:iid/draft_notes`).
/// Published one by one or in bulk when the review is submitted.
class DraftNote extends Equatable {
  const DraftNote({
    required this.id,
    required this.note,
    this.author,
    this.position,
    this.resolveDiscussion = false,
  });

  factory DraftNote.fromJson(Map<String, dynamic> json) => DraftNote(
    id: json['id'] as int? ?? 0,
    note: json['note'] as String? ?? '',
    author: json['author'] is Map<String, dynamic>
        ? GitLabUser.fromJson(json['author'] as Map<String, dynamic>)
        : null,
    position: json['position'] is Map<String, dynamic>
        ? NotePosition.fromJson(json['position'] as Map<String, dynamic>)
        : null,
    resolveDiscussion: json['resolve_discussion'] as bool? ?? false,
  );

  final int id;
  final String note;
  final GitLabUser? author;
  final NotePosition? position;
  final bool resolveDiscussion;

  @override
  List<Object?> get props => [id, note, resolveDiscussion];
}
