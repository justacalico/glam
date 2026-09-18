// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Glam';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionOk => 'OK';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionRevoke => 'Revoke';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get errorRequired => 'Required';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String filterBy(String title) {
    return 'Filter by $title';
  }

  @override
  String filterAny(String title) {
    return 'Any $title';
  }

  @override
  String get sortTitle => 'Sort';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortRecentlyUpdated => 'Recently updated';

  @override
  String get sortLeastRecentlyUpdated => 'Least recently updated';

  @override
  String get sortDueSoonest => 'Due soonest';

  @override
  String get sortDueLatest => 'Due latest';

  @override
  String get sortTitleAZ => 'Title A-Z';

  @override
  String get sortTitleZA => 'Title Z-A';

  @override
  String get composerUploadFailed => 'Failed to upload file';

  @override
  String get composerSendFailed => 'Failed to post comment';

  @override
  String get composerHint => 'Write a comment';

  @override
  String get composerAttach => 'Attach a file';

  @override
  String get listLoadFailed => 'Load failed, tap to retry';

  @override
  String get noteActions => 'Comment actions';

  @override
  String get noteEditTitle => 'Edit comment';

  @override
  String get noteDeleteConfirm => 'Delete comment?';

  @override
  String get pickerNone => 'None';

  @override
  String pickerSelected(int count) {
    return '$count selected';
  }

  @override
  String get pickerSearchMembers => 'Search members';

  @override
  String get pickerLoadFailed => 'Could not load members. Retry';

  @override
  String get pickerEmpty => 'No members found';

  @override
  String get usersEmpty => 'Nobody here yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsLevel => 'Level';

  @override
  String get notifNewNote => 'New comments';

  @override
  String get notifNewIssue => 'New issues';

  @override
  String get notifReopenIssue => 'Reopened issues';

  @override
  String get notifCloseIssue => 'Closed issues';

  @override
  String get notifReassignIssue => 'Reassigned issues';

  @override
  String get notifIssueDue => 'Issue due dates';

  @override
  String get notifNewMr => 'New merge requests';

  @override
  String get notifPushMr => 'Pushes to merge requests';

  @override
  String get notifReopenMr => 'Reopened merge requests';

  @override
  String get notifCloseMr => 'Closed merge requests';

  @override
  String get notifReassignMr => 'Reassigned merge requests';

  @override
  String get notifMergeMr => 'Merged merge requests';

  @override
  String get notifFailedPipeline => 'Failed pipelines';

  @override
  String get notifFixedPipeline => 'Fixed pipelines';

  @override
  String get notifSuccessPipeline => 'Successful pipelines';

  @override
  String get notifMovedProject => 'Moved project';

  @override
  String get templateUse => 'Use template';

  @override
  String get templateChoose => 'Choose a template';

  @override
  String get levelGlobal => 'Global default';

  @override
  String get levelWatch => 'Watch';

  @override
  String get levelParticipating => 'Participate';

  @override
  String get levelMention => 'On mention';

  @override
  String get levelDisabled => 'Disabled';

  @override
  String get levelCustom => 'Custom';
}
