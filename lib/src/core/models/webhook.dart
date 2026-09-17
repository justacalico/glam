import 'package:equatable/equatable.dart';

/// A project or group webhook (`/projects/:id/hooks`, `/groups/:id/hooks`).
class Webhook extends Equatable {
  const Webhook({
    required this.id,
    required this.url,
    this.pushEvents = true,
    this.issuesEvents = false,
    this.mergeRequestsEvents = false,
    this.pipelineEvents = false,
    this.wikiPageEvents = false,
    this.deploymentEvents = false,
    this.releasesEvents = false,
    this.tagPushEvents = false,
    this.noteEvents = false,
    this.jobEvents = false,
    this.subgroupEvents = false,
    this.enableSslVerification = true,
    this.createdAt,
  });

  factory Webhook.fromJson(Map<String, dynamic> json) => Webhook(
    id: json['id'] as int? ?? 0,
    url: json['url'] as String? ?? '',
    pushEvents: json['push_events'] as bool? ?? true,
    issuesEvents: json['issues_events'] as bool? ?? false,
    mergeRequestsEvents: json['merge_requests_events'] as bool? ?? false,
    pipelineEvents: json['pipeline_events'] as bool? ?? false,
    wikiPageEvents: json['wiki_page_events'] as bool? ?? false,
    deploymentEvents: json['deployment_events'] as bool? ?? false,
    releasesEvents: json['releases_events'] as bool? ?? false,
    tagPushEvents: json['tag_push_events'] as bool? ?? false,
    noteEvents: json['note_events'] as bool? ?? false,
    jobEvents: json['job_events'] as bool? ?? false,
    subgroupEvents: json['subgroup_events'] as bool? ?? false,
    enableSslVerification: json['enable_ssl_verification'] as bool? ?? true,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  final int id;
  final String url;
  final bool pushEvents;
  final bool issuesEvents;
  final bool mergeRequestsEvents;
  final bool pipelineEvents;
  final bool wikiPageEvents;
  final bool deploymentEvents;
  final bool releasesEvents;
  final bool tagPushEvents;
  final bool noteEvents;
  final bool jobEvents;
  final bool subgroupEvents;
  final bool enableSslVerification;
  final DateTime? createdAt;

  /// Enabled event names, for the subtitle line.
  List<String> get eventLabels => [
    if (pushEvents) 'push',
    if (tagPushEvents) 'tag push',
    if (issuesEvents) 'issues',
    if (noteEvents) 'comments',
    if (mergeRequestsEvents) 'merge requests',
    if (pipelineEvents) 'pipeline',
    if (jobEvents) 'job',
    if (subgroupEvents) 'subgroup',
    if (wikiPageEvents) 'wiki',
    if (deploymentEvents) 'deployment',
    if (releasesEvents) 'releases',
  ];

  /// Event name → body key used when creating/editing a hook.
  Map<String, bool> get eventFlags => {
    'push_events': pushEvents,
    'tag_push_events': tagPushEvents,
    'issues_events': issuesEvents,
    'note_events': noteEvents,
    'merge_requests_events': mergeRequestsEvents,
    'pipeline_events': pipelineEvents,
    'job_events': jobEvents,
    'wiki_page_events': wikiPageEvents,
    'deployment_events': deploymentEvents,
    'releases_events': releasesEvents,
  };

  @override
  List<Object?> get props => [id];
}
