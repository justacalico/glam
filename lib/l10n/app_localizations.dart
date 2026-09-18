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
  String filterBy(Object title);

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any {title}'**
  String filterAny(Object title);

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
  String pickerSelected(Object count);

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

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit events'**
  String get auditEmpty;

  /// No description provided for @auditEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Audit events may require a paid tier.'**
  String get auditEmptyHint;

  /// No description provided for @auditSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get auditSomeone;

  /// No description provided for @auditMadeChange.
  ///
  /// In en, this message translates to:
  /// **'made a change'**
  String get auditMadeChange;

  /// No description provided for @varsTitle.
  ///
  /// In en, this message translates to:
  /// **'CI/CD variables'**
  String get varsTitle;

  /// No description provided for @varsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No variables'**
  String get varsEmpty;

  /// No description provided for @varAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add variable'**
  String get varAddTitle;

  /// No description provided for @varEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit variable'**
  String get varEditTitle;

  /// No description provided for @fieldKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get fieldKey;

  /// No description provided for @fieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fieldValue;

  /// No description provided for @varEnvScope.
  ///
  /// In en, this message translates to:
  /// **'Environment scope'**
  String get varEnvScope;

  /// No description provided for @varProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get varProtected;

  /// No description provided for @varMasked.
  ///
  /// In en, this message translates to:
  /// **'Masked'**
  String get varMasked;

  /// No description provided for @varDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {key}?'**
  String varDeleteConfirm(Object key);

  /// No description provided for @tokensDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Deploy tokens'**
  String get tokensDeployTitle;

  /// No description provided for @tokensDeployEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deploy tokens'**
  String get tokensDeployEmpty;

  /// No description provided for @tokenDeployCreate.
  ///
  /// In en, this message translates to:
  /// **'Create deploy token'**
  String get tokenDeployCreate;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldUsernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get fieldUsernameOptional;

  /// No description provided for @fieldExpiresDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in days (optional)'**
  String get fieldExpiresDays;

  /// No description provided for @errorPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a positive number'**
  String get errorPositiveNumber;

  /// No description provided for @tokenScopeRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one scope'**
  String get tokenScopeRequired;

  /// No description provided for @tokenValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Token \"{name}\"'**
  String tokenValueTitle(Object name);

  /// No description provided for @tokenCopyNow.
  ///
  /// In en, this message translates to:
  /// **'Copy this now. It will not be shown again.'**
  String get tokenCopyNow;

  /// No description provided for @tokenDeployRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke deploy token?'**
  String get tokenDeployRevokeConfirm;

  /// No description provided for @webhooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get webhooksTitle;

  /// No description provided for @webhooksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No webhooks'**
  String get webhooksEmpty;

  /// No description provided for @webhookTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test event sent'**
  String get webhookTestSent;

  /// No description provided for @webhookDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete webhook?'**
  String get webhookDeleteConfirm;

  /// No description provided for @webhookTestSend.
  ///
  /// In en, this message translates to:
  /// **'Send test event'**
  String get webhookTestSend;

  /// No description provided for @hookPushEvents.
  ///
  /// In en, this message translates to:
  /// **'Push events'**
  String get hookPushEvents;

  /// No description provided for @hookTagPush.
  ///
  /// In en, this message translates to:
  /// **'Tag push events'**
  String get hookTagPush;

  /// No description provided for @hookIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get hookIssues;

  /// No description provided for @hookComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get hookComments;

  /// No description provided for @hookMergeRequests.
  ///
  /// In en, this message translates to:
  /// **'Merge requests'**
  String get hookMergeRequests;

  /// No description provided for @hookPipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get hookPipeline;

  /// No description provided for @hookJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get hookJobs;

  /// No description provided for @hookWiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki pages'**
  String get hookWiki;

  /// No description provided for @hookDeployments.
  ///
  /// In en, this message translates to:
  /// **'Deployments'**
  String get hookDeployments;

  /// No description provided for @hookReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get hookReleases;

  /// No description provided for @hookSubgroup.
  ///
  /// In en, this message translates to:
  /// **'Subgroup events'**
  String get hookSubgroup;

  /// No description provided for @webhookAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add webhook'**
  String get webhookAddTitle;

  /// No description provided for @webhookUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get webhookUrl;

  /// No description provided for @webhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret token (optional)'**
  String get webhookSecret;

  /// No description provided for @webhookSsl.
  ///
  /// In en, this message translates to:
  /// **'SSL verification'**
  String get webhookSsl;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @issuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issuesTitle;

  /// No description provided for @mrsTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge requests'**
  String get mrsTitle;

  /// No description provided for @navMrs.
  ///
  /// In en, this message translates to:
  /// **'MRs'**
  String get navMrs;

  /// No description provided for @todosTitle.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get todosTitle;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @snippetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Snippets'**
  String get snippetsTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @dashProjectsSub.
  ///
  /// In en, this message translates to:
  /// **'Browse your work'**
  String get dashProjectsSub;

  /// No description provided for @dashMrsSub.
  ///
  /// In en, this message translates to:
  /// **'Review and merge'**
  String get dashMrsSub;

  /// No description provided for @dashIssuesSub.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get dashIssuesSub;

  /// No description provided for @dashTodosSub.
  ///
  /// In en, this message translates to:
  /// **'Your task list'**
  String get dashTodosSub;

  /// No description provided for @dashSearchSub.
  ///
  /// In en, this message translates to:
  /// **'Across the instance'**
  String get dashSearchSub;

  /// No description provided for @dashActivitySub.
  ///
  /// In en, this message translates to:
  /// **'What happened lately'**
  String get dashActivitySub;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check the instance URL.'**
  String get loginError;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your GitLab instance'**
  String get loginSubtitle;

  /// No description provided for @loginInstanceUrl.
  ///
  /// In en, this message translates to:
  /// **'Instance URL'**
  String get loginInstanceUrl;

  /// No description provided for @loginInstanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your GitLab instance'**
  String get loginInstanceRequired;

  /// No description provided for @loginToken.
  ///
  /// In en, this message translates to:
  /// **'Personal access token'**
  String get loginToken;

  /// No description provided for @loginPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get loginPaste;

  /// No description provided for @loginShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get loginShow;

  /// No description provided for @loginHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get loginHide;

  /// No description provided for @loginTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Paste a personal access token'**
  String get loginTokenRequired;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'Create a token under Preferences, Access Tokens, with the `api` scope.'**
  String get loginTokenHelp;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get fieldPath;

  /// No description provided for @fieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get fieldRole;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get fieldVisibility;

  /// No description provided for @fieldDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get fieldDomain;

  /// No description provided for @roleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get roleGuest;

  /// No description provided for @roleReporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get roleReporter;

  /// No description provided for @roleDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get roleDeveloper;

  /// No description provided for @roleMaintainer.
  ///
  /// In en, this message translates to:
  /// **'Maintainer'**
  String get roleMaintainer;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @visibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibilityPrivate;

  /// No description provided for @visibilityInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get visibilityInternal;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @stateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get stateEnabled;

  /// No description provided for @stateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get stateDisabled;

  /// No description provided for @stateEnabledShort.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get stateEnabledShort;

  /// No description provided for @miscDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get miscDefault;

  /// No description provided for @miscNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get miscNotSet;

  /// No description provided for @miscLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get miscLoading;

  /// No description provided for @miscSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get miscSaving;

  /// No description provided for @miscSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String miscSeconds(Object count);

  /// No description provided for @errorEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get errorEnterNumber;

  /// No description provided for @emptyDefault.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyDefault;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get actionUnpublish;

  /// No description provided for @actionTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get actionTransfer;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get actionUnarchive;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @actionReexport.
  ///
  /// In en, this message translates to:
  /// **'Re-export'**
  String get actionReexport;

  /// No description provided for @actionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get actionNew;

  /// No description provided for @scopeYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get scopeYours;

  /// No description provided for @scopeStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get scopeStarred;

  /// No description provided for @scopeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get scopeExplore;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scopeAll;

  /// No description provided for @sortLastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity'**
  String get sortLastActivity;

  /// No description provided for @sortMostStars.
  ///
  /// In en, this message translates to:
  /// **'Most stars'**
  String get sortMostStars;

  /// No description provided for @sortRecentlyCreated.
  ///
  /// In en, this message translates to:
  /// **'Recently created'**
  String get sortRecentlyCreated;

  /// No description provided for @projectsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get projectsSearchHint;

  /// No description provided for @projectNew.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNew;

  /// No description provided for @searchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get searchClose;

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects'**
  String get projectsEmpty;

  /// No description provided for @projectsEmptyMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String projectsEmptyMatch(Object query);

  /// No description provided for @projectsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Projects you have access to will show up here'**
  String get projectsEmptyHint;

  /// No description provided for @overviewLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get overviewLanguages;

  /// No description provided for @overviewDefaultBranch.
  ///
  /// In en, this message translates to:
  /// **'Default branch'**
  String get overviewDefaultBranch;

  /// No description provided for @overviewCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get overviewCreated;

  /// No description provided for @overviewLastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity'**
  String get overviewLastActivity;

  /// No description provided for @overviewOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get overviewOwner;

  /// No description provided for @overviewForkedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forked from'**
  String get overviewForkedFrom;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabPipelines.
  ///
  /// In en, this message translates to:
  /// **'Pipelines'**
  String get tabPipelines;

  /// No description provided for @tabEnvironments.
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get tabEnvironments;

  /// No description provided for @tabFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get tabFlags;

  /// No description provided for @tabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// No description provided for @tabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tabMembers;

  /// No description provided for @tabForks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get tabForks;

  /// No description provided for @tabContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get tabContributors;

  /// No description provided for @tabPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get tabPackages;

  /// No description provided for @tabRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get tabRegistry;

  /// No description provided for @tabWiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki'**
  String get tabWiki;

  /// No description provided for @tabBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get tabBoards;

  /// No description provided for @tabMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get tabMilestones;

  /// No description provided for @tabLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get tabLabels;

  /// No description provided for @tabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get tabFiles;

  /// No description provided for @tabCommits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get tabCommits;

  /// No description provided for @tabBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get tabBranches;

  /// No description provided for @tabTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tabTags;

  /// No description provided for @tabReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get tabReleases;

  /// No description provided for @starrersTitle.
  ///
  /// In en, this message translates to:
  /// **'Starrers'**
  String get starrersTitle;

  /// No description provided for @actionStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get actionStar;

  /// No description provided for @actionFork.
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get actionFork;

  /// No description provided for @actionCopyCloneUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy clone URL'**
  String get actionCopyCloneUrl;

  /// No description provided for @actionOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get actionOpenBrowser;

  /// No description provided for @snackStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get snackStarred;

  /// No description provided for @snackForked.
  ///
  /// In en, this message translates to:
  /// **'Forked to {path}'**
  String snackForked(Object path);

  /// No description provided for @snackForkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fork the project'**
  String get snackForkFailed;

  /// No description provided for @snackCloneCopied.
  ///
  /// In en, this message translates to:
  /// **'Clone URL copied'**
  String get snackCloneCopied;

  /// No description provided for @contributorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contributors'**
  String get contributorsEmpty;

  /// No description provided for @latestPipeline.
  ///
  /// In en, this message translates to:
  /// **'Latest pipeline'**
  String get latestPipeline;

  /// No description provided for @forksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No forks yet'**
  String get forksEmpty;

  /// No description provided for @projectSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Project settings'**
  String get projectSettingsTitle;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @fieldProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get fieldProjectName;

  /// No description provided for @fieldTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics (comma separated)'**
  String get fieldTopics;

  /// No description provided for @sectionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get sectionFeatures;

  /// No description provided for @sectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get sectionDangerZone;

  /// No description provided for @dangerArchived.
  ///
  /// In en, this message translates to:
  /// **'This project is archived.'**
  String get dangerArchived;

  /// No description provided for @dangerArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Archiving makes the project read-only.'**
  String get dangerArchiveHint;

  /// No description provided for @dangerTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Move the project to another namespace.'**
  String get dangerTransferHint;

  /// No description provided for @dangerDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Deleting removes the project and its repository.'**
  String get dangerDeleteHint;

  /// No description provided for @transferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Transfer {name}?'**
  String transferConfirm(Object name);

  /// No description provided for @fieldNewNamespace.
  ///
  /// In en, this message translates to:
  /// **'New namespace'**
  String get fieldNewNamespace;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {path}?'**
  String deleteProjectConfirm(Object path);

  /// No description provided for @deleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the project and its repository. On gitlab.com deletion is delayed; on self-managed it may be immediate.'**
  String get deleteProjectBody;

  /// No description provided for @actionDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get actionDeleteProject;

  /// No description provided for @fieldPathHint.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the name'**
  String get fieldPathHint;

  /// No description provided for @fieldNamespace.
  ///
  /// In en, this message translates to:
  /// **'Namespace'**
  String get fieldNamespace;

  /// No description provided for @namespacePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal namespace'**
  String get namespacePersonal;

  /// No description provided for @initReadme.
  ///
  /// In en, this message translates to:
  /// **'Initialize with a README'**
  String get initReadme;

  /// No description provided for @noProjectAccessTokens.
  ///
  /// In en, this message translates to:
  /// **'No project access tokens'**
  String get noProjectAccessTokens;

  /// No description provided for @createProjectAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Create project access token'**
  String get createProjectAccessToken;

  /// No description provided for @copyThisNowItWillNot.
  ///
  /// In en, this message translates to:
  /// **'Copy this now — it will not be shown again.'**
  String get copyThisNowItWillNot;

  /// No description provided for @revokeAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Revoke access token?'**
  String get revokeAccessToken;

  /// No description provided for @tokenCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Token \"{p0}\"'**
  String tokenCreatedTitle(Object p0);

  /// No description provided for @noApprovalRules.
  ///
  /// In en, this message translates to:
  /// **'No approval rules'**
  String get noApprovalRules;

  /// No description provided for @requiredApprovals.
  ///
  /// In en, this message translates to:
  /// **'Required approvals'**
  String get requiredApprovals;

  /// No description provided for @approvalsRequiredToMerge.
  ///
  /// In en, this message translates to:
  /// **'Approvals required to merge'**
  String get approvalsRequiredToMerge;

  /// No description provided for @ruleName.
  ///
  /// In en, this message translates to:
  /// **'Rule name'**
  String get ruleName;

  /// No description provided for @approvalsRequired.
  ///
  /// In en, this message translates to:
  /// **'Approvals required'**
  String get approvalsRequired;

  /// No description provided for @eligibleApprovers.
  ///
  /// In en, this message translates to:
  /// **'Eligible approvers'**
  String get eligibleApprovers;

  /// No description provided for @deleteApprovalRule.
  ///
  /// In en, this message translates to:
  /// **'Delete approval rule?'**
  String get deleteApprovalRule;

  /// No description provided for @publicPipelines.
  ///
  /// In en, this message translates to:
  /// **'Public pipelines'**
  String get publicPipelines;

  /// No description provided for @autoCancelRedundantPipelines.
  ///
  /// In en, this message translates to:
  /// **'Auto-cancel redundant pipelines'**
  String get autoCancelRedundantPipelines;

  /// No description provided for @forwardDeploymentVariables.
  ///
  /// In en, this message translates to:
  /// **'Forward deployment variables'**
  String get forwardDeploymentVariables;

  /// No description provided for @separateCachesPerBranch.
  ///
  /// In en, this message translates to:
  /// **'Separate caches per branch'**
  String get separateCachesPerBranch;

  /// No description provided for @keepLatestArtifacts.
  ///
  /// In en, this message translates to:
  /// **'Keep latest artifacts'**
  String get keepLatestArtifacts;

  /// No description provided for @jobTimeout.
  ///
  /// In en, this message translates to:
  /// **'Job timeout'**
  String get jobTimeout;

  /// No description provided for @timeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Timeout (seconds)'**
  String get timeoutSeconds;

  /// No description provided for @ciCdConfigPath.
  ///
  /// In en, this message translates to:
  /// **'CI/CD config path'**
  String get ciCdConfigPath;

  /// No description provided for @noDeployKeys.
  ///
  /// In en, this message translates to:
  /// **'No deploy keys'**
  String get noDeployKeys;

  /// No description provided for @addDeployKey.
  ///
  /// In en, this message translates to:
  /// **'Add deploy key'**
  String get addDeployKey;

  /// No description provided for @publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKey;

  /// No description provided for @sshEd25519Aaaa.
  ///
  /// In en, this message translates to:
  /// **'ssh-ed25519 AAAA…'**
  String get sshEd25519Aaaa;

  /// No description provided for @grantWriteAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant write access'**
  String get grantWriteAccess;

  /// No description provided for @removeDeployKey.
  ///
  /// In en, this message translates to:
  /// **'Remove deploy key?'**
  String get removeDeployKey;

  /// No description provided for @openSite.
  ///
  /// In en, this message translates to:
  /// **'Open site'**
  String get openSite;

  /// No description provided for @forceHttps.
  ///
  /// In en, this message translates to:
  /// **'Force HTTPS'**
  String get forceHttps;

  /// No description provided for @redirectAllPagesTrafficToHttps.
  ///
  /// In en, this message translates to:
  /// **'Redirect all Pages traffic to HTTPS'**
  String get redirectAllPagesTrafficToHttps;

  /// No description provided for @uniqueDomain.
  ///
  /// In en, this message translates to:
  /// **'Unique domain'**
  String get uniqueDomain;

  /// No description provided for @serveThisSiteOnAUnique.
  ///
  /// In en, this message translates to:
  /// **'Serve this site on a unique per-deployment domain'**
  String get serveThisSiteOnAUnique;

  /// No description provided for @removeDomain.
  ///
  /// In en, this message translates to:
  /// **'Remove domain'**
  String get removeDomain;

  /// No description provided for @addDomain.
  ///
  /// In en, this message translates to:
  /// **'Add domain'**
  String get addDomain;

  /// No description provided for @unpublishPages.
  ///
  /// In en, this message translates to:
  /// **'Unpublish Pages?'**
  String get unpublishPages;

  /// No description provided for @addPagesDomain.
  ///
  /// In en, this message translates to:
  /// **'Add Pages domain'**
  String get addPagesDomain;

  /// No description provided for @exportProject.
  ///
  /// In en, this message translates to:
  /// **'Export project'**
  String get exportProject;

  /// No description provided for @loadStatusError.
  ///
  /// In en, this message translates to:
  /// **'Could not load status'**
  String get loadStatusError;

  /// No description provided for @removeDomainConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove domain?'**
  String get removeDomainConfirm;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @noIntegrations.
  ///
  /// In en, this message translates to:
  /// **'No integrations'**
  String get noIntegrations;

  /// No description provided for @secretValuesMayAppearMaskedFields.
  ///
  /// In en, this message translates to:
  /// **'Secret values may appear masked. Fields you do not change are left as they are.'**
  String get secretValuesMayAppearMaskedFields;

  /// No description provided for @mergeMethod.
  ///
  /// In en, this message translates to:
  /// **'Merge method'**
  String get mergeMethod;

  /// No description provided for @squashCommits.
  ///
  /// In en, this message translates to:
  /// **'Squash commits'**
  String get squashCommits;

  /// No description provided for @pipelinesMustSucceed.
  ///
  /// In en, this message translates to:
  /// **'Pipelines must succeed'**
  String get pipelinesMustSucceed;

  /// No description provided for @allowMergeOnSkippedPipelines.
  ///
  /// In en, this message translates to:
  /// **'Allow merge on skipped pipelines'**
  String get allowMergeOnSkippedPipelines;

  /// No description provided for @allThreadsMustBeResolved.
  ///
  /// In en, this message translates to:
  /// **'All threads must be resolved'**
  String get allThreadsMustBeResolved;

  /// No description provided for @deleteSourceBranchAfterMerge.
  ///
  /// In en, this message translates to:
  /// **'Delete source branch after merge'**
  String get deleteSourceBranchAfterMerge;

  /// No description provided for @mergeCommitTemplate.
  ///
  /// In en, this message translates to:
  /// **'Merge commit template'**
  String get mergeCommitTemplate;

  /// No description provided for @squashCommitTemplate.
  ///
  /// In en, this message translates to:
  /// **'Squash commit template'**
  String get squashCommitTemplate;

  /// No description provided for @suggestionCommitMessage.
  ///
  /// In en, this message translates to:
  /// **'Suggestion commit message'**
  String get suggestionCommitMessage;

  /// No description provided for @leaveEmptyToUseTheDefault.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the default'**
  String get leaveEmptyToUseTheDefault;

  /// No description provided for @protectedBranches.
  ///
  /// In en, this message translates to:
  /// **'Protected branches'**
  String get protectedBranches;

  /// No description provided for @protect.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get protect;

  /// No description provided for @noProtectedBranches.
  ///
  /// In en, this message translates to:
  /// **'No protected branches'**
  String get noProtectedBranches;

  /// No description provided for @protectBranch.
  ///
  /// In en, this message translates to:
  /// **'Protect branch'**
  String get protectBranch;

  /// No description provided for @branchOrWildcard.
  ///
  /// In en, this message translates to:
  /// **'Branch or wildcard'**
  String get branchOrWildcard;

  /// No description provided for @mainOrRelease.
  ///
  /// In en, this message translates to:
  /// **'main or release-*'**
  String get mainOrRelease;

  /// No description provided for @allowedToPush.
  ///
  /// In en, this message translates to:
  /// **'Allowed to push'**
  String get allowedToPush;

  /// No description provided for @allowedToMerge.
  ///
  /// In en, this message translates to:
  /// **'Allowed to merge'**
  String get allowedToMerge;

  /// No description provided for @allowForcePush.
  ///
  /// In en, this message translates to:
  /// **'Allow force push'**
  String get allowForcePush;

  /// No description provided for @unprotectBranch.
  ///
  /// In en, this message translates to:
  /// **'Unprotect branch?'**
  String get unprotectBranch;

  /// No description provided for @noOne.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get noOne;

  /// No description provided for @developersMaintainers.
  ///
  /// In en, this message translates to:
  /// **'Developers + maintainers'**
  String get developersMaintainers;

  /// No description provided for @maintainers.
  ///
  /// In en, this message translates to:
  /// **'Maintainers'**
  String get maintainers;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @protectedTags.
  ///
  /// In en, this message translates to:
  /// **'Protected tags'**
  String get protectedTags;

  /// No description provided for @noProtectedTags.
  ///
  /// In en, this message translates to:
  /// **'No protected tags'**
  String get noProtectedTags;

  /// No description provided for @protectTag.
  ///
  /// In en, this message translates to:
  /// **'Protect tag'**
  String get protectTag;

  /// No description provided for @tagOrWildcard.
  ///
  /// In en, this message translates to:
  /// **'Tag or wildcard'**
  String get tagOrWildcard;

  /// No description provided for @v100OrV.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0 or v*'**
  String get v100OrV;

  /// No description provided for @allowedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Allowed to create'**
  String get allowedToCreate;

  /// No description provided for @unprotectTag.
  ///
  /// In en, this message translates to:
  /// **'Unprotect tag?'**
  String get unprotectTag;

  /// No description provided for @protectedEnvironments.
  ///
  /// In en, this message translates to:
  /// **'Protected environments'**
  String get protectedEnvironments;

  /// No description provided for @noProtectedEnvironments.
  ///
  /// In en, this message translates to:
  /// **'No protected environments'**
  String get noProtectedEnvironments;

  /// No description provided for @protectEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Protect environment'**
  String get protectEnvironment;

  /// No description provided for @environmentOrWildcard.
  ///
  /// In en, this message translates to:
  /// **'Environment or wildcard'**
  String get environmentOrWildcard;

  /// No description provided for @productionOrReview.
  ///
  /// In en, this message translates to:
  /// **'production or review/*'**
  String get productionOrReview;

  /// No description provided for @runners.
  ///
  /// In en, this message translates to:
  /// **'Runners'**
  String get runners;

  /// No description provided for @sharedRunners.
  ///
  /// In en, this message translates to:
  /// **'Shared runners'**
  String get sharedRunners;

  /// No description provided for @allowInstanceRunnersToPickUp.
  ///
  /// In en, this message translates to:
  /// **'Allow instance runners to pick up jobs'**
  String get allowInstanceRunnersToPickUp;

  /// No description provided for @groupRunners.
  ///
  /// In en, this message translates to:
  /// **'Group runners'**
  String get groupRunners;

  /// No description provided for @allowGroupRunnersToPickUp.
  ///
  /// In en, this message translates to:
  /// **'Allow group runners to pick up jobs'**
  String get allowGroupRunnersToPickUp;

  /// No description provided for @noRunnersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No runners available'**
  String get noRunnersAvailable;

  /// No description provided for @removeFromProject.
  ///
  /// In en, this message translates to:
  /// **'Remove from project'**
  String get removeFromProject;

  /// No description provided for @removeRunner.
  ///
  /// In en, this message translates to:
  /// **'Remove runner?'**
  String get removeRunner;

  /// No description provided for @secureFiles.
  ///
  /// In en, this message translates to:
  /// **'Secure files'**
  String get secureFiles;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @noSecureFiles.
  ///
  /// In en, this message translates to:
  /// **'No secure files'**
  String get noSecureFiles;

  /// No description provided for @sharedGroups.
  ///
  /// In en, this message translates to:
  /// **'Shared groups'**
  String get sharedGroups;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @notSharedWithAnyGroup.
  ///
  /// In en, this message translates to:
  /// **'Not shared with any group'**
  String get notSharedWithAnyGroup;

  /// No description provided for @noGroupsLeftToShareWith.
  ///
  /// In en, this message translates to:
  /// **'No groups left to share with'**
  String get noGroupsLeftToShareWith;

  /// No description provided for @shareWithGroup.
  ///
  /// In en, this message translates to:
  /// **'Share with group'**
  String get shareWithGroup;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @maxAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'Max access level'**
  String get maxAccessLevel;

  /// No description provided for @removeGroupShare.
  ///
  /// In en, this message translates to:
  /// **'Remove group share?'**
  String get removeGroupShare;

  /// No description provided for @unshare.
  ///
  /// In en, this message translates to:
  /// **'Unshare'**
  String get unshare;

  /// No description provided for @storageMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Storage & maintenance'**
  String get storageMaintenance;

  /// No description provided for @storageStatisticsAreOnlyVisibleTo.
  ///
  /// In en, this message translates to:
  /// **'Storage statistics are only visible to maintainers.'**
  String get storageStatisticsAreOnlyVisibleTo;

  /// No description provided for @housekeepingOptimizesTheRepositoryGcRepack.
  ///
  /// In en, this message translates to:
  /// **'Housekeeping optimizes the repository (gc, repack).'**
  String get housekeepingOptimizesTheRepositoryGcRepack;

  /// No description provided for @runHousekeeping.
  ///
  /// In en, this message translates to:
  /// **'Run housekeeping'**
  String get runHousekeeping;

  /// No description provided for @housekeepingStarted.
  ///
  /// In en, this message translates to:
  /// **'Housekeeping started'**
  String get housekeepingStarted;

  /// No description provided for @pipelineTriggers.
  ///
  /// In en, this message translates to:
  /// **'Pipeline triggers'**
  String get pipelineTriggers;

  /// No description provided for @noTriggers.
  ///
  /// In en, this message translates to:
  /// **'No triggers'**
  String get noTriggers;

  /// No description provided for @deleteTrigger.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger'**
  String get deleteTrigger;

  /// No description provided for @lintGitlabCiYml.
  ///
  /// In en, this message translates to:
  /// **'Lint .gitlab-ci.yml'**
  String get lintGitlabCiYml;

  /// No description provided for @validateCiConfigAgainstThisProject.
  ///
  /// In en, this message translates to:
  /// **'Validate CI config against this project'**
  String get validateCiConfigAgainstThisProject;

  /// No description provided for @newTrigger.
  ///
  /// In en, this message translates to:
  /// **'New trigger'**
  String get newTrigger;

  /// No description provided for @eGDeployWebhook.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deploy webhook'**
  String get eGDeployWebhook;

  /// No description provided for @triggerCreated.
  ///
  /// In en, this message translates to:
  /// **'Trigger created'**
  String get triggerCreated;

  /// No description provided for @useThisTokenToAuthenticateTrigger.
  ///
  /// In en, this message translates to:
  /// **'Use this token to authenticate trigger requests.'**
  String get useThisTokenToAuthenticateTrigger;

  /// No description provided for @tokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Token copied'**
  String get tokenCopied;

  /// No description provided for @lintCiConfig.
  ///
  /// In en, this message translates to:
  /// **'Lint CI config'**
  String get lintCiConfig;

  /// No description provided for @pasteYourGitlabCiYmlHere.
  ///
  /// In en, this message translates to:
  /// **'Paste your .gitlab-ci.yml here'**
  String get pasteYourGitlabCiYmlHere;

  /// No description provided for @lint.
  ///
  /// In en, this message translates to:
  /// **'Lint'**
  String get lint;

  /// No description provided for @deleteNamedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {p0}?'**
  String deleteNamedConfirm(Object p0);

  /// No description provided for @storageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {p0}'**
  String storageTotal(Object p0);

  /// No description provided for @commitCount.
  ///
  /// In en, this message translates to:
  /// **'{p0} commits'**
  String commitCount(Object p0);

  /// No description provided for @storageStatPair.
  ///
  /// In en, this message translates to:
  /// **'{p0} {p1}'**
  String storageStatPair(Object p0, Object p1);

  /// No description provided for @deleteTriggerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger?'**
  String get deleteTriggerConfirm;

  /// No description provided for @lintJobsList.
  ///
  /// In en, this message translates to:
  /// **'Jobs: {p0}'**
  String lintJobsList(Object p0);

  /// No description provided for @auditEvents.
  ///
  /// In en, this message translates to:
  /// **'Audit events'**
  String get auditEvents;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @sshKeys.
  ///
  /// In en, this message translates to:
  /// **'SSH keys'**
  String get sshKeys;

  /// No description provided for @noSshKeys.
  ///
  /// In en, this message translates to:
  /// **'No SSH keys'**
  String get noSshKeys;

  /// No description provided for @addSshKey.
  ///
  /// In en, this message translates to:
  /// **'Add SSH key'**
  String get addSshKey;

  /// No description provided for @removeSshKey.
  ///
  /// In en, this message translates to:
  /// **'Remove SSH key?'**
  String get removeSshKey;

  /// No description provided for @gpgKeys.
  ///
  /// In en, this message translates to:
  /// **'GPG keys'**
  String get gpgKeys;

  /// No description provided for @noGpgKeys.
  ///
  /// In en, this message translates to:
  /// **'No GPG keys'**
  String get noGpgKeys;

  /// No description provided for @addGpgKey.
  ///
  /// In en, this message translates to:
  /// **'Add GPG key'**
  String get addGpgKey;

  /// No description provided for @removeGpgKey.
  ///
  /// In en, this message translates to:
  /// **'Remove GPG key?'**
  String get removeGpgKey;

  /// No description provided for @accessTokens.
  ///
  /// In en, this message translates to:
  /// **'Access tokens'**
  String get accessTokens;

  /// No description provided for @noActiveTokens.
  ///
  /// In en, this message translates to:
  /// **'No active tokens'**
  String get noActiveTokens;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @rotateToken.
  ///
  /// In en, this message translates to:
  /// **'Rotate token?'**
  String get rotateToken;

  /// No description provided for @gitlabDidNotReturnAToken.
  ///
  /// In en, this message translates to:
  /// **'GitLab did not return a token'**
  String get gitlabDidNotReturnAToken;

  /// No description provided for @tokenRotated.
  ///
  /// In en, this message translates to:
  /// **'Token rotated'**
  String get tokenRotated;

  /// No description provided for @revokeToken.
  ///
  /// In en, this message translates to:
  /// **'Revoke token?'**
  String get revokeToken;

  /// No description provided for @emails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get emails;

  /// No description provided for @noEmails.
  ///
  /// In en, this message translates to:
  /// **'No emails'**
  String get noEmails;

  /// No description provided for @addEmail.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @youExampleCom.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get youExampleCom;

  /// No description provided for @removeEmail.
  ///
  /// In en, this message translates to:
  /// **'Remove email?'**
  String get removeEmail;

  /// No description provided for @gitlabPreferences.
  ///
  /// In en, this message translates to:
  /// **'GitLab preferences'**
  String get gitlabPreferences;

  /// No description provided for @newTokenShownOnce.
  ///
  /// In en, this message translates to:
  /// **'New token (shown once):\\n\\n{p0}'**
  String newTokenShownOnce(Object p0);

  /// No description provided for @eventNewComments.
  ///
  /// In en, this message translates to:
  /// **'New comments'**
  String get eventNewComments;

  /// No description provided for @eventNewIssues.
  ///
  /// In en, this message translates to:
  /// **'New issues'**
  String get eventNewIssues;

  /// No description provided for @eventReopenedIssues.
  ///
  /// In en, this message translates to:
  /// **'Reopened issues'**
  String get eventReopenedIssues;

  /// No description provided for @eventClosedIssues.
  ///
  /// In en, this message translates to:
  /// **'Closed issues'**
  String get eventClosedIssues;

  /// No description provided for @eventReassignedIssues.
  ///
  /// In en, this message translates to:
  /// **'Reassigned issues'**
  String get eventReassignedIssues;

  /// No description provided for @eventIssueDueDates.
  ///
  /// In en, this message translates to:
  /// **'Issue due dates'**
  String get eventIssueDueDates;

  /// No description provided for @eventNewMrs.
  ///
  /// In en, this message translates to:
  /// **'New merge requests'**
  String get eventNewMrs;

  /// No description provided for @eventPushesToMrs.
  ///
  /// In en, this message translates to:
  /// **'Pushes to merge requests'**
  String get eventPushesToMrs;

  /// No description provided for @eventReopenedMrs.
  ///
  /// In en, this message translates to:
  /// **'Reopened merge requests'**
  String get eventReopenedMrs;

  /// No description provided for @eventClosedMrs.
  ///
  /// In en, this message translates to:
  /// **'Closed merge requests'**
  String get eventClosedMrs;

  /// No description provided for @eventReassignedMrs.
  ///
  /// In en, this message translates to:
  /// **'Reassigned merge requests'**
  String get eventReassignedMrs;

  /// No description provided for @eventMergedMrs.
  ///
  /// In en, this message translates to:
  /// **'Merged merge requests'**
  String get eventMergedMrs;

  /// No description provided for @eventFailedPipelines.
  ///
  /// In en, this message translates to:
  /// **'Failed pipelines'**
  String get eventFailedPipelines;

  /// No description provided for @eventFixedPipelines.
  ///
  /// In en, this message translates to:
  /// **'Fixed pipelines'**
  String get eventFixedPipelines;

  /// No description provided for @eventSuccessfulPipelines.
  ///
  /// In en, this message translates to:
  /// **'Successful pipelines'**
  String get eventSuccessfulPipelines;

  /// No description provided for @eventMovedProjects.
  ///
  /// In en, this message translates to:
  /// **'Moved projects'**
  String get eventMovedProjects;

  /// No description provided for @eventNewEpics.
  ///
  /// In en, this message translates to:
  /// **'New epics'**
  String get eventNewEpics;

  /// No description provided for @gpgKeyId.
  ///
  /// In en, this message translates to:
  /// **'GPG key #{p0}'**
  String gpgKeyId(Object p0);

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get noAlerts;

  /// No description provided for @alertsFromPrometheusAndOtherTools.
  ///
  /// In en, this message translates to:
  /// **'Alerts from Prometheus and other tools appear here.'**
  String get alertsFromPrometheusAndOtherTools;

  /// No description provided for @setStatus.
  ///
  /// In en, this message translates to:
  /// **'Set status'**
  String get setStatus;

  /// No description provided for @linkedIssueP0.
  ///
  /// In en, this message translates to:
  /// **'Linked issue #{p0}'**
  String linkedIssueP0(Object p0);

  /// No description provided for @alertTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get alertTool;

  /// No description provided for @alertService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get alertService;

  /// No description provided for @alertStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get alertStarted;

  /// No description provided for @alertEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get alertEnded;

  /// No description provided for @alertEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get alertEvents;

  /// No description provided for @alertHosts.
  ///
  /// In en, this message translates to:
  /// **'Hosts'**
  String get alertHosts;

  /// No description provided for @fieldAssignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get fieldAssignees;

  /// No description provided for @noBoards.
  ///
  /// In en, this message translates to:
  /// **'No boards'**
  String get noBoards;

  /// No description provided for @newBoard.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get newBoard;

  /// No description provided for @boardActions.
  ///
  /// In en, this message translates to:
  /// **'Board actions'**
  String get boardActions;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @issuesStayOnTheProjectOnly.
  ///
  /// In en, this message translates to:
  /// **'Issues stay on the project; only the board goes.'**
  String get issuesStayOnTheProjectOnly;

  /// No description provided for @thisBoardHasNoLists.
  ///
  /// In en, this message translates to:
  /// **'This board has no lists'**
  String get thisBoardHasNoLists;

  /// No description provided for @addList.
  ///
  /// In en, this message translates to:
  /// **'Add list'**
  String get addList;

  /// No description provided for @noLabelsOnThisProject.
  ///
  /// In en, this message translates to:
  /// **'No labels on this project.'**
  String get noLabelsOnThisProject;

  /// No description provided for @issuesKeepTheirLabelOnlyThe.
  ///
  /// In en, this message translates to:
  /// **'Issues keep their label; only the column goes.'**
  String get issuesKeepTheirLabelOnlyThe;

  /// No description provided for @listActions.
  ///
  /// In en, this message translates to:
  /// **'List actions'**
  String get listActions;

  /// No description provided for @removeList.
  ///
  /// In en, this message translates to:
  /// **'Remove list'**
  String get removeList;

  /// No description provided for @noIssues.
  ///
  /// In en, this message translates to:
  /// **'No issues'**
  String get noIssues;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @editBoard.
  ///
  /// In en, this message translates to:
  /// **'Edit board'**
  String get editBoard;

  /// No description provided for @milestoneScope.
  ///
  /// In en, this message translates to:
  /// **'Milestone scope'**
  String get milestoneScope;

  /// No description provided for @noMilestone.
  ///
  /// In en, this message translates to:
  /// **'No milestone'**
  String get noMilestone;

  /// No description provided for @labelScope.
  ///
  /// In en, this message translates to:
  /// **'Label scope'**
  String get labelScope;

  /// No description provided for @bugFrontend.
  ///
  /// In en, this message translates to:
  /// **'bug, frontend'**
  String get bugFrontend;

  /// No description provided for @weightScope.
  ///
  /// In en, this message translates to:
  /// **'Weight scope'**
  String get weightScope;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @newEnvironment.
  ///
  /// In en, this message translates to:
  /// **'New environment'**
  String get newEnvironment;

  /// No description provided for @noEnvironments.
  ///
  /// In en, this message translates to:
  /// **'No environments'**
  String get noEnvironments;

  /// No description provided for @deploymentsToStagingProductionEtc.
  ///
  /// In en, this message translates to:
  /// **'Deployments to staging, production, etc.'**
  String get deploymentsToStagingProductionEtc;

  /// No description provided for @externalUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'External URL (optional)'**
  String get externalUrlOptional;

  /// No description provided for @openLiveEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Open live environment'**
  String get openLiveEnvironment;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @deleteEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Delete environment'**
  String get deleteEnvironment;

  /// No description provided for @stoppedEnvironmentsCanBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Stopped environments can be deleted.'**
  String get stoppedEnvironmentsCanBeDeleted;

  /// No description provided for @issueIid.
  ///
  /// In en, this message translates to:
  /// **'#{p0}'**
  String issueIid(Object p0);

  /// No description provided for @removeNamedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {p0}?'**
  String removeNamedConfirm(Object p0);

  /// No description provided for @deploymentRef.
  ///
  /// In en, this message translates to:
  /// **'#{p0} {p1} · {p2}'**
  String deploymentRef(Object p0, Object p1, Object p2);

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @editEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Edit environment'**
  String get editEnvironment;

  /// No description provided for @openLiveUrl.
  ///
  /// In en, this message translates to:
  /// **'Open live URL'**
  String get openLiveUrl;

  /// No description provided for @copyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get copyUrl;

  /// No description provided for @noDeploymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No deployments yet'**
  String get noDeploymentsYet;

  /// No description provided for @userLists.
  ///
  /// In en, this message translates to:
  /// **'User lists'**
  String get userLists;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @noFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'No feature flags'**
  String get noFeatureFlags;

  /// No description provided for @theFlagIsRemovedFromEvery.
  ///
  /// In en, this message translates to:
  /// **'The flag is removed from every environment.'**
  String get theFlagIsRemovedFromEvery;

  /// No description provided for @noUserLists.
  ///
  /// In en, this message translates to:
  /// **'No user lists'**
  String get noUserLists;

  /// No description provided for @flagStrategiesUsingItStopMatching.
  ///
  /// In en, this message translates to:
  /// **'Flag strategies using it stop matching.'**
  String get flagStrategiesUsingItStopMatching;

  /// No description provided for @userIds.
  ///
  /// In en, this message translates to:
  /// **'User IDs'**
  String get userIds;

  /// No description provided for @userListSummary.
  ///
  /// In en, this message translates to:
  /// **'{p0} {p1} · {p2}'**
  String userListSummary(Object p0, Object p1, Object p2);

  /// No description provided for @userSingular.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get userSingular;

  /// No description provided for @userPlural.
  ///
  /// In en, this message translates to:
  /// **'users'**
  String get userPlural;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @noGroupsFound.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroupsFound;

  /// No description provided for @searchThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Search this group'**
  String get searchThisGroup;

  /// No description provided for @groupActions.
  ///
  /// In en, this message translates to:
  /// **'Group actions'**
  String get groupActions;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @subgroups.
  ///
  /// In en, this message translates to:
  /// **'Subgroups'**
  String get subgroups;

  /// No description provided for @iterations.
  ///
  /// In en, this message translates to:
  /// **'Iterations'**
  String get iterations;

  /// No description provided for @variables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get variables;

  /// No description provided for @tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get tokens;

  /// No description provided for @audit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get audit;

  /// No description provided for @noProjectsInThisGroup.
  ///
  /// In en, this message translates to:
  /// **'No projects in this group'**
  String get noProjectsInThisGroup;

  /// No description provided for @noProjectsSharedWithThisGroup.
  ///
  /// In en, this message translates to:
  /// **'No projects shared with this group'**
  String get noProjectsSharedWithThisGroup;

  /// No description provided for @noIterations.
  ///
  /// In en, this message translates to:
  /// **'No iterations'**
  String get noIterations;

  /// No description provided for @iterationsNeedAPremiumGroupWith.
  ///
  /// In en, this message translates to:
  /// **'Iterations need a Premium group with a cadence.'**
  String get iterationsNeedAPremiumGroupWith;

  /// No description provided for @noSubgroups.
  ///
  /// In en, this message translates to:
  /// **'No subgroups'**
  String get noSubgroups;

  /// No description provided for @noMergeRequests.
  ///
  /// In en, this message translates to:
  /// **'No merge requests'**
  String get noMergeRequests;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get deleteGroupConfirm;

  /// No description provided for @deleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the group and all of its subgroups and content. This cannot be undone.'**
  String get deleteGroupBody;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get searchProjects;

  /// No description provided for @searchIssues.
  ///
  /// In en, this message translates to:
  /// **'Search issues'**
  String get searchIssues;

  /// No description provided for @searchMrs.
  ///
  /// In en, this message translates to:
  /// **'Search merge requests'**
  String get searchMrs;

  /// No description provided for @stateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get stateOpen;

  /// No description provided for @stateClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stateClosed;

  /// No description provided for @stateAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get stateAll;

  /// No description provided for @stateMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get stateMerged;

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchGroups;

  /// No description provided for @parentGroup.
  ///
  /// In en, this message translates to:
  /// **'Parent group'**
  String get parentGroup;

  /// No description provided for @topLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get topLevel;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMember;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitations;

  /// No description provided for @accessRequests.
  ///
  /// In en, this message translates to:
  /// **'Access requests'**
  String get accessRequests;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @invitedGroups.
  ///
  /// In en, this message translates to:
  /// **'Invited groups'**
  String get invitedGroups;

  /// No description provided for @planner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get planner;

  /// No description provided for @thatGroupLosesAccessToThis.
  ///
  /// In en, this message translates to:
  /// **'That group loses access to this one.'**
  String get thatGroupLosesAccessToThis;

  /// No description provided for @makeP0.
  ///
  /// In en, this message translates to:
  /// **'Make {p0}'**
  String makeP0(Object p0);

  /// No description provided for @theyLoseP0Access.
  ///
  /// In en, this message translates to:
  /// **'They lose {p0} access.'**
  String theyLoseP0Access(Object p0);

  /// No description provided for @usernameUserIdOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username, user id, or email'**
  String get usernameUserIdOrEmail;

  /// No description provided for @jane42OrJaneExampleCom.
  ///
  /// In en, this message translates to:
  /// **'jane, 42, or jane@example.com'**
  String get jane42OrJaneExampleCom;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @memberDisplay.
  ///
  /// In en, this message translates to:
  /// **'{p0} @{p1}'**
  String memberDisplay(Object p0, Object p1);

  /// No description provided for @rolePlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get rolePlanner;

  /// No description provided for @roleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get roleMinimal;

  /// No description provided for @roleLevelOther.
  ///
  /// In en, this message translates to:
  /// **'Level {p0}'**
  String roleLevelOther(Object p0);

  /// No description provided for @expiresDate.
  ///
  /// In en, this message translates to:
  /// **'expires {p0}'**
  String expiresDate(Object p0);

  /// No description provided for @memberIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Username, user id, or email is required'**
  String get memberIdentifierRequired;

  /// No description provided for @memberAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the member'**
  String get memberAddFailed;

  /// No description provided for @noExpiration.
  ///
  /// In en, this message translates to:
  /// **'No expiration'**
  String get noExpiration;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {p0}'**
  String expiresOn(Object p0);

  /// No description provided for @projectWord.
  ///
  /// In en, this message translates to:
  /// **'project'**
  String get projectWord;

  /// No description provided for @groupWord.
  ///
  /// In en, this message translates to:
  /// **'group'**
  String get groupWord;

  /// No description provided for @linkedIssues.
  ///
  /// In en, this message translates to:
  /// **'Linked issues'**
  String get linkedIssues;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @noLinkedIssues.
  ///
  /// In en, this message translates to:
  /// **'No linked issues'**
  String get noLinkedIssues;

  /// No description provided for @linkIssue.
  ///
  /// In en, this message translates to:
  /// **'Link issue'**
  String get linkIssue;

  /// No description provided for @projectOptional.
  ///
  /// In en, this message translates to:
  /// **'Project (optional)'**
  String get projectOptional;

  /// No description provided for @groupOtherProject.
  ///
  /// In en, this message translates to:
  /// **'group/other-project'**
  String get groupOtherProject;

  /// No description provided for @linkType.
  ///
  /// In en, this message translates to:
  /// **'Link type'**
  String get linkType;

  /// No description provided for @relatesTo.
  ///
  /// In en, this message translates to:
  /// **'Relates to'**
  String get relatesTo;

  /// No description provided for @blocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get blocks;

  /// No description provided for @blockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by'**
  String get blockedBy;

  /// No description provided for @removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link?'**
  String get removeLink;

  /// No description provided for @unlinkP0FromThisIssue.
  ///
  /// In en, this message translates to:
  /// **'Unlink #{p0} from this issue.'**
  String unlinkP0FromThisIssue(Object p0);

  /// No description provided for @relatedMergeRequests.
  ///
  /// In en, this message translates to:
  /// **'Related merge requests'**
  String get relatedMergeRequests;

  /// No description provided for @willBeClosedBy.
  ///
  /// In en, this message translates to:
  /// **'Will be closed by'**
  String get willBeClosedBy;

  /// No description provided for @noRelatedMergeRequests.
  ///
  /// In en, this message translates to:
  /// **'No related merge requests'**
  String get noRelatedMergeRequests;

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{p0}'**
  String moreCount(Object p0);

  /// No description provided for @linkSummary.
  ///
  /// In en, this message translates to:
  /// **'{p0} · {p1}'**
  String linkSummary(Object p0, Object p1);

  /// No description provided for @issueIidField.
  ///
  /// In en, this message translates to:
  /// **'Issue #'**
  String get issueIidField;

  /// No description provided for @removeLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get removeLinkTooltip;

  /// No description provided for @markdownSupported.
  ///
  /// In en, this message translates to:
  /// **'Markdown supported'**
  String get markdownSupported;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @confidential.
  ///
  /// In en, this message translates to:
  /// **'Confidential'**
  String get confidential;

  /// No description provided for @onlyVisibleToMembersAndAssignees.
  ///
  /// In en, this message translates to:
  /// **'Only visible to members and assignees'**
  String get onlyVisibleToMembersAndAssignees;

  /// No description provided for @createIssue.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get createIssue;

  /// No description provided for @moveIssue.
  ///
  /// In en, this message translates to:
  /// **'Move issue'**
  String get moveIssue;

  /// No description provided for @destinationProject.
  ///
  /// In en, this message translates to:
  /// **'Destination project'**
  String get destinationProject;

  /// No description provided for @groupProject.
  ///
  /// In en, this message translates to:
  /// **'group/project'**
  String get groupProject;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @issueWeight.
  ///
  /// In en, this message translates to:
  /// **'Issue weight'**
  String get issueWeight;

  /// No description provided for @emptyClearsTheWeight.
  ///
  /// In en, this message translates to:
  /// **'Empty clears the weight'**
  String get emptyClearsTheWeight;

  /// No description provided for @enterAWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get enterAWholeNumber;

  /// No description provided for @timeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Time estimate'**
  String get timeEstimate;

  /// No description provided for @addTimeSpent.
  ///
  /// In en, this message translates to:
  /// **'Add time spent'**
  String get addTimeSpent;

  /// No description provided for @closeIssue.
  ///
  /// In en, this message translates to:
  /// **'Close issue'**
  String get closeIssue;

  /// No description provided for @reopenIssue.
  ///
  /// In en, this message translates to:
  /// **'Reopen issue'**
  String get reopenIssue;

  /// No description provided for @unsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribe;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @setTimeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Set time estimate'**
  String get setTimeEstimate;

  /// No description provided for @resetTimeSpent.
  ///
  /// In en, this message translates to:
  /// **'Reset time spent'**
  String get resetTimeSpent;

  /// No description provided for @setWeight.
  ///
  /// In en, this message translates to:
  /// **'Set weight'**
  String get setWeight;

  /// No description provided for @cloneIssue.
  ///
  /// In en, this message translates to:
  /// **'Clone issue'**
  String get cloneIssue;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @issueDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {p0}'**
  String issueDueDate(Object p0);

  /// No description provided for @issueWeightValue.
  ///
  /// In en, this message translates to:
  /// **'Weight {p0}'**
  String issueWeightValue(Object p0);

  /// No description provided for @enterProjectPath.
  ///
  /// In en, this message translates to:
  /// **'Enter a project path'**
  String get enterProjectPath;

  /// No description provided for @closedByName.
  ///
  /// In en, this message translates to:
  /// **'Closed by {p0}'**
  String closedByName(Object p0);

  /// No description provided for @tasksStatus.
  ///
  /// In en, this message translates to:
  /// **'Tasks {p0}'**
  String tasksStatus(Object p0);

  /// No description provided for @openedByAt.
  ///
  /// In en, this message translates to:
  /// **'{p0} opened {p1}'**
  String openedByAt(Object p0, Object p1);

  /// No description provided for @timeSpentOf.
  ///
  /// In en, this message translates to:
  /// **'{p0} spent of {p1}'**
  String timeSpentOf(Object p0, Object p1);

  /// No description provided for @runPipeline.
  ///
  /// In en, this message translates to:
  /// **'Run pipeline'**
  String get runPipeline;

  /// No description provided for @noPipelinesForThisMr.
  ///
  /// In en, this message translates to:
  /// **'No pipelines for this MR'**
  String get noPipelinesForThisMr;

  /// No description provided for @relatedMergeRequestP0.
  ///
  /// In en, this message translates to:
  /// **'Related merge request{p0}'**
  String relatedMergeRequestP0(Object p0);

  /// No description provided for @closesIssues.
  ///
  /// In en, this message translates to:
  /// **'Closes {p0} issue{p1}'**
  String closesIssues(Object p0, Object p1);

  /// No description provided for @mrTileDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft: '**
  String get mrTileDraft;

  /// No description provided for @sourceBranch.
  ///
  /// In en, this message translates to:
  /// **'Source branch'**
  String get sourceBranch;

  /// No description provided for @targetBranch.
  ///
  /// In en, this message translates to:
  /// **'Target branch'**
  String get targetBranch;

  /// No description provided for @reviewers.
  ///
  /// In en, this message translates to:
  /// **'Reviewers'**
  String get reviewers;

  /// No description provided for @createMr.
  ///
  /// In en, this message translates to:
  /// **'Create MR'**
  String get createMr;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @mrPickBranches.
  ///
  /// In en, this message translates to:
  /// **'Pick a source and target branch'**
  String get mrPickBranches;

  /// No description provided for @mrSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the merge request'**
  String get mrSaveFailed;

  /// No description provided for @editMr.
  ///
  /// In en, this message translates to:
  /// **'Edit merge request'**
  String get editMr;

  /// No description provided for @newMr.
  ///
  /// In en, this message translates to:
  /// **'New merge request'**
  String get newMr;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply…'**
  String get replyHint;

  /// No description provided for @actionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get actionReply;

  /// No description provided for @changes.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changes;

  /// No description provided for @loadMoreFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Load more failed. Retry'**
  String get loadMoreFailedRetry;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @scheduledToMergeWhenThePipeline.
  ///
  /// In en, this message translates to:
  /// **'Scheduled to merge when the pipeline succeeds'**
  String get scheduledToMergeWhenThePipeline;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @revokeApproval.
  ///
  /// In en, this message translates to:
  /// **'Revoke approval'**
  String get revokeApproval;

  /// No description provided for @cancelAutoMerge.
  ///
  /// In en, this message translates to:
  /// **'Cancel auto-merge'**
  String get cancelAutoMerge;

  /// No description provided for @mergeWhenPipelineSucceeds.
  ///
  /// In en, this message translates to:
  /// **'Merge when pipeline succeeds'**
  String get mergeWhenPipelineSucceeds;

  /// No description provided for @mergeP0.
  ///
  /// In en, this message translates to:
  /// **'Merge !{p0}'**
  String mergeP0(Object p0);

  /// No description provided for @deleteSourceBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete source branch'**
  String get deleteSourceBranch;

  /// No description provided for @mergesAutomaticallyOnceThePipelineSucceeds.
  ///
  /// In en, this message translates to:
  /// **'Merges automatically once the pipeline succeeds.'**
  String get mergesAutomaticallyOnceThePipelineSucceeds;

  /// No description provided for @setAutoMerge.
  ///
  /// In en, this message translates to:
  /// **'Set auto-merge'**
  String get setAutoMerge;

  /// No description provided for @closeMr.
  ///
  /// In en, this message translates to:
  /// **'Close MR'**
  String get closeMr;

  /// No description provided for @reopenMr.
  ///
  /// In en, this message translates to:
  /// **'Reopen MR'**
  String get reopenMr;

  /// No description provided for @markAsReady.
  ///
  /// In en, this message translates to:
  /// **'Mark as ready'**
  String get markAsReady;

  /// No description provided for @markAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Mark as draft'**
  String get markAsDraft;

  /// No description provided for @rebase.
  ///
  /// In en, this message translates to:
  /// **'Rebase'**
  String get rebase;

  /// No description provided for @cherryPick.
  ///
  /// In en, this message translates to:
  /// **'Cherry-pick'**
  String get cherryPick;

  /// No description provided for @revert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get revert;

  /// No description provided for @downloadPatch.
  ///
  /// In en, this message translates to:
  /// **'Download patch'**
  String get downloadPatch;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get noChanges;

  /// No description provided for @latestChanges.
  ///
  /// In en, this message translates to:
  /// **'Latest changes'**
  String get latestChanges;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review?'**
  String get submitReview;

  /// No description provided for @allPendingCommentsBecomeVisible.
  ///
  /// In en, this message translates to:
  /// **'All pending comments become visible.'**
  String get allPendingCommentsBecomeVisible;

  /// No description provided for @publishAll.
  ///
  /// In en, this message translates to:
  /// **'Publish all'**
  String get publishAll;

  /// No description provided for @noPendingComments.
  ///
  /// In en, this message translates to:
  /// **'No pending comments.'**
  String get noPendingComments;

  /// No description provided for @binaryFileOrDiffTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Binary file or diff too large'**
  String get binaryFileOrDiffTooLarge;

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get writeAComment;

  /// No description provided for @addToReview.
  ///
  /// In en, this message translates to:
  /// **'Add to review'**
  String get addToReview;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @missingDiffRefsRefreshTheMr.
  ///
  /// In en, this message translates to:
  /// **'Missing diff refs. Refresh the MR and try again.'**
  String get missingDiffRefsRefreshTheMr;

  /// No description provided for @noCommits.
  ///
  /// In en, this message translates to:
  /// **'No commits'**
  String get noCommits;

  /// No description provided for @contextCommits.
  ///
  /// In en, this message translates to:
  /// **'Context commits'**
  String get contextCommits;

  /// No description provided for @mrIid.
  ///
  /// In en, this message translates to:
  /// **'!{p0}'**
  String mrIid(Object p0);

  /// No description provided for @branchArrow.
  ///
  /// In en, this message translates to:
  /// **'{p0} → {p1}'**
  String branchArrow(Object p0, Object p1);

  /// No description provided for @projectMrRef.
  ///
  /// In en, this message translates to:
  /// **'{p0} !{p1}'**
  String projectMrRef(Object p0, Object p1);

  /// No description provided for @deletionsCount.
  ///
  /// In en, this message translates to:
  /// **'-{p0}'**
  String deletionsCount(Object p0);

  /// No description provided for @mergedByAt.
  ///
  /// In en, this message translates to:
  /// **'Merged by {p0} {p1}'**
  String mergedByAt(Object p0, Object p1);

  /// No description provided for @pendingComments.
  ///
  /// In en, this message translates to:
  /// **'{p0} pending comment{p1} in your review'**
  String pendingComments(Object p0, Object p1);

  /// No description provided for @versionEntry.
  ///
  /// In en, this message translates to:
  /// **'Version {p0} · {p1} · {p2} file{p3}'**
  String versionEntry(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @commentOnLine.
  ///
  /// In en, this message translates to:
  /// **'Comment on {p0}:{p1}'**
  String commentOnLine(Object p0, Object p1);

  /// No description provided for @searchMilestones.
  ///
  /// In en, this message translates to:
  /// **'Search milestones'**
  String get searchMilestones;

  /// No description provided for @newMilestone.
  ///
  /// In en, this message translates to:
  /// **'New milestone'**
  String get newMilestone;

  /// No description provided for @noMilestones.
  ///
  /// In en, this message translates to:
  /// **'No milestones'**
  String get noMilestones;

  /// No description provided for @milestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestone;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @createMilestone.
  ///
  /// In en, this message translates to:
  /// **'Create milestone'**
  String get createMilestone;

  /// No description provided for @searchLabels.
  ///
  /// In en, this message translates to:
  /// **'Search labels'**
  String get searchLabels;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get newLabel;

  /// No description provided for @noLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels'**
  String get noLabels;

  /// No description provided for @p0Issues.
  ///
  /// In en, this message translates to:
  /// **'{p0} issues'**
  String p0Issues(Object p0);

  /// No description provided for @promoteToGroup.
  ///
  /// In en, this message translates to:
  /// **'Promote to group'**
  String get promoteToGroup;

  /// No description provided for @promoteP0.
  ///
  /// In en, this message translates to:
  /// **'Promote {p0}?'**
  String promoteP0(Object p0);

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promote;

  /// No description provided for @theLabelIsRemovedFromEvery.
  ///
  /// In en, this message translates to:
  /// **'The label is removed from every issue and MR.'**
  String get theLabelIsRemovedFromEvery;

  /// No description provided for @bugOrPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'bug or priority::high'**
  String get bugOrPriorityHigh;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create label'**
  String get createLabel;

  /// No description provided for @labelPromoteBody.
  ///
  /// In en, this message translates to:
  /// **'The label moves to the parent group and is replaced on every issue and MR that uses it.'**
  String get labelPromoteBody;

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {p0}'**
  String startsOn(Object p0);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {p0}'**
  String dueOn(Object p0);

  /// No description provided for @milestoneSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the milestone'**
  String get milestoneSaveFailed;

  /// No description provided for @editMilestone.
  ///
  /// In en, this message translates to:
  /// **'Edit milestone'**
  String get editMilestone;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @labelSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the label'**
  String get labelSaveFailed;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get editLabel;

  /// No description provided for @labelPreview.
  ///
  /// In en, this message translates to:
  /// **'Label preview'**
  String get labelPreview;

  /// No description provided for @stateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stateActive;

  /// No description provided for @runs.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runs;

  /// No description provided for @schedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedules;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @ref.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get ref;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @noPipelinesYet.
  ///
  /// In en, this message translates to:
  /// **'No pipelines yet'**
  String get noPipelinesYet;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs'**
  String get noJobs;

  /// No description provided for @ciLint.
  ///
  /// In en, this message translates to:
  /// **'CI lint'**
  String get ciLint;

  /// No description provided for @stagesNBuild.
  ///
  /// In en, this message translates to:
  /// **'stages:\\n  - build'**
  String get stagesNBuild;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @p0Jobs.
  ///
  /// In en, this message translates to:
  /// **'{p0} jobs'**
  String p0Jobs(Object p0);

  /// No description provided for @pipelineStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get pipelineStatusRunning;

  /// No description provided for @pipelineStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pipelineStatusPending;

  /// No description provided for @pipelineStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get pipelineStatusSuccess;

  /// No description provided for @pipelineStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get pipelineStatusFailed;

  /// No description provided for @pipelineStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get pipelineStatusCanceled;

  /// No description provided for @pipelineStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get pipelineStatusSkipped;

  /// No description provided for @pipelineStatusManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get pipelineStatusManual;

  /// No description provided for @pipelineSourcePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get pipelineSourcePush;

  /// No description provided for @pipelineSourceWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get pipelineSourceWeb;

  /// No description provided for @pipelineSourceSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get pipelineSourceSchedule;

  /// No description provided for @pipelineSourceApi.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get pipelineSourceApi;

  /// No description provided for @pipelineSourceTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get pipelineSourceTrigger;

  /// No description provided for @pipelineSourceMr.
  ///
  /// In en, this message translates to:
  /// **'Merge request'**
  String get pipelineSourceMr;

  /// No description provided for @pipelineSourcePipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get pipelineSourcePipeline;

  /// No description provided for @pipelineSourceChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get pipelineSourceChat;

  /// No description provided for @newSchedule.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get newSchedule;

  /// No description provided for @noScheduledPipelines.
  ///
  /// In en, this message translates to:
  /// **'No scheduled pipelines'**
  String get noScheduledPipelines;

  /// No description provided for @recentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get recentRuns;

  /// No description provided for @runNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get runNow;

  /// No description provided for @takeOwnership.
  ///
  /// In en, this message translates to:
  /// **'Take ownership'**
  String get takeOwnership;

  /// No description provided for @scheduleTriggered.
  ///
  /// In en, this message translates to:
  /// **'Schedule triggered'**
  String get scheduleTriggered;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule?'**
  String get deleteSchedule;

  /// No description provided for @noRunsYet.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get noRunsYet;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get editSchedule;

  /// No description provided for @targetRef.
  ///
  /// In en, this message translates to:
  /// **'Target ref'**
  String get targetRef;

  /// No description provided for @cron.
  ///
  /// In en, this message translates to:
  /// **'Cron'**
  String get cron;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @utc.
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get utc;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get key;

  /// No description provided for @artifactsJobP0.
  ///
  /// In en, this message translates to:
  /// **'Artifacts · job #{p0}'**
  String artifactsJobP0(Object p0);

  /// No description provided for @archiveIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get archiveIsEmpty;

  /// No description provided for @binaryFileUseShareToSave.
  ///
  /// In en, this message translates to:
  /// **'Binary file — use Share to save it.'**
  String get binaryFileUseShareToSave;

  /// No description provided for @quotedName.
  ///
  /// In en, this message translates to:
  /// **'\"{p0}\"'**
  String quotedName(Object p0);

  /// No description provided for @scheduleId.
  ///
  /// In en, this message translates to:
  /// **'Schedule #{p0}'**
  String scheduleId(Object p0);

  /// No description provided for @pickTargetRef.
  ///
  /// In en, this message translates to:
  /// **'Pick a target ref'**
  String get pickTargetRef;

  /// No description provided for @varKeysUnique.
  ///
  /// In en, this message translates to:
  /// **'Variable keys must be unique'**
  String get varKeysUnique;

  /// No description provided for @scheduleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the schedule'**
  String get scheduleSaveFailed;

  /// No description provided for @scheduleStopsRunning.
  ///
  /// In en, this message translates to:
  /// **'\"{p0}\" stops running.'**
  String scheduleStopsRunning(Object p0);

  /// No description provided for @jobP0.
  ///
  /// In en, this message translates to:
  /// **'Job #{p0}'**
  String jobP0(Object p0);

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @browseArtifacts.
  ///
  /// In en, this message translates to:
  /// **'Browse artifacts'**
  String get browseArtifacts;

  /// No description provided for @keepArtifacts.
  ///
  /// In en, this message translates to:
  /// **'Keep artifacts'**
  String get keepArtifacts;

  /// No description provided for @byP0.
  ///
  /// In en, this message translates to:
  /// **'by {p0}'**
  String byP0(Object p0);

  /// No description provided for @copyTrace.
  ///
  /// In en, this message translates to:
  /// **'Copy trace'**
  String get copyTrace;

  /// No description provided for @pipelineP0.
  ///
  /// In en, this message translates to:
  /// **'Pipeline #{p0}'**
  String pipelineP0(Object p0);

  /// No description provided for @stages.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stages;

  /// No description provided for @tests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tests;

  /// No description provided for @downstream.
  ///
  /// In en, this message translates to:
  /// **'Downstream'**
  String get downstream;

  /// No description provided for @noJobsInThisPipeline.
  ///
  /// In en, this message translates to:
  /// **'No jobs in this pipeline'**
  String get noJobsInThisPipeline;

  /// No description provided for @allowedToFail.
  ///
  /// In en, this message translates to:
  /// **'allowed to fail'**
  String get allowedToFail;

  /// No description provided for @noTestReport.
  ///
  /// In en, this message translates to:
  /// **'No test report'**
  String get noTestReport;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @thisPipelineRanWithoutExtraVariables.
  ///
  /// In en, this message translates to:
  /// **'This pipeline ran without extra variables.'**
  String get thisPipelineRanWithoutExtraVariables;

  /// No description provided for @noDownstreamPipelines.
  ///
  /// In en, this message translates to:
  /// **'No downstream pipelines'**
  String get noDownstreamPipelines;

  /// No description provided for @thisPipelineDidNotTriggerAny.
  ///
  /// In en, this message translates to:
  /// **'This pipeline did not trigger any child pipelines.'**
  String get thisPipelineDidNotTriggerAny;

  /// No description provided for @statText.
  ///
  /// In en, this message translates to:
  /// **'{p0} {p1}{p2}'**
  String statText(Object p0, Object p1, Object p2);

  /// No description provided for @durationInSecs.
  ///
  /// In en, this message translates to:
  /// **'in {p0}s'**
  String durationInSecs(Object p0);

  /// No description provided for @secsValue.
  ///
  /// In en, this message translates to:
  /// **'{p0}s'**
  String secsValue(Object p0);

  /// No description provided for @refAtSha.
  ///
  /// In en, this message translates to:
  /// **'{p0} @ {p1}'**
  String refAtSha(Object p0, Object p1);

  /// No description provided for @eraseJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase job?'**
  String get eraseJobConfirm;

  /// No description provided for @deleteArtifactsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete artifacts?'**
  String get deleteArtifactsConfirm;

  /// No description provided for @deleteArtifactsAction.
  ///
  /// In en, this message translates to:
  /// **'Delete artifacts'**
  String get deleteArtifactsAction;

  /// No description provided for @eraseJobAction.
  ///
  /// In en, this message translates to:
  /// **'Erase job'**
  String get eraseJobAction;

  /// No description provided for @hideRetriedJobs.
  ///
  /// In en, this message translates to:
  /// **'Hide retried jobs'**
  String get hideRetriedJobs;

  /// No description provided for @showRetriedJobs.
  ///
  /// In en, this message translates to:
  /// **'Show retried jobs'**
  String get showRetriedJobs;

  /// No description provided for @runManualJob.
  ///
  /// In en, this message translates to:
  /// **'Run manual job'**
  String get runManualJob;

  /// No description provided for @eraseJobBody.
  ///
  /// In en, this message translates to:
  /// **'The trace and artifacts are permanently removed.'**
  String get eraseJobBody;

  /// No description provided for @deleteArtifactsBody.
  ///
  /// In en, this message translates to:
  /// **'Locked artifacts may remain. Requires a maintainer role.'**
  String get deleteArtifactsBody;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @joinedP0.
  ///
  /// In en, this message translates to:
  /// **'Joined {p0}'**
  String joinedP0(Object p0);

  /// No description provided for @p0Followers.
  ///
  /// In en, this message translates to:
  /// **'{p0} followers'**
  String p0Followers(Object p0);

  /// No description provided for @p0Following.
  ///
  /// In en, this message translates to:
  /// **'{p0} following'**
  String p0Following(Object p0);

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @p0ContributionsInTheLastYear.
  ///
  /// In en, this message translates to:
  /// **'{p0} contributions in the last year'**
  String p0ContributionsInTheLastYear(Object p0);

  /// No description provided for @statusEmoji.
  ///
  /// In en, this message translates to:
  /// **'Status emoji'**
  String get statusEmoji;

  /// No description provided for @eG.
  ///
  /// In en, this message translates to:
  /// **'e.g. 🌴'**
  String get eG;

  /// No description provided for @statusMessage.
  ///
  /// In en, this message translates to:
  /// **'Status message'**
  String get statusMessage;

  /// No description provided for @memberships.
  ///
  /// In en, this message translates to:
  /// **'Memberships'**
  String get memberships;

  /// No description provided for @fieldPronouns.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get fieldPronouns;

  /// No description provided for @fieldJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get fieldJobTitle;

  /// No description provided for @fieldOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get fieldOrganization;

  /// No description provided for @fieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// No description provided for @fieldPublicEmail.
  ///
  /// In en, this message translates to:
  /// **'Public email'**
  String get fieldPublicEmail;

  /// No description provided for @fieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get fieldWebsite;

  /// No description provided for @fieldTwitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get fieldTwitter;

  /// No description provided for @fieldLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get fieldLinkedin;

  /// No description provided for @fieldBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get fieldBio;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @searchPackages.
  ///
  /// In en, this message translates to:
  /// **'Search packages'**
  String get searchPackages;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @noPackages.
  ///
  /// In en, this message translates to:
  /// **'No packages'**
  String get noPackages;

  /// No description provided for @deletePackage.
  ///
  /// In en, this message translates to:
  /// **'Delete package?'**
  String get deletePackage;

  /// No description provided for @p0IsRemovedPermanently.
  ///
  /// In en, this message translates to:
  /// **'\"{p0}\" is removed permanently.'**
  String p0IsRemovedPermanently(Object p0);

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @noContainerImages.
  ///
  /// In en, this message translates to:
  /// **'No container images'**
  String get noContainerImages;

  /// No description provided for @deleteRepository.
  ///
  /// In en, this message translates to:
  /// **'Delete repository?'**
  String get deleteRepository;

  /// No description provided for @p0AndAllItsTagsAre.
  ///
  /// In en, this message translates to:
  /// **'\"{p0}\" and all its tags are removed.'**
  String p0AndAllItsTagsAre(Object p0);

  /// No description provided for @filterTagsRegex.
  ///
  /// In en, this message translates to:
  /// **'Filter tags (regex)'**
  String get filterTagsRegex;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get deleteTag;

  /// No description provided for @emptyDirectory.
  ///
  /// In en, this message translates to:
  /// **'Empty directory'**
  String get emptyDirectory;

  /// No description provided for @downloadSource.
  ///
  /// In en, this message translates to:
  /// **'Download source'**
  String get downloadSource;

  /// No description provided for @newFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFile;

  /// No description provided for @switchBranch.
  ///
  /// In en, this message translates to:
  /// **'Switch branch'**
  String get switchBranch;

  /// No description provided for @editFile.
  ///
  /// In en, this message translates to:
  /// **'Edit file'**
  String get editFile;

  /// No description provided for @copyContents.
  ///
  /// In en, this message translates to:
  /// **'Copy contents'**
  String get copyContents;

  /// No description provided for @fileHistory.
  ///
  /// In en, this message translates to:
  /// **'File history'**
  String get fileHistory;

  /// No description provided for @viewBlame.
  ///
  /// In en, this message translates to:
  /// **'View blame'**
  String get viewBlame;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFile;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @aCommitRemovingThisFileWill.
  ///
  /// In en, this message translates to:
  /// **'A commit removing this file will be created.'**
  String get aCommitRemovingThisFileWill;

  /// No description provided for @editP0.
  ///
  /// In en, this message translates to:
  /// **'Edit {p0}'**
  String editP0(Object p0);

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @commit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commit;

  /// No description provided for @filePath.
  ///
  /// In en, this message translates to:
  /// **'File path'**
  String get filePath;

  /// No description provided for @commitMessage.
  ///
  /// In en, this message translates to:
  /// **'Commit message'**
  String get commitMessage;

  /// No description provided for @fileContents.
  ///
  /// In en, this message translates to:
  /// **'File contents'**
  String get fileContents;

  /// No description provided for @commitsToP0.
  ///
  /// In en, this message translates to:
  /// **'Commits to {p0}'**
  String commitsToP0(Object p0);

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'No templates'**
  String get noTemplates;

  /// No description provided for @searchBranches.
  ///
  /// In en, this message translates to:
  /// **'Search branches'**
  String get searchBranches;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @deleteMerged.
  ///
  /// In en, this message translates to:
  /// **'Delete merged'**
  String get deleteMerged;

  /// No description provided for @newBranch.
  ///
  /// In en, this message translates to:
  /// **'New branch'**
  String get newBranch;

  /// No description provided for @noBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get noBranches;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @sourceRefBranchTagOrSha.
  ///
  /// In en, this message translates to:
  /// **'Source ref (branch, tag, or sha)'**
  String get sourceRefBranchTagOrSha;

  /// No description provided for @deleteMergedBranches.
  ///
  /// In en, this message translates to:
  /// **'Delete merged branches?'**
  String get deleteMergedBranches;

  /// No description provided for @deleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get deleteBranch;

  /// No description provided for @deleteMergedBody.
  ///
  /// In en, this message translates to:
  /// **'Every branch already merged into the default branch is removed. Protected branches are kept.'**
  String get deleteMergedBody;

  /// No description provided for @templateGitignore.
  ///
  /// In en, this message translates to:
  /// **'Gitignore'**
  String get templateGitignore;

  /// No description provided for @templateLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get templateLicense;

  /// No description provided for @templateGitlabCi.
  ///
  /// In en, this message translates to:
  /// **'GitLab CI'**
  String get templateGitlabCi;

  /// No description provided for @templateDockerfile.
  ///
  /// In en, this message translates to:
  /// **'Dockerfile'**
  String get templateDockerfile;
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
