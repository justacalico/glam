import 'package:equatable/equatable.dart';

/// A group iteration (`/groups/:id/iterations`). Issues and merge
/// requests embed one as `iteration`.
class Iteration extends Equatable {
  const Iteration({
    required this.id,
    required this.iid,
    required this.title,
    required this.state,
    this.startDate,
    this.dueDate,
    this.webUrl,
  });

  factory Iteration.fromJson(Map<String, dynamic> json) => Iteration(
    id: json['id'] as int? ?? 0,
    iid: json['iid'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    state: json['state'] as String? ?? '',
    startDate: _date(json['start_date']),
    dueDate: _date(json['due_date']),
    webUrl: json['web_url'] as String?,
  );

  final int id;
  final int iid;
  final String title;

  /// `opened`, `closed`, `current`, `upcoming`, `started`.
  final String state;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? webUrl;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, title, state];
}
