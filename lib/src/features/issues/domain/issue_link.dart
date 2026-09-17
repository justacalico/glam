import 'package:equatable/equatable.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

/// A link between two issues. Each entry is a full issue payload plus
/// `issue_link_id` (the link record's own id, needed to delete it) and
/// `link_type` (`relates_to`, `blocks`, `is_blocked_by`).
class IssueLink extends Equatable {
  const IssueLink({
    required this.issue,
    required this.linkId,
    required this.linkType,
  });

  factory IssueLink.fromJson(Map<String, dynamic> json) {
    return IssueLink(
      issue: Issue.fromJson(json),
      linkId: json['issue_link_id'] as int? ?? 0,
      linkType: json['link_type'] as String? ?? 'relates_to',
    );
  }

  final Issue issue;
  final int linkId;
  final String linkType;

  String get typeLabel => switch (linkType) {
    'blocks' => 'Blocks',
    'is_blocked_by' => 'Blocked by',
    _ => 'Relates to',
  };

  @override
  List<Object?> get props => [linkId];
}
