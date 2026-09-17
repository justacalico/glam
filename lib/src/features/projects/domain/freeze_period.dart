import 'package:equatable/equatable.dart';

/// A deploy freeze window (`/projects/:id/freeze_periods`). Start and end
/// are cron expressions evaluated in [cronTimezone]; deployments are
/// blocked while the window is active.
class FreezePeriod extends Equatable {
  const FreezePeriod({
    required this.id,
    required this.freezeStart,
    required this.freezeEnd,
    required this.cronTimezone,
  });

  factory FreezePeriod.fromJson(Map<String, dynamic> json) {
    return FreezePeriod(
      id: json['id'] as int? ?? 0,
      freezeStart: json['freeze_start'] as String? ?? '',
      freezeEnd: json['freeze_end'] as String? ?? '',
      cronTimezone: json['cron_timezone'] as String? ?? 'UTC',
    );
  }

  final int id;
  final String freezeStart;
  final String freezeEnd;
  final String cronTimezone;

  @override
  List<Object?> get props => [id, freezeStart, freezeEnd, cronTimezone];
}
