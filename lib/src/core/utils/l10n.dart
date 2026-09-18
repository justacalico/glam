import 'package:flutter/widgets.dart';
import 'package:glam/l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
