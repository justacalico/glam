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
}
