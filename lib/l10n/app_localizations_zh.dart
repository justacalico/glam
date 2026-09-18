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
}
