import 'package:equatable/equatable.dart';

/// Status of a project export (`/projects/:id/export`).
class ProjectExport extends Equatable {
  const ProjectExport({this.id, required this.status, this.createdAt});

  factory ProjectExport.fromJson(Map<String, dynamic> json) => ProjectExport(
    id: json['id'] as int?,
    status: json['export_status'] as String? ?? 'none',
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  final int? id;
  final String status;
  final DateTime? createdAt;

  bool get finished => status == 'finished';
  bool get running => status == 'queued' || status == 'started';

  String get statusLabel => switch (status) {
    'finished' => 'Ready to download',
    'queued' => 'Queued',
    'started' => 'Exporting',
    'regeneration_in_progress' => 'Regenerating',
    'failed' => 'Export failed',
    _ => 'No export yet',
  };

  @override
  List<Object?> get props => [id, status];
}
