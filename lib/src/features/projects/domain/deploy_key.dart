import 'package:equatable/equatable.dart';

/// A deploy key enabled on the project (`/projects/:id/deploy_keys`).
class DeployKey extends Equatable {
  const DeployKey({
    required this.id,
    required this.title,
    this.key = '',
    this.canPush = false,
    this.createdAt,
  });

  factory DeployKey.fromJson(Map<String, dynamic> json) => DeployKey(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    key: json['key'] as String? ?? '',
    canPush: json['can_push'] as bool? ?? false,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  final int id;
  final String title;
  final String key;
  final bool canPush;
  final DateTime? createdAt;

  /// Fingerprint-style display: last chunk of the base64 body.
  String get fingerprint {
    final parts = key.trim().split(RegExp(r'\s+'));
    final material = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : key.trim();
    return material.length <= 12
        ? material
        : '…${material.substring(material.length - 12)}';
  }

  @override
  List<Object?> get props => [id];
}
