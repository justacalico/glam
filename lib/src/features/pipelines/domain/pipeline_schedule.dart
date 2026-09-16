import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A CI/CD variable attached to a schedule.
class ScheduleVariable extends Equatable {
  const ScheduleVariable({
    required this.key,
    this.value = '',
    this.variableType = 'env_var',
  });

  factory ScheduleVariable.fromJson(Map<String, dynamic> json) =>
      ScheduleVariable(
        key: json['key'] as String? ?? '',
        value: json['value'] as String? ?? '',
        variableType: json['variable_type'] as String? ?? 'env_var',
      );

  final String key;
  final String value;
  final String variableType;

  @override
  List<Object?> get props => [key, value, variableType];
}

/// A scheduled pipeline (`/projects/:id/pipeline_schedules`).
class PipelineSchedule extends Equatable {
  const PipelineSchedule({
    required this.id,
    this.description = '',
    this.ref = '',
    this.cron = '',
    this.cronTimezone = 'UTC',
    this.nextRunAt,
    this.active = false,
    this.owner,
    this.lastPipelineStatus,
    this.variables = const [],
  });

  factory PipelineSchedule.fromJson(Map<String, dynamic> json) {
    final last = json['last_pipeline'];
    final vars = json['variables'];
    return PipelineSchedule(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      ref: json['ref'] as String? ?? '',
      cron: json['cron'] as String? ?? '',
      cronTimezone: json['cron_timezone'] as String? ?? 'UTC',
      nextRunAt: _date(json['next_run_at']),
      active: json['active'] as bool? ?? false,
      owner: json['owner'] is Map<String, dynamic>
          ? GitLabUser.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      lastPipelineStatus: last is Map<String, dynamic>
          ? last['status'] as String?
          : null,
      variables: vars is List
          ? vars
                .whereType<Map<String, dynamic>>()
                .map(ScheduleVariable.fromJson)
                .toList()
          : const [],
    );
  }

  final int id;
  final String description;
  final String ref;
  final String cron;
  final String cronTimezone;
  final DateTime? nextRunAt;
  final bool active;
  final GitLabUser? owner;

  /// Status of the most recent scheduled run (`last_pipeline.status`).
  final String? lastPipelineStatus;
  final List<ScheduleVariable> variables;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [
    id,
    description,
    ref,
    cron,
    cronTimezone,
    nextRunAt,
    active,
    owner,
    lastPipelineStatus,
    variables,
  ];
}
