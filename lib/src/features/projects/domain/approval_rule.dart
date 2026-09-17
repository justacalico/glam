import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A project merge-request approval rule. `users` holds the explicitly
/// configured approvers; `groups` are name-only since the app does not
/// manage group membership from this surface.
class ApprovalRule extends Equatable {
  const ApprovalRule({
    required this.id,
    required this.name,
    this.ruleType,
    this.approvalsRequired = 0,
    this.users = const [],
    this.groups = const [],
    this.eligibleApproverCount = 0,
    this.containsHiddenGroups = false,
  });

  factory ApprovalRule.fromJson(Map<String, dynamic> json) {
    final users = json['users'];
    final groups = json['groups'];
    final eligible = json['eligible_approvers'];
    return ApprovalRule(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      ruleType: json['rule_type'] as String?,
      approvalsRequired: json['approvals_required'] as int? ?? 0,
      users: users is List
          ? users
                .whereType<Map<String, dynamic>>()
                .map(GitLabUser.fromJson)
                .toList()
          : const [],
      groups: groups is List
          ? groups
                .whereType<Map<String, dynamic>>()
                .map(
                  (g) =>
                      (g['full_path'] ?? g['path'] ?? g['name'] ?? '')
                          as String,
                )
                .where((p) => p.isNotEmpty)
                .toList()
          : const [],
      eligibleApproverCount: eligible is List ? eligible.length : 0,
      containsHiddenGroups: json['contains_hidden_groups'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final String? ruleType;
  final int approvalsRequired;
  final List<GitLabUser> users;
  final List<String> groups;
  final int eligibleApproverCount;

  /// True when the rule has groups the caller can't see — the approver
  /// list is then truncated server-side.
  final bool containsHiddenGroups;

  @override
  List<Object?> get props => [id, name, approvalsRequired];
}
