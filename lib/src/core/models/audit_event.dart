import 'package:equatable/equatable.dart';

/// A project or group audit event (`/projects/:id/audit_events`,
/// `/groups/:id/audit_events`). Premium-gated upstream.
class AuditEvent extends Equatable {
  const AuditEvent({
    required this.id,
    this.authorId,
    this.entityId,
    this.entityType,
    this.details = const {},
    this.createdAt,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'] as int? ?? 0,
    authorId: json['author_id'] as int?,
    entityId: json['entity_id'] as int?,
    entityType: json['entity_type'] as String?,
    details: json['details'] is Map<String, dynamic>
        ? json['details'] as Map<String, dynamic>
        : const {},
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  final int id;
  final int? authorId;
  final int? entityId;
  final String? entityType;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  String? get authorName => details['author_name'] as String?;
  String? get change => details['change'] as String?;
  String? get targetDetails => details['target_details'] as String?;
  String? get ipAddress => details['ip_address'] as String?;

  @override
  List<Object?> get props => [id];
}
