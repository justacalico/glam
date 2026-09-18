import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Glam'**
  String get appTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get actionRevoke;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errorRequired;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by {title}'**
  String filterBy(String title);

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any {title}'**
  String filterAny(String title);

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTitle;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortRecentlyUpdated;

  /// No description provided for @sortLeastRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Least recently updated'**
  String get sortLeastRecentlyUpdated;

  /// No description provided for @sortDueSoonest.
  ///
  /// In en, this message translates to:
  /// **'Due soonest'**
  String get sortDueSoonest;

  /// No description provided for @sortDueLatest.
  ///
  /// In en, this message translates to:
  /// **'Due latest'**
  String get sortDueLatest;

  /// No description provided for @sortTitleAZ.
  ///
  /// In en, this message translates to:
  /// **'Title A-Z'**
  String get sortTitleAZ;

  /// No description provided for @sortTitleZA.
  ///
  /// In en, this message translates to:
  /// **'Title Z-A'**
  String get sortTitleZA;

  /// No description provided for @composerUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get composerUploadFailed;

  /// No description provided for @composerSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment'**
  String get composerSendFailed;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get composerHint;

  /// No description provided for @composerAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get composerAttach;

  /// No description provided for @listLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed, tap to retry'**
  String get listLoadFailed;

  /// No description provided for @noteActions.
  ///
  /// In en, this message translates to:
  /// **'Comment actions'**
  String get noteActions;

  /// No description provided for @noteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get noteEditTitle;

  /// No description provided for @noteDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get noteDeleteConfirm;

  /// No description provided for @pickerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pickerNone;

  /// No description provided for @pickerSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String pickerSelected(int count);

  /// No description provided for @pickerSearchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members'**
  String get pickerSearchMembers;

  /// No description provided for @pickerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load members. Retry'**
  String get pickerLoadFailed;

  /// No description provided for @pickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get pickerEmpty;

  /// No description provided for @usersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody here yet'**
  String get usersEmpty;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get notificationsLevel;

  /// No description provided for @notifNewNote.
  ///
  /// In en, this message translates to:
  /// **'New comments'**
  String get notifNewNote;

  /// No description provided for @notifNewIssue.
  ///
  /// In en, this message translates to:
  /// **'New issues'**
  String get notifNewIssue;

  /// No description provided for @notifReopenIssue.
  ///
  /// In en, this message translates to:
  /// **'Reopened issues'**
  String get notifReopenIssue;

  /// No description provided for @notifCloseIssue.
  ///
  /// In en, this message translates to:
  /// **'Closed issues'**
  String get notifCloseIssue;

  /// No description provided for @notifReassignIssue.
  ///
  /// In en, this message translates to:
  /// **'Reassigned issues'**
  String get notifReassignIssue;

  /// No description provided for @notifIssueDue.
  ///
  /// In en, this message translates to:
  /// **'Issue due dates'**
  String get notifIssueDue;

  /// No description provided for @notifNewMr.
  ///
  /// In en, this message translates to:
  /// **'New merge requests'**
  String get notifNewMr;

  /// No description provided for @notifPushMr.
  ///
  /// In en, this message translates to:
  /// **'Pushes to merge requests'**
  String get notifPushMr;

  /// No description provided for @notifReopenMr.
  ///
  /// In en, this message translates to:
  /// **'Reopened merge requests'**
  String get notifReopenMr;

  /// No description provided for @notifCloseMr.
  ///
  /// In en, this message translates to:
  /// **'Closed merge requests'**
  String get notifCloseMr;

  /// No description provided for @notifReassignMr.
  ///
  /// In en, this message translates to:
  /// **'Reassigned merge requests'**
  String get notifReassignMr;

  /// No description provided for @notifMergeMr.
  ///
  /// In en, this message translates to:
  /// **'Merged merge requests'**
  String get notifMergeMr;

  /// No description provided for @notifFailedPipeline.
  ///
  /// In en, this message translates to:
  /// **'Failed pipelines'**
  String get notifFailedPipeline;

  /// No description provided for @notifFixedPipeline.
  ///
  /// In en, this message translates to:
  /// **'Fixed pipelines'**
  String get notifFixedPipeline;

  /// No description provided for @notifSuccessPipeline.
  ///
  /// In en, this message translates to:
  /// **'Successful pipelines'**
  String get notifSuccessPipeline;

  /// No description provided for @notifMovedProject.
  ///
  /// In en, this message translates to:
  /// **'Moved project'**
  String get notifMovedProject;

  /// No description provided for @templateUse.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get templateUse;

  /// No description provided for @templateChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get templateChoose;

  /// No description provided for @levelGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global default'**
  String get levelGlobal;

  /// No description provided for @levelWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get levelWatch;

  /// No description provided for @levelParticipating.
  ///
  /// In en, this message translates to:
  /// **'Participate'**
  String get levelParticipating;

  /// No description provided for @levelMention.
  ///
  /// In en, this message translates to:
  /// **'On mention'**
  String get levelMention;

  /// No description provided for @levelDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get levelDisabled;

  /// No description provided for @levelCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get levelCustom;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
