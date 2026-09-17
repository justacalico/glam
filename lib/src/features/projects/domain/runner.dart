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
    this.active = true,
    this.paused = false,
    this.online,
    this.status = '',
    this.tagList = const [],
  });

  factory Runner.fromJson(Map<String, dynamic> json) {
    return Runner(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      name: json['name'] as String? ?? '',
      runnerType: json['runner_type'] as String? ?? 'project_type',
      active: json['active'] as bool? ?? true,
      paused: json['paused'] as bool? ?? false,
      online: json['online'] as bool?,
      status: json['status'] as String? ?? '',
      tagList: json['tag_list'] is List
          ? (json['tag_list'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  final int id;
  final String description;
  final String name;
  final String runnerType;
  final bool active;
  final bool paused;

  /// null means the runner has never contacted GitLab.
  final bool? online;
  final String status;
  final List<String> tagList;

  bool get isShared => runnerType == 'instance_type';

  String get typeLabel => switch (runnerType) {
    'instance_type' => 'Shared',
    'group_type' => 'Group',
    _ => 'Project',
  };

  String get statusLabel {
    if (paused) {
      return 'Paused';
    }
    if (online == null) {
      return 'Never contacted';
    }
    return online! ? 'Online' : 'Offline';
  }

  @override
  List<Object?> get props => [id];
}
