import 'dart:typed_data';

import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

/// Wraps `/projects/:id/repository/*`, `/files`, `/releases`.
class RepositoryRepository {
  const RepositoryRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  /// Directory listing for [path] at [ref].
  Future<Paginated<TreeEntry>> tree(
    Object projectId, {
    String? path,
    String? ref,
    int page = 1,
    int perPage = 100,
  }) {
    return _client.getPage(
      '${_p(projectId)}/repository/tree',
      query: {'path': ?path, 'ref': ?ref, 'order_by': 'name', 'sort': 'asc'},
      page: page,
      perPage: perPage,
      decoder: (j) => TreeEntry.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Fetches and decodes a file at [path] on [ref].
  Future<RepoFile> file(Object projectId, String path, {String? ref}) {
    return _client.get(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}',
      query: {'ref': ?ref},
      decoder: (j) => RepoFile.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Raw file contents without the JSON wrapper.
  Future<String> rawFile(Object projectId, String path, {String? ref}) {
    return _client.getRaw(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}/raw',
      ref: ref,
    );
  }

  /// `PUT` file update (creates a commit).
  Future<RepoFile> updateFile(
    Object projectId,
    String path, {
    required String branch,
    required String content,
    required String commitMessage,
  }) {
    return _client.put(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}',
      body: {
        'branch': branch,
        'content': content,
        'commit_message': commitMessage,
      },
      decoder: (j) => RepoFile(
        path: (j! as Map<String, dynamic>)['file_path'] as String? ?? path,
        name: path.split('/').last,
        content: content,
        encoding: 'text',
      ),
    );
  }

  /// `POST` file create.
  Future<void> createFile(
    Object projectId,
    String path, {
    required String branch,
    required String content,
    required String commitMessage,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}',
      body: {
        'branch': branch,
        'content': content,
        'commit_message': commitMessage,
      },
      decoder: (j) => j,
    );
  }

