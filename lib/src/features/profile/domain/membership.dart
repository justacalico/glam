import 'package:equatable/equatable.dart';

/// A namespace or project the signed-in user belongs to
/// (`/user/memberships`).
class Membership extends Equatable {
  const Membership({
    required this.sourceId,
    required this.sourceName,
    required this.sourceType,
    this.accessLevel = 0,
    this.expiresAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
    sourceId: json['source_id'] as int? ?? 0,
    sourceName: json['source_name'] as String? ?? '',
    sourceType: json['source_type'] as String? ?? '',
    accessLevel: json['access_level'] as int? ?? 0,
    expiresAt: json['expires_at'] is String
        ? DateTime.tryParse(json['expires_at'] as String)
        : null,
  );

  final int sourceId;
  final String sourceName;

  /// `Namespace` (group) or `Project`.
  final String sourceType;
  final int accessLevel;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [sourceId, sourceType, accessLevel];
}
