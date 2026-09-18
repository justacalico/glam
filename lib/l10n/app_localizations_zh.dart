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
  String filterBy(Object title) {
    return '按$title筛选';
  }

  @override
  String filterAny(Object title) {
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
  String pickerSelected(Object count) {
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
  String get varMasked => '已脱敏';

  @override
  String varDeleteConfirm(Object key) {
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
  String tokenValueTitle(Object name) {
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
  String miscSeconds(Object count) {
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
  String projectsEmptyMatch(Object query) {
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
  String snackForked(Object path) {
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
  String transferConfirm(Object name) {
    return '转移 $name？';
  }

  @override
  String get fieldNewNamespace => '新命名空间';

  @override
  String deleteProjectConfirm(Object path) {
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
  String lintJobsList(Object p0) {
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
  String gpgKeyId(Object p0) {
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
  String get noBoards => '没有看板';

  @override
  String get newBoard => '新建看板';

  @override
  String get boardActions => '看板操作';

  @override
  String get rename => '重命名';

  @override
  String get issuesStayOnTheProjectOnly => '议题会保留在项目中，仅删除看板。';

  @override
  String get thisBoardHasNoLists => '此看板没有列表';

  @override
  String get addList => '添加列表';

  @override
  String get noLabelsOnThisProject => '此项目没有标签。';

  @override
  String get issuesKeepTheirLabelOnlyThe => '议题会保留标签，仅移除该列。';

  @override
  String get listActions => '列表操作';

  @override
  String get removeList => '移除列表';

  @override
  String get noIssues => '没有议题';

  @override
  String get moveTo => '移动到';

  @override
  String get editBoard => '编辑看板';

  @override
  String get milestoneScope => '里程碑范围';

  @override
  String get noMilestone => '无里程碑';

  @override
  String get labelScope => '标签范围';

  @override
  String get bugFrontend => 'bug, frontend';

  @override
  String get weightScope => '权重范围';

  @override
  String get state => '状态';

  @override
  String get newEnvironment => '新建环境';

  @override
  String get noEnvironments => '没有环境';

  @override
  String get deploymentsToStagingProductionEtc => '部署到 staging、production 等环境。';

  @override
  String get externalUrlOptional => '外部 URL（可选）';

  @override
  String get openLiveEnvironment => '打开线上环境';

  @override
  String get stop => '停止';

  @override
  String get deleteEnvironment => '删除环境';

  @override
  String get stoppedEnvironmentsCanBeDeleted => '已停止的环境可以删除。';

  @override
  String issueIid(Object p0) {
    return '#$p0';
  }

  @override
  String removeNamedConfirm(Object p0) {
    return '移除 $p0？';
  }

  @override
  String deploymentRef(Object p0, Object p1, Object p2) {
    return '#$p0 $p1 · $p2';
  }

  @override
  String get environment => '环境';

  @override
  String get editEnvironment => '编辑环境';

  @override
  String get openLiveUrl => '打开线上 URL';

  @override
  String get copyUrl => '复制 URL';

  @override
  String get noDeploymentsYet => '暂无部署';

  @override
  String get userLists => '用户列表';

  @override
  String get newList => '新建列表';

  @override
  String get noFeatureFlags => '没有功能标志';

  @override
  String get theFlagIsRemovedFromEvery => '该标志将从每个环境中移除。';

  @override
  String get noUserLists => '没有用户列表';

  @override
  String get flagStrategiesUsingItStopMatching => '使用该列表的标志策略将停止匹配。';

  @override
  String get userIds => '用户 ID';

  @override
  String userListSummary(Object p0, Object p1, Object p2) {
    return '共 $p0 个$p1 · $p2';
  }

  @override
  String get userSingular => '用户';

  @override
  String get userPlural => '用户';

  @override
  String get newGroup => '新建群组';

  @override
  String get noGroupsFound => '未找到群组';

  @override
  String get searchThisGroup => '搜索此群组';

  @override
  String get groupActions => '群组操作';

  @override
  String get editGroup => '编辑群组';

  @override
  String get deleteGroup => '删除群组';

  @override
  String get shared => '已共享';

  @override
  String get subgroups => '子群组';

  @override
  String get iterations => '迭代';

  @override
  String get variables => '变量';

  @override
  String get tokens => '令牌';

  @override
  String get audit => '审计';

  @override
  String get noProjectsInThisGroup => '此群组中没有项目';

  @override
  String get noProjectsSharedWithThisGroup => '没有与此群组共享的项目';

  @override
  String get noIterations => '没有迭代';

  @override
  String get iterationsNeedAPremiumGroupWith => '迭代需要 Premium 群组并设置周期。';

  @override
  String get noSubgroups => '没有子群组';

  @override
  String get noMergeRequests => '没有合并请求';

  @override
  String get deleteGroupConfirm => '删除群组？';

  @override
  String get deleteGroupBody => '将删除该群组及其所有子群组和内容。此操作无法撤销。';

  @override
  String get searchProjects => '搜索项目';

  @override
  String get searchIssues => '搜索议题';

  @override
  String get searchMrs => '搜索合并请求';

  @override
  String get stateOpen => '打开';

  @override
  String get stateClosed => '已关闭';

  @override
  String get stateAll => '全部';

  @override
  String get stateMerged => '已合并';

  @override
  String get searchGroups => '搜索群组';

  @override
  String get parentGroup => '父群组';

  @override
  String get topLevel => '顶层';

  @override
  String get inviteMember => '邀请成员';

  @override
  String get noMembers => '没有成员';

  @override
  String get pendingInvitations => '待处理的邀请';

  @override
  String get accessRequests => '访问请求';

  @override
  String get approve => '批准';

  @override
  String get deny => '拒绝';

  @override
  String get invitedGroups => '受邀群组';

  @override
  String get planner => 'Planner';

  @override
  String get thatGroupLosesAccessToThis => '该群组将失去对此群组的访问权限。';

  @override
  String makeP0(Object p0) {
    return '设为$p0';
  }

  @override
  String theyLoseP0Access(Object p0) {
    return '将失去$p0访问权限。';
  }

  @override
  String get usernameUserIdOrEmail => '用户名、用户 ID 或邮箱';

  @override
  String get jane42OrJaneExampleCom => 'jane、42 或 jane@example.com';

  @override
  String get invite => '邀请';

  @override
  String memberDisplay(Object p0, Object p1) {
    return '$p0 @$p1';
  }

  @override
  String get rolePlanner => 'Planner';

  @override
  String get roleMinimal => '最小权限';

  @override
  String roleLevelOther(Object p0) {
    return '级别 $p0';
  }

  @override
  String expiresDate(Object p0) {
    return '$p0 到期';
  }

  @override
  String get memberIdentifierRequired => '需要填写用户名、用户 ID 或邮箱';

  @override
  String get memberAddFailed => '无法添加成员';

  @override
  String get noExpiration => '无到期时间';

  @override
  String expiresOn(Object p0) {
    return '$p0 到期';
  }

  @override
  String get projectWord => '项目';

  @override
  String get groupWord => '群组';

  @override
  String get linkedIssues => '关联议题';

  @override
  String get link => '链接';

  @override
  String get noLinkedIssues => '没有关联议题';

  @override
  String get linkIssue => '链接议题';

  @override
  String get projectOptional => '项目（可选）';

  @override
  String get groupOtherProject => 'group/other-project';

  @override
  String get linkType => '链接类型';

  @override
  String get relatesTo => '关联';

  @override
  String get blocks => '阻塞';

  @override
  String get blockedBy => '被阻塞';

  @override
  String get removeLink => '移除链接？';

  @override
  String unlinkP0FromThisIssue(Object p0) {
    return '从此议题取消链接 #$p0。';
  }

  @override
  String get relatedMergeRequests => '相关合并请求';

  @override
  String get willBeClosedBy => '将被关闭';

  @override
  String get noRelatedMergeRequests => '没有相关合并请求';

  @override
  String moreCount(Object p0) {
    return '+$p0';
  }

  @override
  String linkSummary(Object p0, Object p1) {
    return '$p0 · $p1';
  }

  @override
  String get issueIidField => '议题 #';

  @override
  String get removeLinkTooltip => '移除链接';

  @override
  String get markdownSupported => '支持 Markdown';

  @override
  String get weight => '权重';

  @override
  String get confidential => '保密';

  @override
  String get onlyVisibleToMembersAndAssignees => '仅成员和负责人可见';

  @override
  String get createIssue => '创建议题';

  @override
  String get moveIssue => '移动议题';

  @override
  String get destinationProject => '目标项目';

  @override
  String get groupProject => 'group/project';

  @override
  String get move => '移动';

  @override
  String get issueWeight => '议题权重';

  @override
  String get emptyClearsTheWeight => '留空则清除权重';

  @override
  String get enterAWholeNumber => '输入整数';

  @override
  String get timeEstimate => '时间估计';

  @override
  String get addTimeSpent => '添加已用时间';

  @override
  String get closeIssue => '关闭议题';

  @override
  String get reopenIssue => '重新打开议题';

  @override
  String get unsubscribe => '取消订阅';

  @override
  String get subscribe => '订阅';

  @override
  String get setTimeEstimate => '设置时间估计';

  @override
  String get resetTimeSpent => '重置已用时间';

  @override
  String get setWeight => '设置权重';

  @override
  String get cloneIssue => '克隆议题';

  @override
  String get copyLink => '复制链接';

  @override
  String get noCommentsYet => '暂无评论';

  @override
  String issueDueDate(Object p0) {
    return '$p0 到期';
  }

  @override
  String issueWeightValue(Object p0) {
    return '权重 $p0';
  }

  @override
  String get enterProjectPath => '输入项目路径';

  @override
  String closedByName(Object p0) {
    return '由 $p0 关闭';
  }

  @override
  String tasksStatus(Object p0) {
    return '任务 $p0';
  }

  @override
  String openedByAt(Object p0, Object p1) {
    return '$p0 于 $p1 打开';
  }

  @override
  String timeSpentOf(Object p0, Object p1) {
    return '已用 $p0 / 共 $p1';
  }

  @override
  String get runPipeline => '运行流水线';

  @override
  String get noPipelinesForThisMr => '此 MR 没有流水线';

  @override
  String relatedMergeRequestP0(Object p0) {
    return '相关合并请求';
  }

  @override
  String closesIssues(Object p0, Object p1) {
    return '关闭 $p0 个议题';
  }

  @override
  String get mrTileDraft => '草稿：';

  @override
  String get sourceBranch => '源分支';

  @override
  String get targetBranch => '目标分支';

  @override
  String get reviewers => '审查者';

  @override
  String get createMr => '创建 MR';

  @override
  String get titleRequired => '标题必填';

  @override
  String get mrPickBranches => '请选择源分支和目标分支';

  @override
  String get mrSaveFailed => '无法保存合并请求';

  @override
  String get editMr => '编辑合并请求';

  @override
  String get newMr => '新建合并请求';

  @override
  String get resolved => '已解决';

  @override
  String get resolve => '解决';

  @override
  String get replyHint => '回复…';

  @override
  String get actionReply => '回复';

  @override
  String get changes => '变更';

  @override
  String get loadMoreFailedRetry => '加载更多失败。重试';

  @override
  String get draft => '草稿';

  @override
  String get scheduledToMergeWhenThePipeline => '计划在流水线成功后合并';

  @override
  String get merge => '合并';

  @override
  String get revokeApproval => '撤销批准';

  @override
  String get cancelAutoMerge => '取消自动合并';

  @override
  String get mergeWhenPipelineSucceeds => '流水线成功后合并';

  @override
  String mergeP0(Object p0) {
    return '合并 !$p0';
  }

  @override
  String get deleteSourceBranch => '删除源分支';

  @override
  String get mergesAutomaticallyOnceThePipelineSucceeds => '流水线成功后自动合并。';

  @override
  String get setAutoMerge => '设置自动合并';

  @override
  String get closeMr => '关闭 MR';

  @override
  String get reopenMr => '重新打开 MR';

  @override
  String get markAsReady => '标记为就绪';

  @override
  String get markAsDraft => '标记为草稿';

  @override
  String get rebase => '变基';

  @override
  String get cherryPick => '拣选';

  @override
  String get revert => '还原';

  @override
  String get downloadPatch => '下载补丁';

  @override
  String get noChanges => '没有变更';

  @override
  String get latestChanges => '最新变更';

  @override
  String get review => '审查';

  @override
  String get publish => '发布';

  @override
  String get submitReview => '提交审查？';

  @override
  String get allPendingCommentsBecomeVisible => '所有待处理评论将变为可见。';

  @override
  String get publishAll => '全部发布';

  @override
  String get noPendingComments => '没有待处理评论。';

  @override
  String get binaryFileOrDiffTooLarge => '二进制文件或 diff 过大';

  @override
  String get writeAComment => '写评论…';

  @override
  String get addToReview => '加入审查';

  @override
  String get comment => '评论';

  @override
  String get missingDiffRefsRefreshTheMr => '缺少 diff 引用。请刷新 MR 后重试。';

  @override
  String get noCommits => '没有提交';

  @override
  String get contextCommits => '上下文提交';

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
    return '由 $p0 于 $p1 合并';
  }

  @override
  String pendingComments(Object p0, Object p1) {
    return '你的审查中有 $p0 条待处理评论';
  }

  @override
  String versionEntry(Object p0, Object p1, Object p2, Object p3) {
    return '版本 $p0 · $p1 · $p2 个文件';
  }

  @override
  String commentOnLine(Object p0, Object p1) {
    return '评论 $p0:$p1';
  }

  @override
  String get searchMilestones => '搜索里程碑';

  @override
  String get newMilestone => '新建里程碑';

  @override
  String get noMilestones => '没有里程碑';

  @override
  String get milestone => '里程碑';

  @override
  String get active => '进行中';

  @override
  String get startDate => '开始日期';

  @override
  String get dueDate => '截止日期';

  @override
  String get createMilestone => '创建里程碑';

  @override
  String get searchLabels => '搜索标签';

  @override
  String get newLabel => '新建标签';

  @override
  String get noLabels => '没有标签';

  @override
  String p0Issues(Object p0) {
    return '$p0 个议题';
  }

  @override
  String get promoteToGroup => '提升到群组';

  @override
  String promoteP0(Object p0) {
    return '提升 $p0？';
  }

  @override
  String get promote => '提升';

  @override
  String get theLabelIsRemovedFromEvery => '该标签将从每个议题和 MR 上移除。';

  @override
  String get bugOrPriorityHigh => 'bug 或 priority::high';

  @override
  String get color => '颜色';

  @override
  String get createLabel => '创建标签';

  @override
  String get labelPromoteBody => '标签将移动到父群组，并在使用它的每个议题和 MR 上被替换。';

  @override
  String startsOn(Object p0) {
    return '$p0 开始';
  }

  @override
  String dueOn(Object p0) {
    return '$p0 截止';
  }

  @override
  String get milestoneSaveFailed => '无法保存里程碑';

  @override
  String get editMilestone => '编辑里程碑';

  @override
  String get nameRequired => '名称必填';

  @override
  String get labelSaveFailed => '无法保存标签';

  @override
  String get editLabel => '编辑标签';

  @override
  String get labelPreview => '标签预览';

  @override
  String get stateActive => '进行中';

  @override
  String get runs => '运行';

  @override
  String get schedules => '调度';

  @override
  String get source => '来源';

  @override
  String get ref => '引用';

  @override
  String get user => '用户';

  @override
  String get noPipelinesYet => '暂无流水线';

  @override
  String get scope => '范围';

  @override
  String get noJobs => '没有作业';

  @override
  String get ciLint => 'CI Lint';

  @override
  String get stagesNBuild => 'stages:\n  - build';

  @override
  String get checking => '检查中…';

  @override
  String get validate => '验证';

  @override
  String p0Jobs(Object p0) {
    return '$p0 个作业';
  }

  @override
  String get pipelineStatusRunning => '运行中';

  @override
  String get pipelineStatusPending => '等待中';

  @override
  String get pipelineStatusSuccess => '已通过';

  @override
  String get pipelineStatusFailed => '失败';

  @override
  String get pipelineStatusCanceled => '已取消';

  @override
  String get pipelineStatusSkipped => '已跳过';

  @override
  String get pipelineStatusManual => '手动';

  @override
  String get pipelineSourcePush => '推送';

  @override
  String get pipelineSourceWeb => 'Web';

  @override
  String get pipelineSourceSchedule => '调度';

  @override
  String get pipelineSourceApi => 'API';

  @override
  String get pipelineSourceTrigger => '触发器';

  @override
  String get pipelineSourceMr => '合并请求';

  @override
  String get pipelineSourcePipeline => '流水线';

  @override
  String get pipelineSourceChat => '聊天';

  @override
  String get newSchedule => '新建调度';

  @override
  String get noScheduledPipelines => '没有调度的流水线';

  @override
  String get recentRuns => '最近运行';

  @override
  String get runNow => '立即运行';

  @override
  String get takeOwnership => '取得所有权';

  @override
  String get scheduleTriggered => '调度已触发';

  @override
  String get deleteSchedule => '删除调度？';

  @override
  String get noRunsYet => '暂无运行';

  @override
  String get editSchedule => '编辑调度';

  @override
  String get targetRef => '目标引用';

  @override
  String get cron => 'Cron';

  @override
  String get timezone => '时区';

  @override
  String get utc => 'UTC';

  @override
  String get key => '键';

  @override
  String artifactsJobP0(Object p0) {
    return '作业 $p0 的产物';
  }

  @override
  String get archiveIsEmpty => '归档为空';

  @override
  String get binaryFileUseShareToSave => '二进制文件。使用分享保存。';

  @override
  String quotedName(Object p0) {
    return '“$p0”';
  }

  @override
  String scheduleId(Object p0) {
    return '调度 #$p0';
  }

  @override
  String get pickTargetRef => '请选择目标引用';

  @override
  String get varKeysUnique => '变量键必须唯一';

  @override
  String get scheduleSaveFailed => '无法保存调度';

  @override
  String scheduleStopsRunning(Object p0) {
    return '“$p0”将停止运行。';
  }

  @override
  String jobP0(Object p0) {
    return '作业 #$p0';
  }

  @override
  String get erase => '清除';

  @override
  String get browseArtifacts => '浏览产物';

  @override
  String get keepArtifacts => '保留产物';

  @override
  String byP0(Object p0) {
    return '由 $p0';
  }

  @override
  String get copyTrace => '复制日志';

  @override
  String pipelineP0(Object p0) {
    return '流水线 #$p0';
  }

  @override
  String get stages => '阶段';

  @override
  String get tests => '测试';

  @override
  String get downstream => '下游';

  @override
  String get noJobsInThisPipeline => '此流水线没有作业';

  @override
  String get allowedToFail => '允许失败';

  @override
  String get noTestReport => '没有测试报告';

  @override
  String get total => '总计';

  @override
  String get errors => '错误';

  @override
  String get coverage => '覆盖率';

  @override
  String get thisPipelineRanWithoutExtraVariables => '此流水线没有使用额外变量运行。';

  @override
  String get noDownstreamPipelines => '没有下游流水线';

  @override
  String get thisPipelineDidNotTriggerAny => '此流水线未触发任何子流水线。';

  @override
  String statText(Object p0, Object p1, Object p2) {
    return '$p0 $p1$p2';
  }

  @override
  String durationInSecs(Object p0) {
    return '$p0 秒内';
  }

  @override
  String secsValue(Object p0) {
    return '$p0 秒';
  }

  @override
  String refAtSha(Object p0, Object p1) {
    return '$p0 @ $p1';
  }

  @override
  String get eraseJobConfirm => '清除作业？';

  @override
  String get deleteArtifactsConfirm => '删除产物？';

  @override
  String get deleteArtifactsAction => '删除产物';

  @override
  String get eraseJobAction => '清除作业';

  @override
  String get hideRetriedJobs => '隐藏重试作业';

  @override
  String get showRetriedJobs => '显示重试作业';

  @override
  String get runManualJob => '运行手动作业';

  @override
  String get eraseJobBody => '日志和产物将被永久移除。';

  @override
  String get deleteArtifactsBody => '锁定的产物可能保留。需要维护者权限。';

  @override
  String get profile => '个人资料';

  @override
  String get editProfile => '编辑资料';

  @override
  String joinedP0(Object p0) {
    return '$p0 加入';
  }

  @override
  String p0Followers(Object p0) {
    return '$p0 位关注者';
  }

  @override
  String p0Following(Object p0) {
    return '正在关注 $p0 人';
  }

  @override
  String get unfollow => '取消关注';

  @override
  String get follow => '关注';

  @override
  String p0ContributionsInTheLastYear(Object p0) {
    return '过去一年 $p0 次贡献';
  }

  @override
  String get statusEmoji => '状态表情';

  @override
  String get eG => '例如 🌴';

  @override
  String get statusMessage => '状态消息';

  @override
  String get memberships => '成员关系';

  @override
  String get fieldPronouns => '代称';

  @override
  String get fieldJobTitle => '职位';

  @override
  String get fieldOrganization => '组织';

  @override
  String get fieldLocation => '位置';

  @override
  String get fieldPublicEmail => '公开邮箱';

  @override
  String get fieldWebsite => '网站';

  @override
  String get fieldTwitter => 'Twitter';

  @override
  String get fieldLinkedin => 'LinkedIn';

  @override
  String get fieldBio => '简介';

  @override
  String get followers => '关注者';

  @override
  String get following => '正在关注';

  @override
  String get searchPackages => '搜索包';

  @override
  String get type => '类型';

  @override
  String get noPackages => '没有包';

  @override
  String get deletePackage => '删除包？';

  @override
  String p0IsRemovedPermanently(Object p0) {
    return '“$p0”将被永久移除。';
  }

  @override
  String get noFiles => '没有文件';

  @override
  String get noContainerImages => '没有容器镜像';

  @override
  String get deleteRepository => '删除仓库？';

  @override
  String p0AndAllItsTagsAre(Object p0) {
    return '“$p0”及其所有标签将被移除。';
  }

  @override
  String get filterTagsRegex => '过滤标签（正则）';

  @override
  String get noTags => '没有标签';

  @override
  String get deleteTag => '删除标签？';

  @override
  String get emptyDirectory => '空目录';

  @override
  String get downloadSource => '下载源码';

  @override
  String get newFile => '新建文件';

  @override
  String get switchBranch => '切换分支';

  @override
  String get editFile => '编辑文件';

  @override
  String get copyContents => '复制内容';

  @override
  String get fileHistory => '文件历史';

  @override
  String get viewBlame => '查看 blame';

  @override
  String get deleteFile => '删除文件';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get aCommitRemovingThisFileWill => '将创建一个删除此文件的提交。';

  @override
  String editP0(Object p0) {
    return '编辑 $p0';
  }

  @override
  String get template => '模板';

  @override
  String get commit => '提交';

  @override
  String get filePath => '文件路径';

  @override
  String get commitMessage => '提交信息';

  @override
  String get fileContents => '文件内容';

  @override
  String commitsToP0(Object p0) {
    return '提交到 $p0';
  }

  @override
  String get noTemplates => '没有模板';

  @override
  String get searchBranches => '搜索分支';

  @override
  String get compare => '比较';

  @override
  String get deleteMerged => '删除已合并分支';

  @override
  String get newBranch => '新建分支';

  @override
  String get noBranches => '没有分支';

  @override
  String get branchName => '分支名';

  @override
  String get sourceRefBranchTagOrSha => '源引用（分支、标签或 sha）';

  @override
  String get deleteMergedBranches => '删除已合并的分支？';

  @override
  String get deleteBranch => '删除分支';

  @override
  String get deleteMergedBody => '将移除所有已合并到默认分支的分支。受保护分支会被保留。';

  @override
  String get templateGitignore => 'Gitignore';

  @override
  String get templateLicense => '许可证';

  @override
  String get templateGitlabCi => 'GitLab CI';

  @override
  String get templateDockerfile => 'Dockerfile';

  @override
  String couldNotLoadTheDiffP0(Object p0) {
    return '无法加载 diff：$p0';
  }

  @override
  String get couldNotPostTheComment => '无法发布评论';

  @override
  String get cherryPickToBranch => '拣选到分支';

  @override
  String get revertOnBranch => '在分支上还原';

  @override
  String get copySha => '复制 SHA';

  @override
  String parentsP0(Object p0) {
    return '父提交：$p0';
  }

  @override
  String get checks => '检查';

  @override
  String get on => '于';

  @override
  String couldNotLoadCommentsP0(Object p0) {
    return '无法加载评论（$p0）';
  }

  @override
  String get commentOnThisCommit => '评论此提交';

  @override
  String get diffTooLargeOrBinaryView => 'Diff 过大或为二进制文件。请在网页上查看';

  @override
  String deletionsMinus(Object p0) {
    return '−$p0';
  }

  @override
  String diffStats(Object p0, Object p1) {
    return '+$p0 −$p1';
  }

  @override
  String get cherryPicked => '已拣选';

  @override
  String get reverted => '已还原';

  @override
  String cherryRevertDone(Object p0, Object p1) {
    return '$p0，提交为 $p1';
  }

  @override
  String get fileSingular => '个文件';

  @override
  String get filePlural => '个文件';

  @override
  String get searchTags => '搜索标签';

  @override
  String get newTag => '新建标签';

  @override
  String get tagName => '标签名';

  @override
  String get sourceRefBranchOrSha => '源引用（分支或 sha）';

  @override
  String get messageOptional => '消息（可选）';

  @override
  String deleteTagP0(Object p0) {
    return '删除标签 $p0？';
  }

  @override
  String get downloadArchive => '下载归档';

  @override
  String get generateChangelog => '生成更新日志';

  @override
  String get deleteTag2 => '删除标签';

  @override
  String get version => '版本';

  @override
  String get fromRefOptional => '起始引用（可选）';

  @override
  String get toRefOptional => '目标引用（可选）';

  @override
  String get preview => '预览';

  @override
  String get changelogCommitted => '更新日志已提交';

  @override
  String get newRelease => '新建发布';

  @override
  String get noReleasesYet => '暂无发布';

  @override
  String get tagNewOrExisting => '标签（新建或已有）';

  @override
  String get releaseName => '发布名称';

  @override
  String get releaseNotes => '发布说明';

  @override
  String get theReleaseIsRemovedTheTag => '发布被移除；标签保留。';

  @override
  String get addAssetLink => '添加资产链接';

  @override
  String get editLink => '编辑链接';

  @override
  String get runbook => '运行手册';

  @override
  String get image => '镜像';

  @override
  String get package => '包';

  @override
  String get other => '其他';

  @override
  String get filepathOptional => '文件路径（可选）';

  @override
  String get onlyTheLinkIsRemovedAssets => '仅移除链接；资产保留。';

  @override
  String evidenceP0(Object p0) {
    return '证据 · $p0';
  }

  @override
  String shaP0(Object p0) {
    return 'SHA：$p0';
  }

  @override
  String fileP0(Object p0) {
    return '文件：$p0';
  }

  @override
  String collectedP0(Object p0) {
    return '收集于：$p0';
  }

  @override
  String get releaseActions => '发布操作';

  @override
  String get evidence => '证据';

  @override
  String get addLink => '添加链接';

  @override
  String get base => '基准';

  @override
  String get swapRefs => '交换引用';

  @override
  String get pickTwoRefs => '选择两个引用';

  @override
  String get branchesTagsOrCommitShas => '分支、标签或提交 SHA';

  @override
  String get enterARef => '输入引用';

  @override
  String get branchTagOrCommitSha => '分支、标签或提交 SHA';

  @override
  String get useRef => '使用引用';

  @override
  String get theseRefsPointAtTheSame => '这两个引用指向同一个提交';

  @override
  String get comparisonTimedOutResultsMayBe => '比较超时；结果可能不完整';

  @override
  String get nothingNewOnTheCompareRef => '比较引用上没有新内容';

  @override
  String get nothingToBlame => '没有可 blame 的内容';

  @override
  String get mergeBasePrefix => '合并基准 ';

  @override
  String titleSuffix(Object p0) {
    return ' · $p0';
  }

  @override
  String tagReleasedAt(Object p0, Object p1) {
    return '$p0 · $p1';
  }

  @override
  String get noEvidenceCollected => '未收集到证据';

  @override
  String get searchGitlab => '搜索 GitLab';

  @override
  String get projectsIssuesMergeRequestsCodeAnd => '项目、议题、合并请求、代码等。';

  @override
  String get noResults => '没有结果';

  @override
  String get markAllDone => '全部标为完成';

  @override
  String get nothingOnYourPlate => '没有待办事项';

  @override
  String get markDone => '标为完成';

  @override
  String get newPage => '新建页面';

  @override
  String get noWikiPages => '没有 wiki 页面';

  @override
  String get deletePage => '删除页面？';

  @override
  String get thisCannotBeUndone => '此操作无法撤销。';

  @override
  String get content => '内容';

  @override
  String get markdown => 'Markdown';

  @override
  String get attachFile => '附加文件';

  @override
  String get createPage => '创建页面';

  @override
  String lineColon(Object p0) {
    return ':$p0';
  }

  @override
  String commitMeta(Object p0, Object p1, Object p2) {
    return '$p0 · $p1 · $p2';
  }

  @override
  String get contentRequired => '内容必填';

  @override
  String get pageSaveFailed => '无法保存页面';

  @override
  String get editPage => '编辑页面';

  @override
  String get newWikiPage => '新建 wiki 页面';

  @override
  String get searchSnippets => '搜索代码片段';

  @override
  String get newSnippet => '新建代码片段';

  @override
  String get noSnippetsYet => '暂无代码片段';

  @override
  String get noSnippets => '没有代码片段';

  @override
  String get snippet => '代码片段';

  @override
  String get deleteSnippet => '删除代码片段？';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get fileName => '文件名';

  @override
  String get createSnippet => '创建代码片段';

  @override
  String get fileNameRequired => '文件名必填';

  @override
  String get snippetSaveFailed => '无法保存代码片段';

  @override
  String get editSnippet => '编辑代码片段';

  @override
  String get stateLocked => '已锁定';

  @override
  String p0StopsWorkingImmediately(Object p0) {
    return '“$p0”将立即停止工作。';
  }

  @override
  String stateEventLine(Object p0, Object p1, Object p2) {
    return '$p0 $p1$p2';
  }

  @override
  String milestoneEventLine(Object p0, Object p1, Object p2, Object p3) {
    return '$p0里程碑 $p1 $p2$p3';
  }

  @override
  String labelEventLine(Object p0, Object p1, Object p2, Object p3) {
    return '$p0标签 $p1 $p2$p3';
  }

  @override
  String byUser(Object p0) {
    return '由 $p0 ';
  }

  @override
  String get eventReopened => '重新打开';

  @override
  String get eventRemoved => '移除';

  @override
  String get eventAdded => '添加';

  @override
  String get deletedUser => '已注销用户';

  @override
  String runnerId(Object p0) {
    return 'Runner #$p0';
  }

  @override
  String envScope(Object p0) {
    return '环境：$p0';
  }

  @override
  String get varFile => '文件';

  @override
  String get historyTitle => '历史';

  @override
  String get commitsTitle => '提交';

  @override
  String get projectAccessTokens => '项目访问令牌';

  @override
  String get mergeRequestApprovals => '合并请求审批';

  @override
  String p0Required(Object p0) {
    return '需要 $p0 个';
  }

  @override
  String p0Eligible(Object p0) {
    return '$p0 个可审批';
  }

  @override
  String get includesHiddenGroups => '包含隐藏群组';

  @override
  String get deployKeys => '部署密钥';

  @override
  String get writeAccess => '写权限';

  @override
  String addedP0(Object p0) {
    return '添加于 $p0';
  }

  @override
  String get pages => 'Pages';

  @override
  String get autoSsl => 'Auto SSL';

  @override
  String certExpiresP0(Object p0) {
    return '证书到期 $p0';
  }

  @override
  String pushP0(Object p0) {
    return '推送：$p0';
  }

  @override
  String mergeP02(Object p0) {
    return '合并：$p0';
  }

  @override
  String get forcePushAllowed => '允许强制推送';

  @override
  String get allowedToDeploy => '允许部署';

  @override
  String get unprotectEnvironment => '取消环境保护？';

  @override
  String deployP0(Object p0) {
    return '部署：$p0';
  }

  @override
  String get deployFreezes => '部署冻结';

  @override
  String get addFreeze => '添加冻结';

  @override
  String get noDeployFreezes => '没有部署冻结';

  @override
  String get addDeployFreeze => '添加部署冻结';

  @override
  String get editFreeze => '编辑冻结';

  @override
  String get freezeStartCron => '冻结开始（cron）';

  @override
  String get freezeEndCron => '冻结结束（cron）';

  @override
  String get deleteDeployFreeze => '删除部署冻结？';

  @override
  String get mirroringRepositories => '镜像仓库';

  @override
  String get syncNow => '立即同步';

  @override
  String get noMirrors => '没有镜像';

  @override
  String get mirrorRepository => '镜像仓库';

  @override
  String get gitRepositoryUrl => 'Git 仓库 URL';

  @override
  String get branchRegexOptional => '分支正则（可选）';

  @override
  String get onlyProtectedBranches => '仅受保护分支';

  @override
  String get keepDivergentRefs => '保留分叉引用';

  @override
  String get deleteMirror => '删除镜像？';

  @override
  String get protectedOnly => '仅受保护';

  @override
  String get keepDivergent => '保留分叉';

  @override
  String errorP0(Object p0) {
    return '错误：$p0';
  }

  @override
  String syncedP0(Object p0) {
    return '已同步 $p0';
  }

  @override
  String createP0(Object p0) {
    return '创建：$p0';
  }

  @override
  String get ciCd => 'CI/CD';

  @override
  String p0NoLongerGatesMerges(Object p0) {
    return '“$p0”不再阻止合并。';
  }

  @override
  String p0WillStopServingThisPages(Object p0) {
    return '“$p0”将停止提供此 Pages 站点。';
  }

  @override
  String get theSiteGoesOfflineUntilThe => '站点将离线，直到下一次 Pages 部署。';

  @override
  String p0WillAcceptPushesAgain(Object p0) {
    return '“$p0”将再次接受推送。';
  }

  @override
  String p0CanBeCreatedByAnyone(Object p0) {
    return '任何有推送权限的人都可以创建“$p0”。';
  }

  @override
  String p0WillAcceptDeploysAgain(Object p0) {
    return '“$p0”将再次接受部署。';
  }

  @override
  String p0ToP1WillBeRemoved(Object p0, Object p1) {
    return '“$p0”到“$p1”将被移除。';
  }

  @override
  String syncingFromP0WillStop(Object p0) {
    return '从 $p0 同步将停止。';
  }

  @override
  String get mergeMethodCommit => '合并提交';

  @override
  String get mergeMethodRebase => '变基并合并';

  @override
  String get mergeMethodFf => '快进合并';

  @override
  String get squashNever => '不允许';

  @override
  String get squashAlways => '必须';

  @override
  String get squashDefaultOn => '允许，默认开启';

  @override
  String get squashDefaultOff => '允许，默认关闭';

  @override
  String get templateDefault => '默认';

  @override
  String get exportReady => '可下载';

  @override
  String get exportQueued => '排队中';

  @override
  String get exportRunning => '导出中';

  @override
  String get exportRegenerating => '重新生成中';

  @override
  String get exportFailed => '导出失败';

  @override
  String get exportNone => '暂无导出';

  @override
  String get runnerOnline => '在线';

  @override
  String get runnerOffline => '离线';

  @override
  String get runnerStale => '过期';

  @override
  String get runnerNeverContacted => '从未连接';

  @override
  String get statusUnknown => '未知';

  @override
  String get hookEventPush => '推送';

  @override
  String get hookEventTagPush => '标签推送';

  @override
  String get hookEventIssues => '议题';

  @override
  String get hookEventComments => '评论';

  @override
  String get hookEventMrs => '合并请求';

  @override
  String get hookEventPipeline => '流水线';

  @override
  String get hookEventJob => '作业';

  @override
  String get hookEventSubgroup => '子群组';

  @override
  String get positiveNumberRequired => '必须是正数';

  @override
  String get enterNumber => '请输入数字';

  @override
  String get addApprovalRule => '添加审批规则';

  @override
  String get editApprovalRule => '编辑审批规则';

  @override
  String get notSet => '未设置';

  @override
  String approvalsValue(Object p0, Object p1) {
    return '$p0 个审批';
  }

  @override
  String secondsValue(Object p0) {
    return '$p0 秒';
  }

  @override
  String get pagesSite => 'Pages 站点';

  @override
  String runnerStopsRunning(Object p0) {
    return '“$p0”将停止运行此项目的作业。';
  }

  @override
  String get secureFileDeleteBody => '引用它的流水线将失败。';

  @override
  String shareRemoveBody(Object p0) {
    return '“$p0”将失去对此项目的访问权限。';
  }

  @override
  String lastUsedAt(Object p0) {
    return '最后使用 $p0';
  }

  @override
  String get neverUsed => '从未使用';

  @override
  String get triggerDeleteBody => '使用此令牌的请求将停止工作。';

  @override
  String get storageRepository => '仓库';

  @override
  String get storageLfs => 'LFS 对象';

  @override
  String get storageJobArtifacts => '作业产物';

  @override
  String get storagePackages => '包';

  @override
  String get storageUploads => '上传';

  @override
  String get storageWiki => 'Wiki';

  @override
  String get storageSnippets => '代码片段';

  @override
  String get storageRegistry => '容器注册表';

  @override
  String get errNetwork => '无法连接服务器';

  @override
  String get errUnauthorized => '会话已过期，请重新登录';

  @override
  String get errForbidden => '你没有访问权限';

  @override
  String get errNotFound => '未找到';

  @override
  String get errConflict => '请求与当前状态冲突';

  @override
  String get errServer => '服务器出现问题';

  @override
  String get errUnknown => '出现错误';

  @override
  String get errFileTooLarge => '文件过大，无法在应用中显示';

  @override
  String get errTooManyRedirects => '重定向次数过多';

  @override
  String get errBadArchive => '无法读取产物归档';

  @override
  String get settingsAppearance => '外观';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsSession => '会话';

  @override
  String signedInAs(Object p0) {
    return '已登录为 @$p0';
  }

  @override
  String get settingsAbout => '关于';

  @override
  String get aboutTagline => '适用于桌面和移动端的 GitLab 客户端';

  @override
  String get aboutInstance => 'GitLab 实例';

  @override
  String aboutVersion(Object p0) {
    return '版本 $p0';
  }

  @override
  String aboutVersionRev(Object p0, Object p1) {
    return '版本 $p0（$p1）';
  }

  @override
  String get aboutVersionChecking => '正在检查版本…';

  @override
  String get aboutVersionUnavailable => '版本不可用';

  @override
  String get signOutConfirmTitle => '退出登录？';

  @override
  String get signOutConfirmBody => '你的令牌将从此设备移除。';

  @override
  String get reactionThumbsup => '点赞';

  @override
  String get reactionThumbsdown => '踩';

  @override
  String get reactionSmile => '微笑';

  @override
  String get reactionTada => '庆祝';

  @override
  String get reactionHeart => '爱心';

  @override
  String get notConfidential => '非保密';

  @override
  String get dueFilter => '截止日期';

  @override
  String get dueOverdue => '已逾期';

  @override
  String get dueThisWeek => '本周截止';

  @override
  String get dueThisMonth => '本月截止';

  @override
  String get dueSoon => '即将截止';

  @override
  String get noDueDate => '无截止日期';

  @override
  String get reactedFilter => '已表态';

  @override
  String get last24h => '最近 24 小时';

  @override
  String get lastWeek => '最近一周';

  @override
  String get lastMonth => '最近一个月';

  @override
  String get newIssue => '新建议题';

  @override
  String get noIssuesMatchFilter => '没有符合此筛选条件的议题';

  @override
  String get assignee => '指派人';

  @override
  String get author => '作者';

  @override
  String get labelFilter => '标签';

  @override
  String get issueTypeIssue => '议题';

  @override
  String get issueTypeIncident => '事故';

  @override
  String get issueTypeTask => '任务';

  @override
  String get issueTypeTestCase => '测试用例';

  @override
  String get draftsOnly => '仅草稿';

  @override
  String get noDrafts => '排除草稿';

  @override
  String get noMrsMatchFilter => '没有符合此筛选条件的合并请求';

  @override
  String get mrScopeAssigned => '指派给我';

  @override
  String get mrScopeCreated => '由我创建';

  @override
  String get mrScopeReview => '请我评审';

  @override
  String get scopeFilter => '范围';

  @override
  String get branchFilter => '分支';

  @override
  String get todoPending => '待处理';

  @override
  String get todoDone => '已完成';

  @override
  String get targetIssue => '议题';

  @override
  String get targetMr => '合并请求';

  @override
  String get targetEpic => '史诗';

  @override
  String get envAvailable => '可用';

  @override
  String get envStopped => '已停止';

  @override
  String get searchEnvironments => '搜索环境';

  @override
  String get newUserList => '新建用户列表';

  @override
  String editNamed(Object p0) {
    return '编辑 $p0';
  }
}
