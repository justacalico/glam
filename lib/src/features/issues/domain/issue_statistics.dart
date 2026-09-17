import 'package:equatable/equatable.dart';

/// Issue counts from `/issues_statistics` (global or per project).
class IssueStatistics extends Equatable {
  const IssueStatistics({
    required this.all,
    required this.opened,
    required this.closed,
  });

  factory IssueStatistics.fromJson(Map<String, dynamic> json) {
    final counts = json['statistics'] is Map
        ? ((json['statistics'] as Map)['counts'] as Map<String, dynamic>? ??
              const {})
        : const <String, dynamic>{};
    int c(String key) => counts[key] is num ? (counts[key]! as num).toInt() : 0;
    return IssueStatistics(
      all: c('all'),
      opened: c('opened'),
      closed: c('closed'),
    );
  }

  final int all;
  final int opened;
  final int closed;

  @override
  List<Object?> get props => [all, opened, closed];
}
