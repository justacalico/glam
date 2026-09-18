import 'package:flutter/widgets.dart';
import 'package:glam/l10n/app_localizations.dart';

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
