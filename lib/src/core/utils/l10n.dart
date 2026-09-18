import 'package:flutter/widgets.dart';
import 'package:glam/l10n/app_localizations.dart';
import 'package:glam/src/core/api/api_exception.dart';

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
