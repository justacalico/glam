import 'package:equatable/equatable.dart';

/// A pull mirror (`/projects/:id/remote_mirrors`). GitLab syncs
/// branches and tags from [url] into this repository.
class RemoteMirror extends Equatable {
  const RemoteMirror({
    required this.id,
    required this.url,
    this.enabled = true,
    this.onlyProtectedBranches = false,
    this.keepDivergentRefs = false,
    this.mirrorBranchRegex,
    this.updateStatus,
    this.lastError,
    this.lastUpdateAt,
  });

  factory RemoteMirror.fromJson(Map<String, dynamic> json) {
    return RemoteMirror(
      id: json['id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      onlyProtectedBranches: json['only_protected_branches'] as bool? ?? false,
      keepDivergentRefs: json['keep_divergent_refs'] as bool? ?? false,
      mirrorBranchRegex: json['mirror_branch_regex'] as String?,
      updateStatus: json['update_status'] as String?,
      lastError: json['last_error'] as String?,
      lastUpdateAt: json['last_update_at'] is String
          ? DateTime.tryParse(json['last_update_at'] as String)?.toLocal()
          : null,
    );
  }

  final int id;
  final String url;
  final bool enabled;
  final bool onlyProtectedBranches;
  final bool keepDivergentRefs;
  final String? mirrorBranchRegex;
  final String? updateStatus;
  final String? lastError;
  final DateTime? lastUpdateAt;

  @override
  List<Object?> get props => [id, url];
}
