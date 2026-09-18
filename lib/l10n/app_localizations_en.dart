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

  @override
  String get auditEmpty => 'No audit events';

  @override
  String get auditEmptyHint => 'Audit events may require a paid tier.';

  @override
  String get auditSomeone => 'Someone';

  @override
  String get auditMadeChange => 'made a change';

  @override
  String get varsTitle => 'CI/CD variables';

  @override
  String get varsEmpty => 'No variables';

  @override
  String get varAddTitle => 'Add variable';

  @override
  String get varEditTitle => 'Edit variable';

  @override
  String get fieldKey => 'Key';

  @override
  String get fieldValue => 'Value';

  @override
  String get varEnvScope => 'Environment scope';

  @override
  String get varProtected => 'Protected';

  @override
  String get varMasked => 'Masked';

  @override
  String varDeleteConfirm(String key) {
    return 'Delete $key?';
  }

  @override
  String get tokensDeployTitle => 'Deploy tokens';

  @override
  String get tokensDeployEmpty => 'No deploy tokens';

  @override
  String get tokenDeployCreate => 'Create deploy token';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldUsernameOptional => 'Username (optional)';

  @override
  String get fieldExpiresDays => 'Expires in days (optional)';

  @override
  String get errorPositiveNumber => 'Must be a positive number';

  @override
  String get tokenScopeRequired => 'Pick at least one scope';

  @override
  String tokenValueTitle(String name) {
    return 'Token \"$name\"';
  }

  @override
  String get tokenCopyNow => 'Copy this now. It will not be shown again.';

  @override
  String get tokenDeployRevokeConfirm => 'Revoke deploy token?';

  @override
  String get webhooksTitle => 'Webhooks';

  @override
  String get webhooksEmpty => 'No webhooks';

  @override
  String get webhookTestSent => 'Test event sent';

  @override
  String get webhookDeleteConfirm => 'Delete webhook?';

  @override
  String get webhookTestSend => 'Send test event';

  @override
  String get hookPushEvents => 'Push events';

  @override
  String get hookTagPush => 'Tag push events';

  @override
  String get hookIssues => 'Issues';

  @override
  String get hookComments => 'Comments';

  @override
  String get hookMergeRequests => 'Merge requests';

  @override
  String get hookPipeline => 'Pipeline';

  @override
  String get hookJobs => 'Jobs';

  @override
  String get hookWiki => 'Wiki pages';

  @override
  String get hookDeployments => 'Deployments';

  @override
  String get hookReleases => 'Releases';

  @override
  String get hookSubgroup => 'Subgroup events';

  @override
  String get webhookAddTitle => 'Add webhook';

  @override
  String get webhookUrl => 'URL';

  @override
  String get webhookSecret => 'Secret token (optional)';

  @override
  String get webhookSsl => 'SSL verification';

  @override
  String get homeTitle => 'Home';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get issuesTitle => 'Issues';

  @override
  String get mrsTitle => 'Merge requests';

  @override
  String get navMrs => 'MRs';

  @override
  String get todosTitle => 'To-dos';

  @override
  String get activityTitle => 'Activity';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get snippetsTitle => 'Snippets';

  @override
  String get searchTitle => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get dashProjectsSub => 'Browse your work';

  @override
  String get dashMrsSub => 'Review and merge';

  @override
  String get dashIssuesSub => 'Assigned to you';

  @override
  String get dashTodosSub => 'Your task list';

  @override
  String get dashSearchSub => 'Across the instance';

  @override
  String get dashActivitySub => 'What happened lately';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get loginError => 'Could not sign in. Check the instance URL.';

  @override
  String get loginSubtitle => 'Sign in to your GitLab instance';

  @override
  String get loginInstanceUrl => 'Instance URL';

  @override
  String get loginInstanceRequired => 'Enter your GitLab instance';

  @override
  String get loginToken => 'Personal access token';

  @override
  String get loginPaste => 'Paste';

  @override
  String get loginShow => 'Show';

  @override
  String get loginHide => 'Hide';

  @override
  String get loginTokenRequired => 'Paste a personal access token';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginTokenHelp =>
      'Create a token under Preferences, Access Tokens, with the `api` scope.';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldPath => 'Path';

  @override
  String get fieldRole => 'Role';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldVisibility => 'Visibility';

  @override
  String get fieldDomain => 'Domain';

  @override
  String get roleGuest => 'Guest';

  @override
  String get roleReporter => 'Reporter';

  @override
  String get roleDeveloper => 'Developer';

  @override
  String get roleMaintainer => 'Maintainer';

  @override
  String get roleOwner => 'Owner';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get visibilityInternal => 'Internal';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get stateEnabled => 'Enabled';

  @override
  String get stateDisabled => 'Disabled';

  @override
  String get stateEnabledShort => 'Enabled';

  @override
  String get miscDefault => 'Default';

  @override
  String get miscNotSet => 'Not set';

  @override
  String get miscLoading => 'Loading…';

  @override
  String get miscSaving => 'Saving…';

  @override
  String miscSeconds(int count) {
    return '$count seconds';
  }

  @override
  String get errorEnterNumber => 'Enter a number';

  @override
  String get emptyDefault => 'Nothing here yet';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionUnpublish => 'Unpublish';

  @override
  String get actionTransfer => 'Transfer';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Unarchive';

  @override
  String get actionExport => 'Export';

  @override
  String get actionReexport => 'Re-export';

  @override
  String get actionNew => 'New';

  @override
  String get scopeYours => 'Yours';

  @override
  String get scopeStarred => 'Starred';

  @override
  String get scopeExplore => 'Explore';

  @override
  String get scopeAll => 'All';

  @override
  String get sortLastActivity => 'Last activity';

  @override
  String get sortMostStars => 'Most stars';

  @override
  String get sortRecentlyCreated => 'Recently created';

  @override
  String get projectsSearchHint => 'Search projects';

  @override
  String get projectNew => 'New project';

  @override
  String get searchClose => 'Close search';

  @override
  String get projectsEmpty => 'No projects';

  @override
  String projectsEmptyMatch(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String get projectsEmptyHint =>
      'Projects you have access to will show up here';

  @override
  String get overviewLanguages => 'Languages';

  @override
  String get overviewDefaultBranch => 'Default branch';

  @override
  String get overviewCreated => 'Created';

  @override
  String get overviewLastActivity => 'Last activity';

  @override
  String get overviewOwner => 'Owner';

  @override
  String get overviewForkedFrom => 'Forked from';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabPipelines => 'Pipelines';

  @override
  String get tabEnvironments => 'Environments';

  @override
  String get tabFlags => 'Flags';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabMembers => 'Members';

  @override
  String get tabForks => 'Forks';

  @override
  String get tabContributors => 'Contributors';

  @override
  String get tabPackages => 'Packages';

  @override
  String get tabRegistry => 'Registry';

  @override
  String get tabWiki => 'Wiki';

  @override
  String get tabBoards => 'Boards';

  @override
  String get tabMilestones => 'Milestones';

  @override
  String get tabLabels => 'Labels';

  @override
  String get tabFiles => 'Files';

  @override
  String get tabCommits => 'Commits';

  @override
  String get tabBranches => 'Branches';

  @override
  String get tabTags => 'Tags';

  @override
  String get tabReleases => 'Releases';

  @override
  String get starrersTitle => 'Starrers';

  @override
  String get actionStar => 'Star';

  @override
  String get actionFork => 'Fork';

  @override
  String get actionCopyCloneUrl => 'Copy clone URL';

  @override
  String get actionOpenBrowser => 'Open in browser';

  @override
  String get snackStarred => 'Starred';

  @override
  String snackForked(String path) {
    return 'Forked to $path';
  }

  @override
  String get snackForkFailed => 'Could not fork the project';

  @override
  String get snackCloneCopied => 'Clone URL copied';

  @override
  String get contributorsEmpty => 'No contributors';

  @override
  String get latestPipeline => 'Latest pipeline';

  @override
  String get forksEmpty => 'No forks yet';

  @override
  String get projectSettingsTitle => 'Project settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get sectionGeneral => 'General';

  @override
  String get fieldProjectName => 'Project name';

  @override
  String get fieldTopics => 'Topics (comma separated)';

  @override
  String get sectionFeatures => 'Features';

  @override
  String get sectionDangerZone => 'Danger zone';

  @override
  String get dangerArchived => 'This project is archived.';

  @override
  String get dangerArchiveHint => 'Archiving makes the project read-only.';

  @override
  String get dangerTransferHint => 'Move the project to another namespace.';

  @override
  String get dangerDeleteHint =>
      'Deleting removes the project and its repository.';

  @override
  String transferConfirm(String name) {
    return 'Transfer $name?';
  }

  @override
  String get fieldNewNamespace => 'New namespace';

  @override
  String deleteProjectConfirm(String path) {
    return 'Delete $path?';
  }

  @override
  String get deleteProjectBody =>
      'This deletes the project and its repository. On gitlab.com deletion is delayed; on self-managed it may be immediate.';

  @override
  String get actionDeleteProject => 'Delete project';

  @override
  String get fieldPathHint => 'Defaults to the name';

  @override
  String get fieldNamespace => 'Namespace';

  @override
  String get namespacePersonal => 'Personal namespace';

  @override
  String get initReadme => 'Initialize with a README';

  @override
  String get noProjectAccessTokens => 'No project access tokens';

  @override
  String get createProjectAccessToken => 'Create project access token';

  @override
  String get copyThisNowItWillNot =>
      'Copy this now — it will not be shown again.';

  @override
  String get revokeAccessToken => 'Revoke access token?';

  @override
  String tokenCreatedTitle(Object p0) {
    return 'Token \"$p0\"';
  }

  @override
  String get noApprovalRules => 'No approval rules';

  @override
  String get requiredApprovals => 'Required approvals';

  @override
  String get approvalsRequiredToMerge => 'Approvals required to merge';

  @override
  String get ruleName => 'Rule name';

  @override
  String get approvalsRequired => 'Approvals required';

  @override
  String get eligibleApprovers => 'Eligible approvers';

  @override
  String get deleteApprovalRule => 'Delete approval rule?';

  @override
  String get publicPipelines => 'Public pipelines';

  @override
  String get autoCancelRedundantPipelines => 'Auto-cancel redundant pipelines';

  @override
  String get forwardDeploymentVariables => 'Forward deployment variables';

  @override
  String get separateCachesPerBranch => 'Separate caches per branch';

  @override
  String get keepLatestArtifacts => 'Keep latest artifacts';

  @override
  String get jobTimeout => 'Job timeout';

  @override
  String get timeoutSeconds => 'Timeout (seconds)';

  @override
  String get ciCdConfigPath => 'CI/CD config path';

  @override
  String get noDeployKeys => 'No deploy keys';

  @override
  String get addDeployKey => 'Add deploy key';

  @override
  String get publicKey => 'Public key';

  @override
  String get sshEd25519Aaaa => 'ssh-ed25519 AAAA…';

  @override
  String get grantWriteAccess => 'Grant write access';

  @override
  String get removeDeployKey => 'Remove deploy key?';
}
