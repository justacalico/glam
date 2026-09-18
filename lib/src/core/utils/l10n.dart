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
