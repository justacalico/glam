// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Glam';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get actionAdd => '添加';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClose => '关闭';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionCopy => '复制';

  @override
  String get actionCopied => '已复制';

  @override
  String get actionCreate => '创建';

  @override
  String get actionDelete => '删除';

  @override
  String get actionDone => '完成';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionOk => '确定';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionRetry => '重试';

  @override
  String get actionRevoke => '吊销';

  @override
  String get actionSave => '保存';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get errorRequired => '必填';

  @override
  String get errorGeneric => '出错了';

  @override
  String get actionTryAgain => '重试';

  @override
  String filterBy(String title) {
    return '按$title筛选';
  }

  @override
  String filterAny(String title) {
    return '全部$title';
  }

  @override
  String get sortTitle => '排序';

  @override
  String get sortNewest => '最新';

  @override
  String get sortOldest => '最早';

  @override
  String get sortRecentlyUpdated => '最近更新';

  @override
  String get sortLeastRecentlyUpdated => '最早更新';

  @override
  String get sortDueSoonest => '截止最早';

  @override
  String get sortDueLatest => '截止最晚';

  @override
  String get sortTitleAZ => '标题 A-Z';

  @override
  String get sortTitleZA => '标题 Z-A';

  @override
  String get composerUploadFailed => '上传文件失败';

  @override
  String get composerSendFailed => '发表评论失败';

  @override
  String get composerHint => '写评论';

  @override
  String get composerAttach => '添加附件';

  @override
  String get listLoadFailed => '加载失败，点击重试';

  @override
  String get noteActions => '评论操作';

  @override
  String get noteEditTitle => '编辑评论';

  @override
  String get noteDeleteConfirm => '删除评论？';

  @override
  String get pickerNone => '无';

  @override
  String pickerSelected(int count) {
    return '已选 $count 人';
  }

  @override
  String get pickerSearchMembers => '搜索成员';

  @override
  String get pickerLoadFailed => '成员加载失败，重试';

  @override
  String get pickerEmpty => '未找到成员';

  @override
  String get usersEmpty => '暂无成员';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsLevel => '级别';

  @override
  String get notifNewNote => '新评论';

  @override
  String get notifNewIssue => '新议题';

  @override
  String get notifReopenIssue => '重新打开的议题';

  @override
  String get notifCloseIssue => '已关闭的议题';

  @override
  String get notifReassignIssue => '重新指派的议题';

  @override
  String get notifIssueDue => '议题截止日期';

  @override
  String get notifNewMr => '新合并请求';

  @override
  String get notifPushMr => '合并请求新推送';

  @override
  String get notifReopenMr => '重新打开的合并请求';

  @override
  String get notifCloseMr => '已关闭的合并请求';

  @override
  String get notifReassignMr => '重新指派的合并请求';

  @override
  String get notifMergeMr => '已合并的合并请求';

  @override
  String get notifFailedPipeline => '失败的流水线';

  @override
  String get notifFixedPipeline => '已修复的流水线';

  @override
  String get notifSuccessPipeline => '成功的流水线';

  @override
  String get notifMovedProject => '项目转移';

  @override
  String get templateUse => '使用模板';

  @override
  String get templateChoose => '选择模板';

  @override
  String get levelGlobal => '全局默认';

  @override
  String get levelWatch => '关注';

  @override
  String get levelParticipating => '参与';

  @override
  String get levelMention => '被提及时';

  @override
  String get levelDisabled => '禁用';

  @override
  String get levelCustom => '自定义';

  @override
  String get auditEmpty => '暂无审计事件';

  @override
  String get auditEmptyHint => '审计事件可能需要付费版。';

  @override
  String get auditSomeone => '某人';

  @override
  String get auditMadeChange => '做了修改';

  @override
  String get varsTitle => 'CI/CD 变量';

  @override
  String get varsEmpty => '暂无变量';

  @override
  String get varAddTitle => '添加变量';

  @override
  String get varEditTitle => '编辑变量';

  @override
  String get fieldKey => '键';

  @override
  String get fieldValue => '值';

  @override
  String get varEnvScope => '环境范围';

  @override
  String get varProtected => '受保护';

  @override
  String get varMasked => '已掩码';

  @override
  String varDeleteConfirm(String key) {
    return '删除 $key？';
  }

  @override
  String get tokensDeployTitle => '部署令牌';

  @override
  String get tokensDeployEmpty => '暂无部署令牌';

  @override
  String get tokenDeployCreate => '创建部署令牌';

  @override
  String get fieldName => '名称';

  @override
  String get fieldUsernameOptional => '用户名（可选）';

  @override
  String get fieldExpiresDays => '有效天数（可选）';

  @override
  String get errorPositiveNumber => '必须是正数';

  @override
  String get tokenScopeRequired => '至少选择一个权限范围';

  @override
  String tokenValueTitle(String name) {
    return '令牌 \"$name\"';
  }

  @override
  String get tokenCopyNow => '请立即复制，之后将不再显示。';

  @override
  String get tokenDeployRevokeConfirm => '吊销部署令牌？';

  @override
  String get webhooksTitle => 'Webhooks';

  @override
  String get webhooksEmpty => '暂无 Webhook';

  @override
  String get webhookTestSent => '测试事件已发送';

  @override
  String get webhookDeleteConfirm => '删除 Webhook？';

  @override
  String get webhookTestSend => '发送测试事件';

  @override
  String get hookPushEvents => '推送事件';

  @override
  String get hookTagPush => '标签推送事件';

  @override
  String get hookIssues => '议题';

  @override
  String get hookComments => '评论';

  @override
  String get hookMergeRequests => '合并请求';

  @override
  String get hookPipeline => '流水线';

  @override
  String get hookJobs => '作业';

  @override
  String get hookWiki => 'Wiki 页面';

  @override
  String get hookDeployments => '部署';

  @override
  String get hookReleases => '发布';

  @override
  String get hookSubgroup => '子群组事件';

  @override
  String get webhookAddTitle => '添加 Webhook';

  @override
  String get webhookUrl => 'URL';

  @override
  String get webhookSecret => 'Secret 令牌（可选）';

  @override
  String get webhookSsl => 'SSL 验证';

  @override
  String get homeTitle => '首页';

  @override
  String get projectsTitle => '项目';

  @override
  String get issuesTitle => '议题';

  @override
  String get mrsTitle => '合并请求';

  @override
  String get navMrs => '合并请求';

  @override
  String get todosTitle => '待办';

  @override
  String get activityTitle => '动态';

  @override
  String get groupsTitle => '群组';

  @override
  String get snippetsTitle => '代码片段';

  @override
  String get searchTitle => '搜索';

  @override
  String get settingsTitle => '设置';

  @override
  String get navMore => '更多';

  @override
  String get dashProjectsSub => '浏览你的项目';

  @override
  String get dashMrsSub => '审查与合并';

  @override
  String get dashIssuesSub => '指派给你';

  @override
  String get dashTodosSub => '你的任务列表';

  @override
  String get dashSearchSub => '全实例搜索';

  @override
  String get dashActivitySub => '最近动态';

  @override
  String get greetingMorning => '早上好，';

  @override
  String get greetingAfternoon => '下午好，';

  @override
  String get greetingEvening => '晚上好，';

  @override
  String get loginError => '登录失败，请检查实例地址。';

  @override
  String get loginSubtitle => '登录到你的 GitLab 实例';

  @override
  String get loginInstanceUrl => '实例地址';

  @override
  String get loginInstanceRequired => '请输入 GitLab 实例地址';

  @override
  String get loginToken => '个人访问令牌';

  @override
  String get loginPaste => '粘贴';

  @override
  String get loginShow => '显示';

  @override
  String get loginHide => '隐藏';

  @override
  String get loginTokenRequired => '请粘贴个人访问令牌';

  @override
  String get loginSignIn => '登录';

  @override
  String get loginTokenHelp => '在「偏好设置 → 访问令牌」中创建具有 `api` 权限的令牌。';

  @override
  String get fieldTitle => '标题';

  @override
  String get fieldPath => '路径';

  @override
  String get fieldRole => '角色';

  @override
  String get fieldDescription => '描述';

  @override
  String get fieldVisibility => '可见性';

  @override
  String get fieldDomain => '域名';

  @override
  String get roleGuest => '访客';

  @override
  String get roleReporter => '报告者';

  @override
  String get roleDeveloper => '开发者';

  @override
  String get roleMaintainer => '维护者';

  @override
  String get roleOwner => '所有者';

  @override
  String get visibilityPrivate => '私有';

  @override
  String get visibilityInternal => '内部';

  @override
  String get visibilityPublic => '公开';

  @override
  String get stateEnabled => '启用';

  @override
  String get stateDisabled => '禁用';

  @override
  String get stateEnabledShort => '已启用';

  @override
  String get miscDefault => '默认';

  @override
  String get miscNotSet => '未设置';

  @override
  String get miscLoading => '加载中…';

  @override
  String get miscSaving => '保存中…';

  @override
  String miscSeconds(int count) {
    return '$count 秒';
  }

  @override
  String get errorEnterNumber => '请输入数字';

  @override
  String get emptyDefault => '暂无内容';

  @override
  String get actionRemove => '移除';

  @override
  String get actionDownload => '下载';

  @override
  String get actionOpen => '打开';

  @override
  String get actionUnpublish => '取消发布';

  @override
  String get actionTransfer => '转移';

  @override
  String get actionArchive => '归档';

  @override
  String get actionUnarchive => '取消归档';

  @override
  String get actionExport => '导出';

  @override
  String get actionReexport => '重新导出';

  @override
  String get actionNew => '新建';

  @override
  String get scopeYours => '你的';

  @override
  String get scopeStarred => '已加星';

  @override
  String get scopeExplore => '探索';

  @override
  String get scopeAll => '全部';

  @override
  String get sortLastActivity => '最近活动';

  @override
  String get sortMostStars => '最多星标';

  @override
  String get sortRecentlyCreated => '最近创建';

  @override
  String get projectsSearchHint => '搜索项目';

  @override
  String get projectNew => '新建项目';

  @override
  String get searchClose => '关闭搜索';

  @override
  String get projectsEmpty => '暂无项目';

  @override
  String projectsEmptyMatch(String query) {
    return '没有匹配 \"$query\" 的结果';
  }

  @override
  String get projectsEmptyHint => '你有权限的项目会显示在这里';

  @override
  String get overviewLanguages => '语言';

  @override
  String get overviewDefaultBranch => '默认分支';

  @override
  String get overviewCreated => '创建时间';

  @override
  String get overviewLastActivity => '最近活动';

  @override
  String get overviewOwner => '所有者';

  @override
  String get overviewForkedFrom => '派生自';

  @override
  String get tabOverview => '概览';

  @override
  String get tabPipelines => '流水线';

  @override
  String get tabEnvironments => '环境';

  @override
  String get tabFlags => '功能开关';

  @override
  String get tabAlerts => '告警';

  @override
  String get tabMembers => '成员';

  @override
  String get tabForks => '派生';

  @override
  String get tabContributors => '贡献者';

  @override
  String get tabPackages => '软件包';

  @override
  String get tabRegistry => '注册表';

  @override
  String get tabWiki => 'Wiki';

  @override
  String get tabBoards => '看板';

  @override
  String get tabMilestones => '里程碑';

  @override
  String get tabLabels => '标签';

  @override
  String get tabFiles => '文件';

  @override
  String get tabCommits => '提交';

  @override
  String get tabBranches => '分支';

  @override
  String get tabTags => '标记';

  @override
  String get tabReleases => '发布';

  @override
  String get starrersTitle => '加星用户';

  @override
  String get actionStar => '加星';

  @override
  String get actionFork => '派生';

  @override
  String get actionCopyCloneUrl => '复制克隆地址';

  @override
  String get actionOpenBrowser => '在浏览器打开';

  @override
  String get snackStarred => '已加星';

  @override
  String snackForked(String path) {
    return '已派生到 $path';
  }

  @override
  String get snackForkFailed => '派生项目失败';

  @override
  String get snackCloneCopied => '克隆地址已复制';

  @override
  String get contributorsEmpty => '暂无贡献者';

  @override
  String get latestPipeline => '最新流水线';

  @override
  String get forksEmpty => '暂无派生';

  @override
  String get projectSettingsTitle => '项目设置';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get sectionGeneral => '通用';

  @override
  String get fieldProjectName => '项目名称';

  @override
  String get fieldTopics => '主题（逗号分隔）';

  @override
  String get sectionFeatures => '功能';

  @override
  String get sectionDangerZone => '危险操作';

  @override
  String get dangerArchived => '此项目已归档。';

  @override
  String get dangerArchiveHint => '归档后项目将变为只读。';

  @override
  String get dangerTransferHint => '将项目转移到其他命名空间。';

  @override
  String get dangerDeleteHint => '删除将移除项目及其仓库。';

  @override
  String transferConfirm(String name) {
    return '转移 $name？';
  }

  @override
  String get fieldNewNamespace => '新命名空间';

  @override
  String deleteProjectConfirm(String path) {
    return '删除 $path？';
  }

  @override
  String get deleteProjectBody => '将删除项目及其仓库。gitlab.com 上删除会延迟执行；自建实例上可能立即删除。';

  @override
  String get actionDeleteProject => '删除项目';

  @override
  String get fieldPathHint => '默认使用名称';

  @override
  String get fieldNamespace => '命名空间';

  @override
  String get namespacePersonal => '个人命名空间';

  @override
  String get initReadme => '使用 README 初始化';

  @override
  String get noProjectAccessTokens => '没有项目访问令牌';

  @override
  String get createProjectAccessToken => '创建项目访问令牌';

  @override
  String get copyThisNowItWillNot => '请立即复制，之后将无法再次查看。';

  @override
  String get revokeAccessToken => '吊销访问令牌？';

  @override
  String tokenCreatedTitle(Object p0) {
    return '令牌“$p0”';
  }

  @override
  String get noApprovalRules => '没有审批规则';

  @override
  String get requiredApprovals => '所需审批数';

  @override
  String get approvalsRequiredToMerge => '合并所需审批数';

  @override
  String get ruleName => '规则名称';

  @override
  String get approvalsRequired => '所需审批数';

  @override
  String get eligibleApprovers => '可审批成员';

  @override
  String get deleteApprovalRule => '删除审批规则？';

  @override
  String get publicPipelines => '公开流水线';

  @override
  String get autoCancelRedundantPipelines => '自动取消冗余流水线';

  @override
  String get forwardDeploymentVariables => '转发部署变量';

  @override
  String get separateCachesPerBranch => '按分支隔离缓存';

  @override
  String get keepLatestArtifacts => '保留最新产物';

  @override
  String get jobTimeout => '作业超时';

  @override
  String get timeoutSeconds => '超时时间（秒）';

  @override
  String get ciCdConfigPath => 'CI/CD 配置路径';

  @override
  String get noDeployKeys => '没有部署密钥';

  @override
  String get addDeployKey => '添加部署密钥';

  @override
  String get publicKey => '公钥';

  @override
  String get sshEd25519Aaaa => 'ssh-ed25519 AAAA…';

  @override
  String get grantWriteAccess => '授予写权限';

  @override
  String get removeDeployKey => '移除部署密钥？';

  @override
  String get openSite => '打开站点';

  @override
  String get forceHttps => '强制 HTTPS';

  @override
  String get redirectAllPagesTrafficToHttps => '将所有 Pages 流量重定向到 HTTPS';

  @override
  String get uniqueDomain => '独立域名';

  @override
  String get serveThisSiteOnAUnique => '在每次部署的独立域名上提供此站点';

  @override
  String get removeDomain => '移除域名';

  @override
  String get addDomain => '添加域名';

  @override
  String get unpublishPages => '取消发布 Pages？';

  @override
  String get addPagesDomain => '添加 Pages 域名';

  @override
  String get exportProject => '导出项目';

  @override
  String get loadStatusError => '无法加载状态';

  @override
  String get removeDomainConfirm => '移除域名？';

  @override
  String get integrations => '集成';

  @override
  String get noIntegrations => '没有集成';

  @override
  String get secretValuesMayAppearMaskedFields => '密钥值可能会脱敏显示。未修改的字段将保持原样。';

  @override
  String get mergeMethod => '合并方式';

  @override
  String get squashCommits => '压缩提交';

  @override
  String get pipelinesMustSucceed => '流水线必须成功';

  @override
  String get allowMergeOnSkippedPipelines => '允许在跳过流水线时合并';

  @override
  String get allThreadsMustBeResolved => '所有讨论必须已解决';

  @override
  String get deleteSourceBranchAfterMerge => '合并后删除源分支';

  @override
  String get mergeCommitTemplate => '合并提交模板';

  @override
  String get squashCommitTemplate => '压缩提交模板';

  @override
  String get suggestionCommitMessage => '建议提交信息';

  @override
  String get leaveEmptyToUseTheDefault => '留空则使用默认值';

  @override
  String get protectedBranches => '受保护分支';

  @override
  String get protect => '保护';

  @override
  String get noProtectedBranches => '没有受保护分支';

  @override
  String get protectBranch => '保护分支';

  @override
  String get branchOrWildcard => '分支或通配符';

  @override
  String get mainOrRelease => 'main 或 release-*';

  @override
  String get allowedToPush => '允许推送';

  @override
  String get allowedToMerge => '允许合并';

  @override
  String get allowForcePush => '允许强制推送';

  @override
  String get unprotectBranch => '取消分支保护？';

  @override
  String get noOne => '无人';

  @override
  String get developersMaintainers => '开发者 + 维护者';

  @override
  String get maintainers => '维护者';

  @override
  String get admins => '管理员';

  @override
  String get protectedTags => '受保护标签';

  @override
  String get noProtectedTags => '没有受保护标签';

  @override
  String get protectTag => '保护标签';

  @override
  String get tagOrWildcard => '标签或通配符';

  @override
  String get v100OrV => 'v1.0.0 或 v*';

  @override
  String get allowedToCreate => '允许创建';

  @override
  String get unprotectTag => '取消标签保护？';

  @override
  String get protectedEnvironments => '受保护环境';

  @override
  String get noProtectedEnvironments => '没有受保护环境';

  @override
  String get protectEnvironment => '保护环境';

  @override
  String get environmentOrWildcard => '环境或通配符';

  @override
  String get productionOrReview => 'production 或 review/*';

  @override
  String get runners => 'Runners';

  @override
  String get sharedRunners => '共享 Runners';

  @override
  String get allowInstanceRunnersToPickUp => '允许实例 Runner 拾取作业';

  @override
  String get groupRunners => '群组 Runners';

  @override
  String get allowGroupRunnersToPickUp => '允许群组 Runner 拾取作业';

  @override
  String get noRunnersAvailable => '没有可用的 Runner';

  @override
  String get removeFromProject => '从项目移除';

  @override
  String get removeRunner => '移除 Runner？';

  @override
  String get secureFiles => '安全文件';

  @override
  String get upload => '上传';

  @override
  String get noSecureFiles => '没有安全文件';

  @override
  String get sharedGroups => '共享群组';

  @override
  String get share => '共享';

  @override
  String get notSharedWithAnyGroup => '未与任何群组共享';

  @override
  String get noGroupsLeftToShareWith => '没有可共享的群组了';

  @override
  String get shareWithGroup => '与群组共享';

  @override
  String get group => '群组';

  @override
  String get maxAccessLevel => '最高访问级别';

  @override
  String get removeGroupShare => '移除群组共享？';

  @override
  String get unshare => '取消共享';

  @override
  String get storageMaintenance => '存储与维护';

  @override
  String get storageStatisticsAreOnlyVisibleTo => '存储统计仅对维护者可见。';

  @override
  String get housekeepingOptimizesTheRepositoryGcRepack =>
      'Housekeeping 会优化仓库（gc、repack）。';

  @override
  String get runHousekeeping => '运行 housekeeping';

  @override
  String get housekeepingStarted => 'Housekeeping 已开始';

  @override
  String get pipelineTriggers => '流水线触发器';

  @override
  String get noTriggers => '没有触发器';

  @override
  String get deleteTrigger => '删除触发器';

  @override
  String get lintGitlabCiYml => 'Lint .gitlab-ci.yml';

  @override
  String get validateCiConfigAgainstThisProject => '针对此项目验证 CI 配置';

  @override
  String get newTrigger => '新建触发器';

  @override
  String get eGDeployWebhook => '例如 部署 webhook';

  @override
  String get triggerCreated => '触发器已创建';

  @override
  String get useThisTokenToAuthenticateTrigger => '使用此令牌认证触发请求。';

  @override
  String get tokenCopied => '令牌已复制';

  @override
  String get lintCiConfig => 'Lint CI 配置';

  @override
  String get pasteYourGitlabCiYmlHere => '在此粘贴 .gitlab-ci.yml';

  @override
  String get lint => 'Lint';

  @override
  String deleteNamedConfirm(Object p0) {
    return '删除 $p0？';
  }

  @override
  String storageTotal(Object p0) {
    return '总计 $p0';
  }

  @override
  String commitCount(Object p0) {
    return '$p0 次提交';
  }

  @override
  String storageStatPair(Object p0, Object p1) {
    return '$p0 $p1';
  }

  @override
  String get deleteTriggerConfirm => '删除触发器？';

  @override
  String lintJobsList(String p0) {
    return '作业：$p0';
  }

  @override
  String get auditEvents => '审计事件';

  @override
  String get archived => '已归档';

  @override
  String get sshKeys => 'SSH 密钥';

  @override
  String get noSshKeys => '没有 SSH 密钥';

  @override
  String get addSshKey => '添加 SSH 密钥';

  @override
  String get removeSshKey => '移除 SSH 密钥？';

  @override
  String get gpgKeys => 'GPG 密钥';

  @override
  String get noGpgKeys => '没有 GPG 密钥';

  @override
  String get addGpgKey => '添加 GPG 密钥';

  @override
  String get removeGpgKey => '移除 GPG 密钥？';

  @override
  String get accessTokens => '访问令牌';

  @override
  String get noActiveTokens => '没有启用的令牌';

  @override
  String get rotate => '轮换';

  @override
  String get rotateToken => '轮换令牌？';

  @override
  String get gitlabDidNotReturnAToken => 'GitLab 未返回令牌';

  @override
  String get tokenRotated => '令牌已轮换';

  @override
  String get revokeToken => '吊销令牌？';

  @override
  String get emails => '邮箱';

  @override
  String get noEmails => '没有邮箱';

  @override
  String get addEmail => '添加邮箱';

  @override
  String get email => '邮箱';

  @override
  String get youExampleCom => 'you@example.com';

  @override
  String get removeEmail => '移除邮箱？';

  @override
  String get gitlabPreferences => 'GitLab 偏好设置';

  @override
  String newTokenShownOnce(Object p0) {
    return '新令牌（仅显示一次）：\n\n$p0';
  }

  @override
  String get eventNewComments => '新评论';

  @override
  String get eventNewIssues => '新议题';

  @override
  String get eventReopenedIssues => '重新打开的议题';

  @override
  String get eventClosedIssues => '已关闭的议题';

  @override
  String get eventReassignedIssues => '重新分配的议题';

  @override
  String get eventIssueDueDates => '议题截止日期';

  @override
  String get eventNewMrs => '新合并请求';

  @override
  String get eventPushesToMrs => '合并请求推送';

  @override
  String get eventReopenedMrs => '重新打开的合并请求';

  @override
  String get eventClosedMrs => '已关闭的合并请求';

  @override
  String get eventReassignedMrs => '重新分配的合并请求';

  @override
  String get eventMergedMrs => '已合并的合并请求';

  @override
  String get eventFailedPipelines => '失败的流水线';

  @override
  String get eventFixedPipelines => '修复的流水线';

  @override
  String get eventSuccessfulPipelines => '成功的流水线';

  @override
  String get eventMovedProjects => '移动的项目';

  @override
  String get eventNewEpics => '新 epic';

  @override
  String gpgKeyId(int p0) {
    return 'GPG 密钥 #$p0';
  }

  @override
  String get noActivityYet => '暂无动态';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get allCaughtUp => '全部处理完了';

  @override
  String get status => '状态';

  @override
  String get noAlerts => '没有告警';

  @override
  String get alertsFromPrometheusAndOtherTools =>
      '来自 Prometheus 和其他工具的告警会显示在这里。';

  @override
  String get setStatus => '设置状态';

  @override
  String linkedIssueP0(Object p0) {
    return '关联议题 #$p0';
  }

  @override
  String get alertTool => '工具';

  @override
  String get alertService => '服务';

  @override
  String get alertStarted => '开始时间';

  @override
  String get alertEnded => '结束时间';

  @override
  String get alertEvents => '事件';

  @override
  String get alertHosts => '主机';

  @override
  String get fieldAssignees => '负责人';

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
  String removeP0(Object p0) {
    return 'Remove $p0?';
  }

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
  String p0(Object p0) {
    return '#$p0';
  }

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
}
