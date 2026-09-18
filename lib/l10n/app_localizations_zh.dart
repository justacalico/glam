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
}
