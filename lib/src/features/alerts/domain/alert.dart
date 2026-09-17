import 'package:glam/src/features/auth/domain/user.dart';

/// A Monitor > Alerts entry (`/alert_management/alerts`).
class Alert {
  const Alert({
    required this.iid,
    required this.title,
    required this.status,
    this.severity,
    this.monitoringTool,
    this.service,
    this.startedAt,
    this.endedAt,
    this.eventCount = 0,
    this.hosts = const [],
    this.issueIid,
    this.assignees = const [],
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      iid: json['iid'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'triggered',
      severity: json['severity'] as String?,
      monitoringTool: json['monitoring_tool'] as String?,
      service: json['service'] as String?,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
      endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''),
      eventCount: json['event_count'] as int? ?? 0,
      hosts: json['hosts'] is List
          ? (json['hosts'] as List).map((e) => e.toString()).toList()
          : const [],
      issueIid: json['issue_iid'] as int?,
      assignees: json['assignees'] is List
          ? (json['assignees'] as List)
                .whereType<Map<String, dynamic>>()
                .map(GitLabUser.fromJson)
                .toList()
          : const [],
    );
  }

  final int iid;
  final String title;
  final String status;
  final String? severity;
  final String? monitoringTool;
  final String? service;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int eventCount;
  final List<String> hosts;
  final int? issueIid;
  final List<GitLabUser> assignees;
}
