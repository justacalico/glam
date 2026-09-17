import 'package:equatable/equatable.dart';

/// A CI/CD runner attached to a project (`/projects/:id/runners`).
/// `runnerType` is `instance_type` (shared), `group_type`, or
/// `project_type`. `online` is null until the runner first contacts.
class Runner extends Equatable {
  const Runner({
    required this.id,
    this.description = '',
    this.name = '',
    this.runnerType = 'project_type',
    this.paused = false,
    this.status = 'never_contacted',
    this.tagList = const [],
  });

  factory Runner.fromJson(Map<String, dynamic> json) {
    return Runner(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      name: json['name'] as String? ?? '',
      runnerType: json['runner_type'] as String? ?? 'project_type',
      paused: json['paused'] as bool? ?? false,
      status: json['status'] as String? ?? 'never_contacted',
      tagList: json['tag_list'] is List
          ? (json['tag_list'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  final int id;
  final String description;
  final String name;
  final String runnerType;
  final bool paused;

  /// `online`, `offline`, `stale`, or `never_contacted`.
  final String status;
  final List<String> tagList;

  bool get isProjectRunner => runnerType == 'project_type';

  String get typeLabel => switch (runnerType) {
    'instance_type' => 'Shared',
    'group_type' => 'Group',
    _ => 'Project',
  };

  String get statusLabel {
    if (paused) {
      return 'Paused';
    }
    return switch (status) {
      'online' => 'Online',
      'offline' => 'Offline',
      'stale' => 'Stale',
      'never_contacted' => 'Never contacted',
      _ => status.isEmpty ? 'Unknown' : status,
    };
  }

  @override
  List<Object?> get props => [id];
}
