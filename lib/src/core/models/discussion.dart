import 'package:equatable/equatable.dart';
import 'package:glam/src/core/models/note.dart';

/// A thread of notes (`/:id/discussions`). Diff comments and regular
/// comments both come back as discussions; `individualNote` marks
/// single unresolvable comments.
class Discussion extends Equatable {
  const Discussion({
    required this.id,
    required this.notes,
    this.individualNote = false,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) => Discussion(
    id: json['id'] as String? ?? '',
    individualNote: json['individual_note'] as bool? ?? false,
    notes: json['notes'] is List
        ? (json['notes'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Note.fromJson)
              .toList()
        : const [],
  );

  final String id;
  final List<Note> notes;
  final bool individualNote;

  Note? get first => notes.isEmpty ? null : notes.first;

  /// True when every resolvable note is resolved.
  bool get resolved =>
      resolvable && notes.where((n) => n.resolvable).every((n) => n.resolved);

  bool get resolvable => notes.any((n) => n.resolvable);

  /// Diff position of the thread's first note, if it's a diff note.
  NotePosition? get position => first?.position;

  @override
  List<Object?> get props => [id];
}
