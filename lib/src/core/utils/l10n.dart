import 'package:flutter/widgets.dart';
import 'package:glam/l10n/app_localizations.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/models/iteration.dart';
import 'package:glam/src/core/models/shared_group.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/data/issues_repository.dart';
import 'package:glam/src/features/merge_requests/data/merge_requests_repository.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

export 'package:glam/l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Display names for notification levels, keyed the same way as
/// `NotificationSettings.levelLabels`.
extension NotificationLevelL10n on AppLocalizations {
  String notificationLevel(String key) => switch (key) {
    'watch' => levelWatch,
    'participating' => levelParticipating,
    'mention' => levelMention,
    'disabled' => levelDisabled,
    'custom' => levelCustom,
    _ => levelGlobal,
  };
}

/// Labels for the top-level nav destinations, keyed by route path.
extension NavLabelL10n on AppLocalizations {
  String navLabel(String path) => switch (path) {
    '/home' => homeTitle,
    '/projects' => projectsTitle,
    '/issues' => issuesTitle,
    '/merge-requests' => navMrs,
    '/todos' => todosTitle,
    '/activity' => activityTitle,
    '/groups' => groupsTitle,
    '/snippets' => snippetsTitle,
    '/search' => searchTitle,
    '/settings' => settingsTitle,
    _ => homeTitle,
  };
}

/// Labels for the projects-list scope chips, keyed by `ProjectScope.name`.
extension ProjectScopeL10n on AppLocalizations {
  String projectScope(String name) => switch (name) {
    'starred' => scopeStarred,
    'explored' => scopeExplore,
    'all' => scopeAll,
    _ => scopeYours,
  };
}

/// Labels for `ProjectSort`, keyed by enum name.
extension ProjectSortL10n on AppLocalizations {
  String projectSort(String name) => switch (name) {
    'name' => fieldName,
    'stars' => sortMostStars,
    'created' => sortRecentlyCreated,
    'oldest' => sortOldest,
    _ => sortLastActivity,
  };
}

/// Labels for GitLab member access levels.
extension AccessLevelL10n on AppLocalizations {
  String accessLevelName(int level) => switch (level) {
    10 => roleGuest,
    15 => rolePlanner,
    20 => roleReporter,
    30 => roleDeveloper,
    40 => roleMaintainer,
    50 => roleOwner,
    _ => roleLevelOther(level),
  };
}

/// Export status labels keyed on the API status slug.
extension ExportStatusL10n on AppLocalizations {
  String exportStatus(String status) => switch (status) {
    'finished' => exportReady,
    'queued' => exportQueued,
    'started' => exportRunning,
    'regeneration_in_progress' => exportRegenerating,
    'failed' => exportFailed,
    _ => exportNone,
  };
}

/// Runner status labels keyed on the API status slug.
extension RunnerStatusL10n on AppLocalizations {
  String runnerStatus(String status) => switch (status) {
    'online' => runnerOnline,
    'offline' => runnerOffline,
    'stale' => runnerStale,
    'never_contacted' => runnerNeverContacted,
    _ => status.isEmpty ? statusUnknown : status,
  };
}

/// Protected-branch/tag/environment access level labels.
extension ProtectedLevelL10n on AppLocalizations {
  String protectedLevel(int level) => switch (level) {
    0 => noOne,
    30 => developersMaintainers,
    40 => maintainers,
    60 => admins,
    _ => roleLevelOther(level),
  };
}

/// Webhook event labels keyed on the event slug.
extension WebhookEventL10n on AppLocalizations {
  String webhookEvent(String slug) => switch (slug) {
    'push' => hookEventPush,
    'tag push' => hookEventTagPush,
    'issues' => hookEventIssues,
    'comments' => hookEventComments,
    'merge requests' => hookEventMrs,
    'pipeline' => hookEventPipeline,
    'job' => hookEventJob,
    'subgroup' => hookEventSubgroup,
    _ => slug,
  };
}

/// Localized text for [ApiException] display. Server-supplied and custom
/// messages pass through untouched; client defaults resolve per kind.
extension ApiExceptionL10n on ApiException {
  String displayMessage(AppLocalizations l10n) {
    if (!isDefaultMessage) return message;
    return switch (messageKey) {
      ApiMessageKey.fileTooLarge => l10n.errFileTooLarge,
      ApiMessageKey.tooManyRedirects => l10n.errTooManyRedirects,
      ApiMessageKey.badArchive => l10n.errBadArchive,
      ApiMessageKey.none => switch (kind) {
        ApiErrorKind.network => l10n.errNetwork,
        ApiErrorKind.unauthorized => l10n.errUnauthorized,
        ApiErrorKind.forbidden => l10n.errForbidden,
        ApiErrorKind.notFound => l10n.errNotFound,
        ApiErrorKind.conflict => l10n.errConflict,
        ApiErrorKind.server => l10n.errServer,
        ApiErrorKind.unknown => l10n.errUnknown,
      },
    };
  }
}

