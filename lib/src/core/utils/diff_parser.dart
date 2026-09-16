import 'dart:convert';

import 'package:equatable/equatable.dart';

/// One line inside a diff hunk.
enum DiffLineKind { context, added, removed, meta }

class DiffLine extends Equatable {
  const DiffLine({
    required this.kind,
    required this.content,
    this.oldLine,
    this.newLine,
  });

  final DiffLineKind kind;

  /// The line content without the leading `+`/`-`/space marker.
  final String content;
  final int? oldLine;
  final int? newLine;

  @override
  List<Object?> get props => [kind, content, oldLine, newLine];
}

/// A `@@ -a,b +c,d @@` section of a file diff.
class DiffHunk extends Equatable {
  const DiffHunk({
    required this.header,
    required this.lines,
    this.oldStart = 0,
    this.newStart = 0,
  });

  final String header;
  final List<DiffLine> lines;
  final int oldStart;
  final int newStart;

  @override
  List<Object?> get props => [header, lines.length];
}

/// The diff for a single file (as GitLab returns it in `diff` fields).
class FileDiff extends Equatable {
  const FileDiff({
    required this.oldPath,
    required this.newPath,
    required this.hunks,
    this.newFile = false,
    this.deletedFile = false,
    this.renamedFile = false,
  });

  final String oldPath;
  final String newPath;
  final List<DiffHunk> hunks;
  final bool newFile;
  final bool deletedFile;
  final bool renamedFile;

  String get displayPath => renamedFile ? '$oldPath → $newPath' : newPath;

  int get additions => hunks
      .expand((h) => h.lines)
      .where((l) => l.kind == DiffLineKind.added)
      .length;

  int get deletions => hunks
      .expand((h) => h.lines)
      .where((l) => l.kind == DiffLineKind.removed)
      .length;

  @override
  List<Object?> get props => [oldPath, newPath, hunks.length];
}

/// Parses unified-diff text (as returned in `diff` on GitLab change
/// objects) into structured [DiffHunk]s.
abstract final class DiffParser {
  static final _hunkHeader = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

  static List<DiffHunk> parse(String diff) {
    final hunks = <DiffHunk>[];
    var lines = <DiffLine>[];
    var inHunk = false;
    var header = '';
    var oldStart = 0;
    var newStart = 0;
    var oldLine = 0;
    var newLine = 0;

    void flush() {
      if (inHunk) {
        hunks.add(
          DiffHunk(
            header: header,
            lines: List.unmodifiable(lines),
            oldStart: oldStart,
            newStart: newStart,
          ),
        );
      }
    }

    for (final raw in const LineSplitter().convert(diff)) {
      final match = _hunkHeader.firstMatch(raw);
      if (match != null) {
        flush();
        header = raw;
        oldStart = int.parse(match.group(1)!);
        newStart = int.parse(match.group(2)!);
        oldLine = oldStart;
        newLine = newStart;
        lines = [];
        inHunk = true;
        continue;
      }
      if (!inHunk) {
        continue;
      }
      if (raw.startsWith('+')) {
        lines.add(
          DiffLine(
            kind: DiffLineKind.added,
            content: raw.substring(1),
            newLine: newLine++,
          ),
        );
      } else if (raw.startsWith('-')) {
        lines.add(
          DiffLine(
            kind: DiffLineKind.removed,
            content: raw.substring(1),
            oldLine: oldLine++,
          ),
        );
      } else if (raw.startsWith(r'\')) {
        lines.add(DiffLine(kind: DiffLineKind.meta, content: raw));
      } else {
        final content = raw.isEmpty ? '' : raw.substring(1);
        lines.add(
          DiffLine(
            kind: DiffLineKind.context,
            content: content,
            oldLine: oldLine++,
            newLine: newLine++,
          ),
        );
      }
    }
    flush();
    return hunks;
  }
}