  /// `DELETE` file (creates a commit removing it).
  Future<void> deleteFile(
    Object projectId,
    String path, {
    required String branch,
    required String commitMessage,
  }) {
    return _client.delete(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}',
      body: {'branch': branch, 'commit_message': commitMessage},
    );
  }

  /// Line-by-line blame for a file. `ref` is required by the API, so
  /// fall back to HEAD (the default branch) when none is given.
  Future<List<BlameHunk>> blame(Object projectId, String path, {String? ref}) {
    return _client.getList(
      '${_p(projectId)}/repository/files/${Uri.encodeComponent(path)}/blame',
      query: {'ref': ref ?? 'HEAD'},
      decoder: (j) => BlameHunk.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Commits, optionally filtered to a ref/path.
  Future<Paginated<Commit>> commits(
    Object projectId, {
    String? ref,
    String? path,
    int page = 1,
    int perPage = 20,
    bool withStats = false,
  }) {
    return _client.getPage(
      '${_p(projectId)}/repository/commits',
      query: {
        'ref_name': ?ref,
        'path': ?path,
        if (withStats) 'with_stats': true,
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Commit.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Commit authors ranked by commit count (`/repository/contributors`).
  Future<List<Contributor>> contributors(Object projectId, {String? ref}) {
    return _client.getAll(
      '${_p(projectId)}/repository/contributors',
      query: {'ref': ?ref},
      decoder: (j) => Contributor.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Branches and tags containing this commit (`/commits/:sha/refs`).
  Future<List<CommitRef>> commitRefs(Object projectId, String sha) {
    return _client.getAll(
      '${_p(projectId)}/repository/commits/$sha/refs',
      query: {'type': 'all'},
      decoder: (j) => CommitRef.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Merge requests that contain this commit
  /// (`/repository/commits/:sha/merge_requests`).
  Future<List<MergeRequest>> commitMergeRequests(Object projectId, String sha) {
    return _client.getAll(
      '${_p(projectId)}/repository/commits/$sha/merge_requests',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Issue/MR description templates under `.gitlab/` (`/templates/:type`,
  /// where type is `issues` or `merge_requests`).
  Future<List<DescriptionTemplate>> templates(Object projectId, String type) {
    return _client.getAll(
      '${_p(projectId)}/templates/$type',
      decoder: (j) => DescriptionTemplate.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Commit> commit(Object projectId, String sha) {
    return _client.get(
      '${_p(projectId)}/repository/commits/$sha',
      decoder: (j) => Commit.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Statuses reported on the commit: its own pipeline plus external
  /// checks posted through the commit status API.
  Future<List<CommitStatus>> commitStatuses(Object projectId, String sha) {
    return _client.getAll(
      '${_p(projectId)}/repository/commits/$sha/statuses',
      decoder: (j) => CommitStatus.fromJson(j as Map<String, dynamic>),
    );
  }

  /// The file-level diffs of a commit.
  Future<List<ChangeEntry>> commitDiff(Object projectId, String sha) {
    return _client.getList(
      '${_p(projectId)}/repository/commits/$sha/diff',
      decoder: (j) => ChangeEntry.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// `POST /repository/commits/:sha/cherry_pick` onto [branch].
  Future<Commit> cherryPick(
    Object projectId,
    String sha, {
    required String branch,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/commits/$sha/cherry_pick',
      body: {'branch': branch},
      decoder: (j) => Commit.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// `POST /repository/commits/:sha/revert` onto [branch].
  Future<Commit> revert(
    Object projectId,
    String sha, {
    required String branch,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/commits/$sha/revert',
      body: {'branch': branch},
      decoder: (j) => Commit.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Compare two refs: commits `to` adds over `from` plus the diff.
  Future<CompareResult> compare(Object projectId, String from, String to) {
    return _client.get(
      '${_p(projectId)}/repository/compare',
      query: {'from': from, 'to': to},
      decoder: (j) => CompareResult.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Comments on a commit, oldest first. The endpoint paginates, so
  /// fetch every page (bounded by `getAll`).
  Future<List<CommitComment>> commitComments(Object projectId, String sha) {
    return _client.getAll(
      '${_p(projectId)}/repository/commits/$sha/comments',
      decoder: (j) => CommitComment.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Post a comment on a commit. Pass `anchor` to pin it to a diff line;
  /// GitLab requires the new-side path plus `line`/`lineType` together.
  Future<CommitComment> addCommitComment(
    Object projectId,
    String sha, {
    required String note,
    ({String path, int line, String lineType})? anchor,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/commits/$sha/comments',
      body: {
        'note': note,
        'path': ?anchor?.path,
        'line': ?anchor?.line,
        'line_type': ?anchor?.lineType,
      },
      decoder: (j) => CommitComment.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Paginated<Branch>> branches(
    Object projectId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/repository/branches',
      query: {'search': ?search},
      page: page,
      perPage: perPage,
      decoder: (j) => Branch.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Branch> branch(Object projectId, String name) {
    return _client.get(
      '${_p(projectId)}/repository/branches/${Uri.encodeComponent(name)}',
      decoder: (j) => Branch.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Creates a branch off [ref].
  Future<Branch> createBranch(
    Object projectId, {
    required String branch,
    required String ref,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/branches',
      body: {'branch': branch, 'ref': ref},
      decoder: (j) => Branch.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteBranch(Object projectId, String name) {
    return _client.delete(
      '${_p(projectId)}/repository/branches/${Uri.encodeComponent(name)}',
    );
  }

  Future<Paginated<Tag>> tags(
    Object projectId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/repository/tags',
      query: {'search': ?search, 'order_by': 'version', 'sort': 'desc'},
      page: page,
      perPage: perPage,
      decoder: (j) => Tag.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Tag> createTag(
    Object projectId, {
    required String name,
    required String ref,
    String? message,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/tags',
      body: {'tag_name': name, 'ref': ref, 'message': ?message},
      decoder: (j) => Tag.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteTag(Object projectId, String name) {
    return _client.delete(
      '${_p(projectId)}/repository/tags/${Uri.encodeComponent(name)}',
    );
  }

  Future<Paginated<Release>> releases(
    Object projectId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/releases',
      page: page,
      perPage: perPage,
      decoder: (j) => Release.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Release> release(Object projectId, String tag) {
    return _client.get(
      '${_p(projectId)}/releases/${Uri.encodeComponent(tag)}',
      decoder: (j) => Release.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Release> createRelease(
    Object projectId, {
    required String tag,
    required String name,
    String? description,
    String? ref,
  }) {
    return _client.post(
      '${_p(projectId)}/releases',
      body: {
        'tag_name': tag,
        'name': name,
        'description': ?description,
        'ref': ?ref,
      },
      decoder: (j) => Release.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Edits a release's name, notes, or release date.
  Future<Release> updateRelease(
    Object projectId,
    String tag, {
    String? name,
    String? description,
    DateTime? releasedAt,
  }) {
    return _client.put(
      '${_p(projectId)}/releases/${Uri.encodeComponent(tag)}',
      body: {
        'name': ?name,
        'description': ?description,
        'released_at': ?releasedAt?.toIso8601String(),
      },
      decoder: (j) => Release.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteRelease(Object projectId, String tag) {
    return _client.delete(
      '${_p(projectId)}/releases/${Uri.encodeComponent(tag)}',
    );
  }

  /// The rendered README for the project overview.
  Future<RepoFile?> readme(Object projectId, {String? ref}) async {
    const candidates = [
      'README.md',
      'readme.md',
      'README.markdown',
      'README.txt',
      'README',
    ];
    for (final name in candidates) {
      try {
        return await file(projectId, name, ref: ref);
      } on Object {
        continue;
      }
    }
    return null;
  }

  /// Project languages breakdown (`/projects/:id/languages`).
  Future<Map<String, double>> languages(Object projectId) async {
    return _client.get(
      '${_p(projectId)}/languages',
      decoder: (j) => (j! as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  /// Source tarball for a ref (`/repository/archive.tar.gz?sha=:ref`).
  Future<Uint8List> archive(Object projectId, String ref) {
    return _client.getBytes(
      '${_p(projectId)}/repository/archive.tar.gz',
      query: {'sha': ref},
      maxBytes: 100 * 1024 * 1024,
    );
  }

  /// Changelog entries for a version (`/repository/changelog`).
  Future<String> changelog(
    Object projectId, {
    required String version,
    String? from,
    String? to,
  }) {
    return _client.get(
      '${_p(projectId)}/repository/changelog',
      query: {'version': version, 'from': ?from, 'to': ?to},
      decoder: (j) => (j! as Map<String, dynamic>)['notes'] as String? ?? '',
    );
  }

  /// File template keys for a type (`/templates/:type`): `gitignores`,
  /// `dockerfiles`, `gitlab_ci_ymls`, `licenses`. Licenses key by `key`,
  /// the rest by `name`.
  Future<List<String>> fileTemplateNames(Object projectId, String type) async {
    final keys = await _client.getAll(
      '${_p(projectId)}/templates/$type',
      decoder: (j) {
        final m = j! as Map<String, dynamic>;
        return (m['key'] ?? m['name']) as String? ?? '';
      },
    );
    return keys.where((k) => k.isNotEmpty).toList();
  }

  /// Content of one template (`/templates/:type/:key`).
  Future<String> fileTemplate(Object projectId, String type, String key) {
    return _client.get(
      '${_p(projectId)}/templates/$type/${Uri.encodeComponent(key)}',
      decoder: (j) => (j! as Map<String, dynamic>)['content'] as String? ?? '',
    );
  }

  /// Generates the changelog for [version] and commits it to [branch]
  /// (default: the project's default branch).
  Future<void> generateChangelog(
    Object projectId, {
    required String version,
    String? from,
    String? to,
    String? branch,
    String? message,
    String? trailer,
  }) {
    return _client.post(
      '${_p(projectId)}/repository/changelog',
      body: {
        'version': version,
        'from': ?from,
        'to': ?to,
        'branch': ?branch,
        'message': ?message,
        'trailer': ?trailer,
      },
      decoder: (_) {},
    );
  }
}