/// Localized board list titles — system lists localize, label lists keep
/// their label name.
extension BoardListL10n on BoardList {
  String displayTitle(AppLocalizations l10n) => switch (listType) {
    'backlog' => l10n.stateOpen,
    'closed' => l10n.stateClosed,
    _ => title,
  };
}

/// Localized labels for the global issue-list scope segmented control.
extension IssueScopeL10n on AppLocalizations {
  String issueScopeLabel(IssueScope scope) => switch (scope) {
    IssueScope.assigned => issueScopeAssigned,
    IssueScope.created => issueScopeCreated,
    IssueScope.all => stateAll,
  };
}

/// Localized labels for the global MR-list scope segmented control.
extension MrScopeL10n on AppLocalizations {
  String mrScopeLabel(MrScope scope) => switch (scope) {
    MrScope.all => stateAll,
    MrScope.assigned => mrScopeAssigned,
    MrScope.created => mrScopeCreated,
    MrScope.review => mrScopeReview,
  };
}

/// Localized notification reasons — unknown reasons fall back to the raw
/// API value with underscores stripped.
extension NotificationReasonL10n on AppLocalizations {
  String notificationReason(String reason) => switch (reason) {
    'assigned' => dashIssuesSub,
    'mentioned' => reasonMentioned,
    'review_requested' => mrScopeReview,
    'approval_required' => reasonApprovalRequired,
    'build_failed' => reasonBuildFailed,
    'marked' => reasonMarked,
    'subscribed' => reasonSubscribed,
    _ => reason.replaceAll('_', ' '),
  };
}

/// Localized runner kind labels.
extension RunnerTypeL10n on AppLocalizations {
  String runnerTypeLabel(String runnerType) => switch (runnerType) {
    'instance_type' => shared,
    'group_type' => group,
    _ => runnerProjectType,
  };
}

/// Localized merge-readiness hint, mirroring `MergeRequest.mergeabilityLabel`.
extension MergeabilityL10n on MergeRequest {
  String mergeabilityText(AppLocalizations l10n) =>
      switch (detailedMergeStatus) {
        'mergeable' => l10n.mrReadyToMerge,
        'broken_status' || 'not_open' => l10n.mrCannotMerge,
        'conflict' => l10n.mrHasConflicts,
        'need_rebase' => l10n.mrNeedsRebase,
        'ci_must_pass' || 'ci_still_running' => l10n.mrPipelineMustPass,
        'discussions_not_resolved' => l10n.mrUnresolvedDiscussions,
        'draft_status' => l10n.draft,
        'not_approved' => l10n.mrNeedsApproval,
        'blocked_status' => l10n.mrBlocked,
        'external_status_checks' => l10n.mrWaitingOnStatusChecks,
        'checking' || 'unchecked' => l10n.checking,
        _ =>
          mergeStatus == 'can_be_merged'
              ? l10n.mrReadyToMerge
              : l10n.statusUnknown,
      };
}

/// Localized issue-link type labels.
extension IssueLinkL10n on AppLocalizations {
  String issueLinkType(String linkType) => switch (linkType) {
    'blocks' => blocks,
    'is_blocked_by' => blockedBy,
    _ => relatesTo,
  };
}

/// Localized search-scope labels, keyed by the API scope name.
extension SearchScopeL10n on AppLocalizations {
  String searchScopeLabel(String apiName) => switch (apiName) {
    'projects' => projectsTitle,
    'issues' => issuesTitle,
    'merge_requests' => navMrs,
    'commits' => commitsTitle,
    'blobs' => searchScopeCode,
    'wiki_blobs' => tabWiki,
    'notes' => hookComments,
    'milestones' => tabMilestones,
    'users' => searchScopeUsers,
    'snippet_titles' => snippetsTitle,
    _ => searchScopeSnippetCode,
  };
}

/// Iteration display label — title or date range pass through, the iid
/// fallback localizes.
extension IterationL10n on Iteration {
  String localizedLabel(AppLocalizations l10n) =>
      label.startsWith('Iteration ') ? l10n.iterationN(iid) : label;
}

/// Shared-group display name — the numeric fallback localizes.
extension SharedGroupL10n on SharedGroup {
  String localizedName(AppLocalizations l10n) =>
      groupFullPath ?? groupName ?? l10n.groupN(groupId);
}
