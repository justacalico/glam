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
  String varDeleteConfirm(String key);

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
  String tokenValueTitle(String name);

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
  String miscSeconds(int count);

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
  String projectsEmptyMatch(String query);

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
  String snackForked(String path);

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
  String transferConfirm(String name);

  /// No description provided for @fieldNewNamespace.
  ///
  /// In en, this message translates to:
  /// **'New namespace'**
  String get fieldNewNamespace;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {path}?'**
  String deleteProjectConfirm(String path);

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
  String lintJobsList(String p0);
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
