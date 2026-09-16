import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/auth/domain/user.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';
import 'package:glam/src/features/search/domain/search_result.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';

/// What to search. Global search supports every value; a project-scoped
/// search swaps the API path.
enum SearchScope {
  projects('Projects', 'projects'),
  issues('Issues', 'issues'),
  mergeRequests('MRs', 'merge_requests'),
  commits('Commits', 'commits'),
  blobs('Code', 'blobs'),
  wiki('Wiki', 'wiki_blobs'),
  notes('Comments', 'notes'),
  milestones('Milestones', 'milestones'),
  users('Users', 'users'),
  snippetTitles('Snippets', 'snippet_titles'),
  snippetBlobs('Snippet code', 'snippet_blobs');

  const SearchScope(this.label, this.apiName);

  final String label;

  /// The `scope=` parameter GitLab expects.
  final String apiName;

  /// Scopes valid in `/search` (instance-wide).
  static const globalScopes = [
    SearchScope.projects,
    SearchScope.issues,
    SearchScope.mergeRequests,
    SearchScope.users,
    SearchScope.snippetTitles,
    SearchScope.milestones,
  ];

  /// Scopes valid in `/projects/:id/search`.
  static const projectScopes = [
    SearchScope.blobs,
    SearchScope.issues,
    SearchScope.mergeRequests,
    SearchScope.commits,
    SearchScope.notes,
    SearchScope.wiki,
    SearchScope.milestones,
  ];

  /// Scopes valid in `/groups/:id/search`.
  static const groupScopes = [
    SearchScope.projects,
    SearchScope.issues,
    SearchScope.mergeRequests,
    SearchScope.blobs,
    SearchScope.milestones,
  ];
}

/// `/search` plus project- and group-scoped variants.
class SearchRepository {
  const SearchRepository(this._client);

  final GitLabApiClient _client;

  Object _decode(SearchScope scope, Object? json) {
    final map = json! as Map<String, dynamic>;
    return switch (scope) {
      SearchScope.projects => Project.fromJson(map),
      SearchScope.issues => Issue.fromJson(map),
      SearchScope.mergeRequests => MergeRequest.fromJson(map),
      SearchScope.commits => Commit.fromJson(map),
      SearchScope.blobs || SearchScope.wiki => BlobResult.fromJson(map),
      SearchScope.notes => Note.fromJson(map),
      SearchScope.milestones => Milestone.fromJson(map),
      SearchScope.users => GitLabUser.fromJson(map),
      SearchScope.snippetTitles ||
      SearchScope.snippetBlobs => Snippet.fromJson(map),
    };
  }

  /// Instance-wide search (`/search`).
  Future<Paginated<Object>> search(
    SearchScope scope,
    String term, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/search',
      query: {'scope': scope.apiName, 'search': term},
      page: page,
      perPage: perPage,
      decoder: (j) => _decode(scope, j),
    );
  }

  /// Search inside one project.
  Future<Paginated<Object>> searchInProject(
    Object projectId,
    SearchScope scope,
    String term, {
    int page = 1,
    int perPage = 20,
    String? ref,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(projectId)}/search',
      query: {'scope': scope.apiName, 'search': term, 'ref': ?ref},
      page: page,
      perPage: perPage,
      decoder: (j) => _decode(scope, j),
    );
  }

  /// Search inside one group.
  Future<Paginated<Object>> searchInGroup(
    Object groupId,
    SearchScope scope,
    String term, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/groups/${GitLabApiClient.encodeProject(groupId)}/search',
      query: {'scope': scope.apiName, 'search': term},
      page: page,
      perPage: perPage,
      decoder: (j) => _decode(scope, j),
    );
  }
}
