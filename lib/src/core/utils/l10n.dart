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
