import 'package:equatable/equatable.dart';

/// A CI/CD Secure File (`/projects/:id/secure_files`).
class SecureFile extends Equatable {
  const SecureFile({
    required this.id,
    required this.name,
    this.checksum,
    this.checksumAlgorithm,
    this.expiresAt,
    this.permissions = 'read_only',
  });

  factory SecureFile.fromJson(Map<String, dynamic> json) {
    final raw = json['expires_at'];
    return SecureFile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      checksum: json['checksum'] as String?,
      checksumAlgorithm: json['checksum_algorithm'] as String?,
      expiresAt: raw is String ? DateTime.tryParse(raw)?.toLocal() : null,
      permissions: json['permissions'] as String? ?? 'read_only',
    );
  }

  final int id;
  final String name;
  final String? checksum;
  final String? checksumAlgorithm;
  final DateTime? expiresAt;
  final String permissions;

  @override
  List<Object?> get props => [id];
}
