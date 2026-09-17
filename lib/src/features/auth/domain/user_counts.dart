import 'package:equatable/equatable.dart';

/// Queue sizes for the signed-in user (`/user/counts`), used for
/// dashboard badges.
class UserCounts extends Equatable {
  const UserCounts({
    this.assignedIssues = 0,
    this.assignedMergeRequests = 0,
    this.mergeRequests = 0,
    this.reviewRequestedMergeRequests = 0,
    this.todos = 0,
  });

  factory UserCounts.fromJson(Map<String, dynamic> json) => UserCounts(
    assignedIssues: json['assigned_issues'] as int? ?? 0,
    assignedMergeRequests: json['assigned_merge_requests'] as int? ?? 0,
    mergeRequests: json['merge_requests'] as int? ?? 0,
    reviewRequestedMergeRequests:
        json['review_requested_merge_requests'] as int? ?? 0,
    todos: json['todos'] as int? ?? 0,
  );

  final int assignedIssues;
  final int assignedMergeRequests;

  /// Open MRs where the user is assignee or reviewer.
  final int mergeRequests;
  final int reviewRequestedMergeRequests;
  final int todos;

  /// Badge for the MRs shortcut: assigned plus awaiting the user's
  /// review.
  int get mrBadge => assignedMergeRequests + reviewRequestedMergeRequests;

  @override
  List<Object?> get props => [
    assignedIssues,
    assignedMergeRequests,
    reviewRequestedMergeRequests,
    todos,
  ];
}
