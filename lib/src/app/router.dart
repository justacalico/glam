import 'package:flutter/widgets.dart';

/// Central place for route paths + typed builders.
///
/// File paths and branch names can contain `/`, so they travel as query
/// parameters (`?ref=&path=`) rather than path segments.
abstract final class Routes {
  static const login = '/login';

  static const home = '/home';
  static const projects = '/projects';
  static const issues = '/issues';
  static const mergeRequests = '/merge-requests';
  static const todos = '/todos';
  static const activity = '/activity';
  static const snippets = '/snippets';
  static const groups = '/groups';
  static const search = '/search';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static const profile = '/profile';
  static String user(int id) => '/users/$id';

  static String project(Object id) => '/projects/$id';
  static String projectTree(Object id, {String? ref, String? path}) =>
      _qs('/projects/$id/tree', {'ref': ref, 'path': path});
  static String projectBlob(Object id, {String? ref, String? path}) =>
      _qs('/projects/$id/blob', {'ref': ref, 'path': path});
  static String projectBlame(Object id, {String? ref, String? path}) =>
      _qs('/projects/$id/blame', {'ref': ref, 'path': path});
  static String projectCommits(Object id, {String? ref}) =>
      _qs('/projects/$id/commits', {'ref': ref});
  static String projectCommit(Object id, String sha) =>
      '/projects/$id/commit/$sha';
  static String projectBranches(Object id) => '/projects/$id/branches';
  static String projectTags(Object id) => '/projects/$id/tags';
  static String projectReleases(Object id) => '/projects/$id/releases';
  static String projectMembers(Object id) => '/projects/$id/members';
  static String projectIssues(Object id) => '/projects/$id/issues';
  static String projectIssue(Object id, int iid) => '/projects/$id/issues/$iid';
  static String projectMrs(Object id) => '/projects/$id/mrs';
  static String projectMr(Object id, int iid) => '/projects/$id/mrs/$iid';
  static String projectPipelines(Object id) => '/projects/$id/pipelines';
  static String projectPipeline(Object id, int pid) =>
      '/projects/$id/pipelines/$pid';
  static String projectJob(Object id, int jid) => '/projects/$id/jobs/$jid';
  static String projectMilestones(Object id) => '/projects/$id/milestones';
  static String projectLabels(Object id) => '/projects/$id/labels';
  static String projectWiki(Object id) => '/projects/$id/wiki';
  static String projectSnippets(Object id) => '/projects/$id/snippets';
  static String projectBoards(Object id) => '/projects/$id/boards';
  static String projectEnvironment(Object id, int envId) =>
      '/projects/$id/environments/$envId';
  static String projectSearch(Object id) => '/projects/$id/search';
  static String projectRegistry(Object id, int rid) =>
      '/projects/$id/registry/$rid';
  static String projectSettings(Object id) => '/projects/$id/settings';

  static String group(int id) => '/groups/$id';
  static String groupSearch(Object id) => '/groups/$id/search';

  static String _qs(String base, Map<String, String?> params) {
    final clean = Map<String, String>.fromEntries(
      params.entries
          .where((e) => e.value != null && e.value!.isNotEmpty)
          .map((e) => MapEntry(e.key, e.value!)),
    );
    if (clean.isEmpty) {
      return base;
    }
    return '$base?${Uri(queryParameters: clean).query}';
  }
}

/// A route change needs the latest auth state; this bridges Riverpod to
/// go_router's [Listenable].
class RouterRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
