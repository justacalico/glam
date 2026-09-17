import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// A group iteration (`/groups/:id/iterations`). Issues and merge
/// requests embed one as `iteration`.
class Iteration extends Equatable {
  const Iteration({
    required this.id,
    required this.iid,
    required this.state,
    this.title,
    this.startDate,
    this.dueDate,
    this.webUrl,
  });

  factory Iteration.fromJson(Map<String, dynamic> json) => Iteration(
    id: json['id'] as int? ?? 0,
    iid: json['iid'] as int? ?? 0,
    title: json['title'] as String?,
    state: switch (json['state']) {
      // The API sends an int enum; tolerate strings for safety.
      final int s => const {1: 'upcoming', 2: 'current', 3: 'closed'}[s] ?? '',
      final String s => s,
      _ => '',
    },
    startDate: _date(json['start_date']),
    dueDate: _date(json['due_date']),
    webUrl: json['web_url'] as String?,
  );

  final int id;
  final int iid;

  /// Untitled cadence-generated iterations come back null.
  final String? title;

  /// `upcoming`, `current`, `closed` (decoded from the int enum).
  final String state;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? webUrl;

  /// Display name — falls back to the date range like GitLab does.
  String get label {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    if (startDate != null || dueDate != null) {
      return '${_fmt(startDate)} – ${_fmt(dueDate)}';
    }
    return 'Iteration $iid';
  }

  static String _fmt(DateTime? d) =>
      d == null ? '?' : DateFormat.yMMMd().format(d);

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, iid, title, state, startDate, dueDate];
}
