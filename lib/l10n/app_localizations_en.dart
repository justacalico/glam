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
  String filterBy(Object title) {
    return 'Filter by $title';
  }

  @override
  String filterAny(Object title) {
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
  String pickerSelected(Object count) {
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
  String varDeleteConfirm(Object key) {
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
  String tokenValueTitle(Object name) {
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
  String miscSeconds(Object count) {
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
  String projectsEmptyMatch(Object query) {
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
  String snackForked(Object path) {
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
  String transferConfirm(Object name) {
    return 'Transfer $name?';
  }

  @override
  String get fieldNewNamespace => 'New namespace';

  @override
  String deleteProjectConfirm(Object path) {
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

  @override
  String get openSite => 'Open site';

  @override
  String get forceHttps => 'Force HTTPS';

  @override
  String get redirectAllPagesTrafficToHttps =>
      'Redirect all Pages traffic to HTTPS';

  @override
  String get uniqueDomain => 'Unique domain';

  @override
  String get serveThisSiteOnAUnique =>
      'Serve this site on a unique per-deployment domain';

  @override
  String get removeDomain => 'Remove domain';

  @override
  String get addDomain => 'Add domain';

  @override
  String get unpublishPages => 'Unpublish Pages?';

  @override
  String get addPagesDomain => 'Add Pages domain';

  @override
  String get exportProject => 'Export project';

  @override
  String get loadStatusError => 'Could not load status';

  @override
  String get removeDomainConfirm => 'Remove domain?';

  @override
  String get integrations => 'Integrations';

  @override
  String get noIntegrations => 'No integrations';

  @override
  String get secretValuesMayAppearMaskedFields =>
      'Secret values may appear masked. Fields you do not change are left as they are.';

  @override
  String get mergeMethod => 'Merge method';

  @override
  String get squashCommits => 'Squash commits';

  @override
  String get pipelinesMustSucceed => 'Pipelines must succeed';

  @override
  String get allowMergeOnSkippedPipelines => 'Allow merge on skipped pipelines';

  @override
  String get allThreadsMustBeResolved => 'All threads must be resolved';

  @override
  String get deleteSourceBranchAfterMerge => 'Delete source branch after merge';

  @override
  String get mergeCommitTemplate => 'Merge commit template';

  @override
  String get squashCommitTemplate => 'Squash commit template';

  @override
  String get suggestionCommitMessage => 'Suggestion commit message';

  @override
  String get leaveEmptyToUseTheDefault => 'Leave empty to use the default';

  @override
  String get protectedBranches => 'Protected branches';

  @override
  String get protect => 'Protect';

  @override
  String get noProtectedBranches => 'No protected branches';

  @override
  String get protectBranch => 'Protect branch';

  @override
  String get branchOrWildcard => 'Branch or wildcard';

  @override
  String get mainOrRelease => 'main or release-*';

  @override
  String get allowedToPush => 'Allowed to push';

  @override
  String get allowedToMerge => 'Allowed to merge';

  @override
  String get allowForcePush => 'Allow force push';

  @override
  String get unprotectBranch => 'Unprotect branch?';

  @override
  String get noOne => 'No one';

  @override
  String get developersMaintainers => 'Developers + maintainers';

  @override
  String get maintainers => 'Maintainers';

  @override
  String get admins => 'Admins';

  @override
  String get protectedTags => 'Protected tags';

  @override
  String get noProtectedTags => 'No protected tags';

  @override
  String get protectTag => 'Protect tag';

  @override
  String get tagOrWildcard => 'Tag or wildcard';

  @override
  String get v100OrV => 'v1.0.0 or v*';

  @override
  String get allowedToCreate => 'Allowed to create';

  @override
  String get unprotectTag => 'Unprotect tag?';

  @override
  String get protectedEnvironments => 'Protected environments';

  @override
  String get noProtectedEnvironments => 'No protected environments';

  @override
  String get protectEnvironment => 'Protect environment';

  @override
  String get environmentOrWildcard => 'Environment or wildcard';

  @override
  String get productionOrReview => 'production or review/*';

  @override
  String get runners => 'Runners';

  @override
  String get sharedRunners => 'Shared runners';

  @override
  String get allowInstanceRunnersToPickUp =>
      'Allow instance runners to pick up jobs';

  @override
  String get groupRunners => 'Group runners';

  @override
  String get allowGroupRunnersToPickUp => 'Allow group runners to pick up jobs';

  @override
  String get noRunnersAvailable => 'No runners available';

  @override
  String get removeFromProject => 'Remove from project';

  @override
  String get removeRunner => 'Remove runner?';

  @override
  String get secureFiles => 'Secure files';

  @override
  String get upload => 'Upload';

  @override
  String get noSecureFiles => 'No secure files';

  @override
  String get sharedGroups => 'Shared groups';

  @override
  String get share => 'Share';

  @override
  String get notSharedWithAnyGroup => 'Not shared with any group';

  @override
  String get noGroupsLeftToShareWith => 'No groups left to share with';

  @override
  String get shareWithGroup => 'Share with group';

  @override
  String get group => 'Group';

  @override
  String get maxAccessLevel => 'Max access level';

  @override
  String get removeGroupShare => 'Remove group share?';

  @override
  String get unshare => 'Unshare';

  @override
  String get storageMaintenance => 'Storage & maintenance';

  @override
  String get storageStatisticsAreOnlyVisibleTo =>
      'Storage statistics are only visible to maintainers.';

  @override
  String get housekeepingOptimizesTheRepositoryGcRepack =>
      'Housekeeping optimizes the repository (gc, repack).';

  @override
  String get runHousekeeping => 'Run housekeeping';

  @override
  String get housekeepingStarted => 'Housekeeping started';

  @override
  String get pipelineTriggers => 'Pipeline triggers';

  @override
  String get noTriggers => 'No triggers';

  @override
  String get deleteTrigger => 'Delete trigger';

  @override
  String get lintGitlabCiYml => 'Lint .gitlab-ci.yml';

  @override
  String get validateCiConfigAgainstThisProject =>
      'Validate CI config against this project';

  @override
  String get newTrigger => 'New trigger';

  @override
  String get eGDeployWebhook => 'e.g. Deploy webhook';

  @override
  String get triggerCreated => 'Trigger created';

  @override
  String get useThisTokenToAuthenticateTrigger =>
      'Use this token to authenticate trigger requests.';

  @override
  String get tokenCopied => 'Token copied';

  @override
  String get lintCiConfig => 'Lint CI config';

  @override
  String get pasteYourGitlabCiYmlHere => 'Paste your .gitlab-ci.yml here';

  @override
  String get lint => 'Lint';

  @override
  String deleteNamedConfirm(Object p0) {
    return 'Delete $p0?';
  }

  @override
  String storageTotal(Object p0) {
    return 'Total $p0';
  }

  @override
  String commitCount(Object p0) {
    return '$p0 commits';
  }

  @override
  String storageStatPair(Object p0, Object p1) {
    return '$p0 $p1';
  }

  @override
  String get deleteTriggerConfirm => 'Delete trigger?';

  @override
  String lintJobsList(Object p0) {
    return 'Jobs: $p0';
  }

  @override
  String get auditEvents => 'Audit events';

  @override
  String get archived => 'Archived';

  @override
  String get sshKeys => 'SSH keys';

  @override
  String get noSshKeys => 'No SSH keys';

  @override
  String get addSshKey => 'Add SSH key';

  @override
  String get removeSshKey => 'Remove SSH key?';

  @override
  String get gpgKeys => 'GPG keys';

  @override
  String get noGpgKeys => 'No GPG keys';

  @override
  String get addGpgKey => 'Add GPG key';

  @override
  String get removeGpgKey => 'Remove GPG key?';

  @override
  String get accessTokens => 'Access tokens';

  @override
  String get noActiveTokens => 'No active tokens';

  @override
  String get rotate => 'Rotate';

  @override
  String get rotateToken => 'Rotate token?';

  @override
  String get gitlabDidNotReturnAToken => 'GitLab did not return a token';

  @override
  String get tokenRotated => 'Token rotated';

  @override
  String get revokeToken => 'Revoke token?';

  @override
  String get emails => 'Emails';

  @override
  String get noEmails => 'No emails';

  @override
  String get addEmail => 'Add email';

  @override
  String get email => 'Email';

  @override
  String get youExampleCom => 'you@example.com';

  @override
  String get removeEmail => 'Remove email?';

  @override
  String get gitlabPreferences => 'GitLab preferences';

  @override
  String newTokenShownOnce(Object p0) {
    return 'New token (shown once):\\n\\n$p0';
  }

  @override
  String get eventNewComments => 'New comments';

  @override
  String get eventNewIssues => 'New issues';

  @override
  String get eventReopenedIssues => 'Reopened issues';

  @override
  String get eventClosedIssues => 'Closed issues';

  @override
  String get eventReassignedIssues => 'Reassigned issues';

  @override
  String get eventIssueDueDates => 'Issue due dates';

  @override
  String get eventNewMrs => 'New merge requests';

  @override
  String get eventPushesToMrs => 'Pushes to merge requests';

  @override
  String get eventReopenedMrs => 'Reopened merge requests';

  @override
  String get eventClosedMrs => 'Closed merge requests';

  @override
  String get eventReassignedMrs => 'Reassigned merge requests';

  @override
  String get eventMergedMrs => 'Merged merge requests';

  @override
  String get eventFailedPipelines => 'Failed pipelines';

  @override
  String get eventFixedPipelines => 'Fixed pipelines';

  @override
  String get eventSuccessfulPipelines => 'Successful pipelines';

  @override
  String get eventMovedProjects => 'Moved projects';

  @override
  String get eventNewEpics => 'New epics';

  @override
  String gpgKeyId(Object p0) {
    return 'GPG key #$p0';
  }

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get status => 'Status';

  @override
  String get noAlerts => 'No alerts';

  @override
  String get alertsFromPrometheusAndOtherTools =>
      'Alerts from Prometheus and other tools appear here.';

  @override
  String get setStatus => 'Set status';

  @override
  String linkedIssueP0(Object p0) {
    return 'Linked issue #$p0';
  }

  @override
  String get alertTool => 'Tool';

  @override
  String get alertService => 'Service';

  @override
  String get alertStarted => 'Started';

  @override
  String get alertEnded => 'Ended';

  @override
  String get alertEvents => 'Events';

  @override
  String get alertHosts => 'Hosts';

  @override
  String get fieldAssignees => 'Assignees';

  @override
  String get noBoards => 'No boards';

  @override
  String get newBoard => 'New board';

  @override
  String get boardActions => 'Board actions';

  @override
  String get rename => 'Rename';

  @override
  String get issuesStayOnTheProjectOnly =>
      'Issues stay on the project; only the board goes.';

  @override
  String get thisBoardHasNoLists => 'This board has no lists';

  @override
  String get addList => 'Add list';

  @override
  String get noLabelsOnThisProject => 'No labels on this project.';

  @override
  String get issuesKeepTheirLabelOnlyThe =>
      'Issues keep their label; only the column goes.';

  @override
  String get listActions => 'List actions';

  @override
  String get removeList => 'Remove list';

  @override
  String get noIssues => 'No issues';

  @override
  String get moveTo => 'Move to';

  @override
  String get editBoard => 'Edit board';

  @override
  String get milestoneScope => 'Milestone scope';

  @override
  String get noMilestone => 'No milestone';

  @override
  String get labelScope => 'Label scope';

  @override
  String get bugFrontend => 'bug, frontend';

  @override
  String get weightScope => 'Weight scope';

  @override
  String get state => 'State';

  @override
  String get newEnvironment => 'New environment';

  @override
  String get noEnvironments => 'No environments';

  @override
  String get deploymentsToStagingProductionEtc =>
      'Deployments to staging, production, etc.';

  @override
  String get externalUrlOptional => 'External URL (optional)';

  @override
  String get openLiveEnvironment => 'Open live environment';

  @override
  String get stop => 'Stop';

  @override
  String get deleteEnvironment => 'Delete environment';

  @override
  String get stoppedEnvironmentsCanBeDeleted =>
      'Stopped environments can be deleted.';

  @override
  String issueIid(Object p0) {
    return '#$p0';
  }

  @override
  String removeNamedConfirm(Object p0) {
    return 'Remove $p0?';
  }

  @override
  String deploymentRef(Object p0, Object p1, Object p2) {
    return '#$p0 $p1 · $p2';
  }

  @override
  String get environment => 'Environment';

  @override
  String get editEnvironment => 'Edit environment';

  @override
  String get openLiveUrl => 'Open live URL';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get noDeploymentsYet => 'No deployments yet';

  @override
  String get userLists => 'User lists';

  @override
  String get newList => 'New list';

  @override
  String get noFeatureFlags => 'No feature flags';

  @override
  String get theFlagIsRemovedFromEvery =>
      'The flag is removed from every environment.';

  @override
  String get noUserLists => 'No user lists';

  @override
  String get flagStrategiesUsingItStopMatching =>
      'Flag strategies using it stop matching.';

  @override
  String get userIds => 'User IDs';

  @override
  String userListSummary(Object p0, Object p1, Object p2) {
    return '$p0 $p1 · $p2';
  }

  @override
  String get userSingular => 'user';

  @override
  String get userPlural => 'users';

  @override
  String get newGroup => 'New group';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get searchThisGroup => 'Search this group';

  @override
  String get groupActions => 'Group actions';

  @override
  String get editGroup => 'Edit group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get shared => 'Shared';

  @override
  String get subgroups => 'Subgroups';

  @override
  String get iterations => 'Iterations';

  @override
  String get variables => 'Variables';

  @override
  String get tokens => 'Tokens';

  @override
  String get audit => 'Audit';

  @override
  String get noProjectsInThisGroup => 'No projects in this group';

  @override
  String get noProjectsSharedWithThisGroup =>
      'No projects shared with this group';

  @override
  String get noIterations => 'No iterations';

  @override
  String get iterationsNeedAPremiumGroupWith =>
      'Iterations need a Premium group with a cadence.';

  @override
  String get noSubgroups => 'No subgroups';

  @override
  String get noMergeRequests => 'No merge requests';

  @override
  String get deleteGroupConfirm => 'Delete group?';

  @override
  String get deleteGroupBody =>
      'This deletes the group and all of its subgroups and content. This cannot be undone.';

  @override
  String get searchProjects => 'Search projects';

  @override
  String get searchIssues => 'Search issues';

  @override
  String get searchMrs => 'Search merge requests';

  @override
  String get stateOpen => 'Open';

  @override
  String get stateClosed => 'Closed';

  @override
  String get stateAll => 'All';

  @override
  String get stateMerged => 'Merged';

  @override
  String get searchGroups => 'Search groups';

  @override
  String get parentGroup => 'Parent group';

  @override
  String get topLevel => 'Top level';

  @override
  String get inviteMember => 'Invite member';

  @override
  String get noMembers => 'No members';

  @override
  String get pendingInvitations => 'Pending invitations';

  @override
  String get accessRequests => 'Access requests';

  @override
  String get approve => 'Approve';

  @override
  String get deny => 'Deny';

  @override
  String get invitedGroups => 'Invited groups';

  @override
  String get planner => 'Planner';

  @override
  String get thatGroupLosesAccessToThis =>
      'That group loses access to this one.';

  @override
  String makeP0(Object p0) {
    return 'Make $p0';
  }

  @override
  String theyLoseP0Access(Object p0) {
    return 'They lose $p0 access.';
  }

  @override
  String get usernameUserIdOrEmail => 'Username, user id, or email';

  @override
  String get jane42OrJaneExampleCom => 'jane, 42, or jane@example.com';

  @override
  String get invite => 'Invite';

  @override
  String memberDisplay(Object p0, Object p1) {
    return '$p0 @$p1';
  }

  @override
  String get rolePlanner => 'Planner';

  @override
  String get roleMinimal => 'Minimal';

  @override
  String roleLevelOther(Object p0) {
    return 'Level $p0';
  }

  @override
  String expiresDate(Object p0) {
    return 'expires $p0';
  }

  @override
  String get memberIdentifierRequired =>
      'Username, user id, or email is required';

  @override
  String get memberAddFailed => 'Could not add the member';

  @override
  String get noExpiration => 'No expiration';

  @override
  String expiresOn(Object p0) {
    return 'Expires $p0';
  }

  @override
  String get projectWord => 'project';

  @override
  String get groupWord => 'group';

  @override
  String get linkedIssues => 'Linked issues';

  @override
  String get link => 'Link';

  @override
  String get noLinkedIssues => 'No linked issues';

  @override
  String get linkIssue => 'Link issue';

  @override
  String get projectOptional => 'Project (optional)';

  @override
  String get groupOtherProject => 'group/other-project';

  @override
  String get linkType => 'Link type';

  @override
  String get relatesTo => 'Relates to';

  @override
  String get blocks => 'Blocks';

  @override
  String get blockedBy => 'Blocked by';

  @override
  String get removeLink => 'Remove link?';

  @override
  String unlinkP0FromThisIssue(Object p0) {
    return 'Unlink #$p0 from this issue.';
  }

  @override
  String get relatedMergeRequests => 'Related merge requests';

  @override
  String get willBeClosedBy => 'Will be closed by';

  @override
  String get noRelatedMergeRequests => 'No related merge requests';

  @override
  String moreCount(Object p0) {
    return '+$p0';
  }

  @override
  String linkSummary(Object p0, Object p1) {
    return '$p0 · $p1';
  }

  @override
  String get issueIidField => 'Issue #';

  @override
  String get removeLinkTooltip => 'Remove link';

  @override
  String get markdownSupported => 'Markdown supported';

  @override
  String get weight => 'Weight';

  @override
  String get confidential => 'Confidential';

  @override
  String get onlyVisibleToMembersAndAssignees =>
      'Only visible to members and assignees';

  @override
  String get createIssue => 'Create issue';

  @override
  String get moveIssue => 'Move issue';

  @override
  String get destinationProject => 'Destination project';

  @override
  String get groupProject => 'group/project';

  @override
  String get move => 'Move';

  @override
  String get issueWeight => 'Issue weight';

  @override
  String get emptyClearsTheWeight => 'Empty clears the weight';

  @override
  String get enterAWholeNumber => 'Enter a whole number';

  @override
  String get timeEstimate => 'Time estimate';

  @override
  String get addTimeSpent => 'Add time spent';

  @override
  String get closeIssue => 'Close issue';

  @override
  String get reopenIssue => 'Reopen issue';

  @override
  String get unsubscribe => 'Unsubscribe';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get setTimeEstimate => 'Set time estimate';

  @override
  String get resetTimeSpent => 'Reset time spent';

  @override
  String get setWeight => 'Set weight';

  @override
  String get cloneIssue => 'Clone issue';

  @override
  String get copyLink => 'Copy link';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String issueDueDate(Object p0) {
    return 'Due $p0';
  }

  @override
  String issueWeightValue(Object p0) {
    return 'Weight $p0';
  }

  @override
  String get enterProjectPath => 'Enter a project path';

  @override
  String closedByName(Object p0) {
    return 'Closed by $p0';
  }

  @override
  String tasksStatus(Object p0) {
    return 'Tasks $p0';
  }

  @override
  String openedByAt(Object p0, Object p1) {
    return '$p0 opened $p1';
  }

  @override
  String timeSpentOf(Object p0, Object p1) {
    return '$p0 spent of $p1';
  }

  @override
  String get runPipeline => 'Run pipeline';

  @override
  String get noPipelinesForThisMr => 'No pipelines for this MR';

  @override
  String relatedMergeRequestP0(Object p0) {
    return 'Related merge request$p0';
  }

  @override
  String closesIssues(Object p0, Object p1) {
    return 'Closes $p0 issue$p1';
  }

  @override
  String get mrTileDraft => 'Draft: ';

  @override
  String get sourceBranch => 'Source branch';

  @override
  String get targetBranch => 'Target branch';

  @override
  String get reviewers => 'Reviewers';

  @override
  String get createMr => 'Create MR';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get mrPickBranches => 'Pick a source and target branch';

  @override
  String get mrSaveFailed => 'Could not save the merge request';

  @override
  String get editMr => 'Edit merge request';

  @override
  String get newMr => 'New merge request';

  @override
  String get resolved => 'Resolved';

  @override
  String get resolve => 'Resolve';

  @override
  String get replyHint => 'Reply…';

  @override
  String get actionReply => 'Reply';

  @override
  String get changes => 'Changes';

  @override
  String get loadMoreFailedRetry => 'Load more failed. Retry';

  @override
  String get draft => 'Draft';

  @override
  String get scheduledToMergeWhenThePipeline =>
      'Scheduled to merge when the pipeline succeeds';

  @override
  String get merge => 'Merge';

  @override
  String get revokeApproval => 'Revoke approval';

  @override
  String get cancelAutoMerge => 'Cancel auto-merge';

  @override
  String get mergeWhenPipelineSucceeds => 'Merge when pipeline succeeds';

  @override
  String mergeP0(Object p0) {
    return 'Merge !$p0';
  }

  @override
  String get deleteSourceBranch => 'Delete source branch';

  @override
  String get mergesAutomaticallyOnceThePipelineSucceeds =>
      'Merges automatically once the pipeline succeeds.';

  @override
  String get setAutoMerge => 'Set auto-merge';

  @override
  String get closeMr => 'Close MR';

  @override
  String get reopenMr => 'Reopen MR';

  @override
  String get markAsReady => 'Mark as ready';

  @override
  String get markAsDraft => 'Mark as draft';

  @override
  String get rebase => 'Rebase';

  @override
  String get cherryPick => 'Cherry-pick';

  @override
  String get revert => 'Revert';

  @override
  String get downloadPatch => 'Download patch';

  @override
  String get noChanges => 'No changes';

  @override
  String get latestChanges => 'Latest changes';

  @override
  String get review => 'Review';

  @override
  String get publish => 'Publish';

  @override
  String get submitReview => 'Submit review?';

  @override
  String get allPendingCommentsBecomeVisible =>
      'All pending comments become visible.';

  @override
  String get publishAll => 'Publish all';

  @override
  String get noPendingComments => 'No pending comments.';

  @override
  String get binaryFileOrDiffTooLarge => 'Binary file or diff too large';

  @override
  String get writeAComment => 'Write a comment…';

  @override
  String get addToReview => 'Add to review';

  @override
  String get comment => 'Comment';

  @override
  String get missingDiffRefsRefreshTheMr =>
      'Missing diff refs. Refresh the MR and try again.';

  @override
  String get noCommits => 'No commits';

  @override
  String get contextCommits => 'Context commits';

  @override
  String mrIid(Object p0) {
    return '!$p0';
  }

  @override
  String branchArrow(Object p0, Object p1) {
    return '$p0 → $p1';
  }

  @override
  String projectMrRef(Object p0, Object p1) {
    return '$p0 !$p1';
  }

  @override
  String deletionsCount(Object p0) {
    return '-$p0';
  }

  @override
  String mergedByAt(Object p0, Object p1) {
    return 'Merged by $p0 $p1';
  }

  @override
  String pendingComments(Object p0, Object p1) {
    return '$p0 pending comment$p1 in your review';
  }

  @override
  String versionEntry(Object p0, Object p1, Object p2, Object p3) {
    return 'Version $p0 · $p1 · $p2 file$p3';
  }

  @override
  String commentOnLine(Object p0, Object p1) {
    return 'Comment on $p0:$p1';
  }

  @override
  String get searchMilestones => 'Search milestones';

  @override
  String get newMilestone => 'New milestone';

  @override
  String get noMilestones => 'No milestones';

  @override
  String get milestone => 'Milestone';

  @override
  String get active => 'Active';

  @override
  String get startDate => 'Start date';

  @override
  String get dueDate => 'Due date';

  @override
  String get createMilestone => 'Create milestone';

  @override
  String get searchLabels => 'Search labels';

  @override
  String get newLabel => 'New label';

  @override
  String get noLabels => 'No labels';

  @override
  String p0Issues(Object p0) {
    return '$p0 issues';
  }

  @override
  String get promoteToGroup => 'Promote to group';

  @override
  String promoteP0(Object p0) {
    return 'Promote $p0?';
  }

  @override
  String get promote => 'Promote';

  @override
  String get theLabelIsRemovedFromEvery =>
      'The label is removed from every issue and MR.';

  @override
  String get bugOrPriorityHigh => 'bug or priority::high';

  @override
  String get color => 'Color';

  @override
  String get createLabel => 'Create label';

  @override
  String get labelPromoteBody =>
      'The label moves to the parent group and is replaced on every issue and MR that uses it.';

  @override
  String startsOn(Object p0) {
    return 'Starts $p0';
  }

  @override
  String dueOn(Object p0) {
    return 'Due $p0';
  }

  @override
  String get milestoneSaveFailed => 'Could not save the milestone';

  @override
  String get editMilestone => 'Edit milestone';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get labelSaveFailed => 'Could not save the label';

  @override
  String get editLabel => 'Edit label';

  @override
  String get labelPreview => 'Label preview';

  @override
  String get stateActive => 'Active';

  @override
  String get runs => 'Runs';

  @override
  String get schedules => 'Schedules';

  @override
  String get source => 'Source';

  @override
  String get ref => 'Ref';

  @override
  String get user => 'User';

  @override
  String get noPipelinesYet => 'No pipelines yet';

  @override
  String get scope => 'Scope';

  @override
  String get noJobs => 'No jobs';

  @override
  String get ciLint => 'CI lint';

  @override
  String get stagesNBuild => 'stages:\\n  - build';

  @override
  String get checking => 'Checking…';

  @override
  String get validate => 'Validate';

  @override
  String p0Jobs(Object p0) {
    return '$p0 jobs';
  }

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusSuccess => 'Passed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCanceled => 'Canceled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String get pipelineStatusManual => 'Manual';

  @override
  String get pipelineSourcePush => 'Push';

  @override
  String get pipelineSourceWeb => 'Web';

  @override
  String get pipelineSourceSchedule => 'Schedule';

  @override
  String get pipelineSourceApi => 'API';

  @override
  String get pipelineSourceTrigger => 'Trigger';

  @override
  String get pipelineSourceMr => 'Merge request';

  @override
  String get pipelineSourcePipeline => 'Pipeline';

  @override
  String get pipelineSourceChat => 'Chat';

  @override
  String get newSchedule => 'New schedule';

  @override
  String get noScheduledPipelines => 'No scheduled pipelines';

  @override
  String get recentRuns => 'Recent runs';

  @override
  String get runNow => 'Run now';

  @override
  String get takeOwnership => 'Take ownership';

  @override
  String get scheduleTriggered => 'Schedule triggered';

  @override
  String get deleteSchedule => 'Delete schedule?';

  @override
  String get noRunsYet => 'No runs yet';

  @override
  String get editSchedule => 'Edit schedule';

  @override
  String get targetRef => 'Target ref';

  @override
  String get cron => 'Cron';

  @override
  String get timezone => 'Timezone';

  @override
  String get utc => 'UTC';

  @override
  String get key => 'KEY';

  @override
  String artifactsJobP0(Object p0) {
    return 'Artifacts · job #$p0';
  }

  @override
  String get archiveIsEmpty => 'Archive is empty';

  @override
  String get binaryFileUseShareToSave => 'Binary file — use Share to save it.';

  @override
  String quotedName(Object p0) {
    return '\"$p0\"';
  }

  @override
  String scheduleId(Object p0) {
    return 'Schedule #$p0';
  }

  @override
  String get pickTargetRef => 'Pick a target ref';

  @override
  String get varKeysUnique => 'Variable keys must be unique';

  @override
  String get scheduleSaveFailed => 'Could not save the schedule';

  @override
  String scheduleStopsRunning(Object p0) {
    return '\"$p0\" stops running.';
  }

  @override
  String jobP0(Object p0) {
    return 'Job #$p0';
  }

  @override
  String get erase => 'Erase';

  @override
  String get browseArtifacts => 'Browse artifacts';

  @override
  String get keepArtifacts => 'Keep artifacts';

  @override
  String byP0(Object p0) {
    return 'by $p0';
  }

  @override
  String get copyTrace => 'Copy trace';

  @override
  String pipelineP0(Object p0) {
    return 'Pipeline #$p0';
  }

  @override
  String get stages => 'Stages';

  @override
  String get tests => 'Tests';

  @override
  String get downstream => 'Downstream';

  @override
  String get noJobsInThisPipeline => 'No jobs in this pipeline';

  @override
  String get allowedToFail => 'allowed to fail';

  @override
  String get noTestReport => 'No test report';

  @override
  String get total => 'Total';

  @override
  String get errors => 'Errors';

  @override
  String get coverage => 'Coverage';

  @override
  String get thisPipelineRanWithoutExtraVariables =>
      'This pipeline ran without extra variables.';

  @override
  String get noDownstreamPipelines => 'No downstream pipelines';

  @override
  String get thisPipelineDidNotTriggerAny =>
      'This pipeline did not trigger any child pipelines.';

  @override
  String statText(Object p0, Object p1, Object p2) {
    return '$p0 $p1$p2';
  }

  @override
  String durationInSecs(Object p0) {
    return 'in ${p0}s';
  }

  @override
  String secsValue(Object p0) {
    return '${p0}s';
  }

  @override
  String refAtSha(Object p0, Object p1) {
    return '$p0 @ $p1';
  }

  @override
  String get eraseJobConfirm => 'Erase job?';

  @override
  String get deleteArtifactsConfirm => 'Delete artifacts?';

  @override
  String get deleteArtifactsAction => 'Delete artifacts';

  @override
  String get eraseJobAction => 'Erase job';

  @override
  String get hideRetriedJobs => 'Hide retried jobs';

  @override
  String get showRetriedJobs => 'Show retried jobs';

  @override
  String get runManualJob => 'Run manual job';

  @override
  String get eraseJobBody => 'The trace and artifacts are permanently removed.';

  @override
  String get deleteArtifactsBody =>
      'Locked artifacts may remain. Requires a maintainer role.';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String joinedP0(Object p0) {
    return 'Joined $p0';
  }

  @override
  String p0Followers(Object p0) {
    return '$p0 followers';
  }

  @override
  String p0Following(Object p0) {
    return '$p0 following';
  }

  @override
  String get unfollow => 'Unfollow';

  @override
  String get follow => 'Follow';

  @override
  String p0ContributionsInTheLastYear(Object p0) {
    return '$p0 contributions in the last year';
  }

  @override
  String get statusEmoji => 'Status emoji';

  @override
  String get eG => 'e.g. 🌴';

  @override
  String get statusMessage => 'Status message';

  @override
  String get memberships => 'Memberships';

  @override
  String get fieldPronouns => 'Pronouns';

  @override
  String get fieldJobTitle => 'Job title';

  @override
  String get fieldOrganization => 'Organization';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldPublicEmail => 'Public email';

  @override
  String get fieldWebsite => 'Website';

  @override
  String get fieldTwitter => 'Twitter';

  @override
  String get fieldLinkedin => 'LinkedIn';

  @override
  String get fieldBio => 'Bio';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get searchPackages => 'Search packages';

  @override
  String get type => 'Type';

  @override
  String get noPackages => 'No packages';

  @override
  String get deletePackage => 'Delete package?';

  @override
  String p0IsRemovedPermanently(Object p0) {
    return '\"$p0\" is removed permanently.';
  }

  @override
  String get noFiles => 'No files';

  @override
  String get noContainerImages => 'No container images';

  @override
  String get deleteRepository => 'Delete repository?';

  @override
  String p0AndAllItsTagsAre(Object p0) {
    return '\"$p0\" and all its tags are removed.';
  }

  @override
  String get filterTagsRegex => 'Filter tags (regex)';

  @override
  String get noTags => 'No tags';

  @override
  String get deleteTag => 'Delete tag?';

  @override
  String get emptyDirectory => 'Empty directory';

  @override
  String get downloadSource => 'Download source';

  @override
  String get newFile => 'New file';

  @override
  String get switchBranch => 'Switch branch';

  @override
  String get editFile => 'Edit file';

  @override
  String get copyContents => 'Copy contents';

  @override
  String get fileHistory => 'File history';

  @override
  String get viewBlame => 'View blame';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get aCommitRemovingThisFileWill =>
      'A commit removing this file will be created.';

  @override
  String editP0(Object p0) {
    return 'Edit $p0';
  }

  @override
  String get template => 'Template';

  @override
  String get commit => 'Commit';

  @override
  String get filePath => 'File path';

  @override
  String get commitMessage => 'Commit message';

  @override
  String get fileContents => 'File contents';

  @override
  String commitsToP0(Object p0) {
    return 'Commits to $p0';
  }

  @override
  String get noTemplates => 'No templates';

  @override
  String get searchBranches => 'Search branches';

  @override
  String get compare => 'Compare';

  @override
  String get deleteMerged => 'Delete merged';

  @override
  String get newBranch => 'New branch';

  @override
  String get noBranches => 'No branches';

  @override
  String get branchName => 'Branch name';

  @override
  String get sourceRefBranchTagOrSha => 'Source ref (branch, tag, or sha)';

  @override
  String get deleteMergedBranches => 'Delete merged branches?';

  @override
  String get deleteBranch => 'Delete branch';

  @override
  String get deleteMergedBody =>
      'Every branch already merged into the default branch is removed. Protected branches are kept.';

  @override
  String get templateGitignore => 'Gitignore';

  @override
  String get templateLicense => 'License';

  @override
  String get templateGitlabCi => 'GitLab CI';

  @override
  String get templateDockerfile => 'Dockerfile';

  @override
  String couldNotLoadTheDiffP0(Object p0) {
    return 'Could not load the diff: $p0';
  }

  @override
  String get couldNotPostTheComment => 'Could not post the comment';

  @override
  String get cherryPickToBranch => 'Cherry-pick to branch';

  @override
  String get revertOnBranch => 'Revert on branch';

  @override
  String get copySha => 'Copy SHA';

  @override
  String parentsP0(Object p0) {
    return 'Parents: $p0';
  }

  @override
  String get checks => 'Checks';

  @override
  String get on => 'On';

  @override
  String couldNotLoadCommentsP0(Object p0) {
    return 'Could not load comments ($p0)';
  }

  @override
  String get commentOnThisCommit => 'Comment on this commit';

  @override
  String get diffTooLargeOrBinaryView =>
      'Diff too large or binary. View it on the web';

  @override
  String deletionsMinus(Object p0) {
    return '−$p0';
  }

  @override
  String diffStats(Object p0, Object p1) {
    return '+$p0 −$p1';
  }

  @override
  String get cherryPicked => 'Cherry-picked';

  @override
  String get reverted => 'Reverted';

  @override
  String cherryRevertDone(Object p0, Object p1) {
    return '$p0 as $p1';
  }

  @override
  String get fileSingular => 'file';

  @override
  String get filePlural => 'files';
}
