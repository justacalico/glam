import 'package:equatable/equatable.dart';

/// Shared by issues, MRs, and the milestones page.
class Milestone extends Equatable {
  const Milestone({
    required this.id,
    required this.title,
    this.iid,
    this.state,
    this.dueDate,
    this.startDate,
    this.description,
    this.webUrl,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as int? ?? 0,
      iid: json['iid'] as int?,
      title: json['title'] as String? ?? '',
      state: json['state'] as String?,
      dueDate: _date(json['due_date']),
      startDate: _date(json['start_date']),
      description: json['description'] as String?,
      webUrl: json['web_url'] as String?,
    );
  }

  final int id;
  final int? iid;
  final String title;
  final String? state;
  final DateTime? dueDate;
  final DateTime? startDate;
  final String? description;
  final String? webUrl;

  bool get isActive => state == 'active';

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, title];
}
