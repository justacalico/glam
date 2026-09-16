import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// A branch (`/projects/:id/repository/branches`).
class Branch extends Equatable {
  const Branch({
    required this.name,
    required this.shortSha,
    this.commitTitle,
    this.merged = false,
    this.protected = false,
    this.isDefault = false,
    this.webUrl,
    this.authoredAt,
    this.authorName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'];
    String? sha;
    String? title;
    DateTime? date;
    String? author;
    if (commit is Map<String, dynamic>) {
      sha = commit['id'] as String?;
      title = commit['title'] as String?;
      author = commit['author_name'] as String?;
      date = _date(commit['committed_date'] ?? commit['created_at']);
    }
    return Branch(
      name: json['name'] as String? ?? '',
      shortSha: (sha ?? '').length > 8 ? sha!.substring(0, 8) : sha ?? '',
      commitTitle: title,
      merged: json['merged'] as bool? ?? false,
      protected: json['protected'] as bool? ?? false,
      isDefault: json['default'] as bool? ?? false,
      webUrl: json['web_url'] as String?,
      authoredAt: date,
      authorName: author,
    );
  }

  final String name;
  final String shortSha;
  final String? commitTitle;
  final bool merged;
  final bool protected;
  final bool isDefault;
  final String? webUrl;
  final DateTime? authoredAt;
  final String? authorName;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [name, shortSha];
}

/// A git commit (`/projects/:id/repository/commits`).
class Commit extends Equatable {
  const Commit({
    required this.id,
    required this.shortId,
    required this.title,
    this.message,
    this.authorName,
    this.authorEmail,
    this.authoredAt,
    this.committerName,
    this.committedAt,
    this.parentIds = const [],
    this.webUrl,
    this.authorAvatarUrl,
  });

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      id: json['id'] as String? ?? '',
      shortId: json['short_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String?,
      authorName: json['author_name'] as String?,
      authorEmail: json['author_email'] as String?,
      authoredAt: _date(json['authored_date']),
      committerName: json['committer_name'] as String?,
      committedAt: _date(json['committed_date']),
      parentIds: json['parent_ids'] is List
          ? (json['parent_ids'] as List).map((e) => e.toString()).toList()
          : const [],
      webUrl: json['web_url'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
    );
  }

  final String id;
  final String shortId;
  final String title;
  final String? message;
  final String? authorName;
  final String? authorEmail;
  final DateTime? authoredAt;
  final String? committerName;
  final DateTime? committedAt;
  final List<String> parentIds;
  final String? webUrl;
  final String? authorAvatarUrl;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [id, title];
}

/// A tag (`/projects/:id/repository/tags`).
class Tag extends Equatable {
  const Tag({
    required this.name,
    this.message,
    this.commitSha,
    this.commitTitle,
    this.committedAt,
    this.protected_ = false,
    this.releaseTitle,
    this.webUrl,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'];
    String? sha;
    String? title;
    DateTime? date;
    if (commit is Map<String, dynamic>) {
      sha = commit['id'] as String?;
      title = commit['title'] as String?;
      date = Commit._date(commit['committed_date']);
    }
    final release = json['release'];
    return Tag(
      name: json['name'] as String? ?? '',
      message: json['message'] as String?,
      commitSha: sha,
      commitTitle: title,
      committedAt: date,
      protected_: json['protected'] as bool? ?? false,
      releaseTitle: release is Map<String, dynamic>
          ? release['name'] as String?
          : null,
      webUrl: json['web_url'] as String?,
    );
  }

  final String name;
  final String? message;
  final String? commitSha;
  final String? commitTitle;
  final DateTime? committedAt;
  final bool protected_;
  final String? releaseTitle;
  final String? webUrl;

  bool get hasRelease => releaseTitle != null;

  @override
  List<Object?> get props => [name];
}

/// An entry in the repository tree (file or directory).
class TreeEntry extends Equatable {
  const TreeEntry({required this.name, required this.path, required this.type});

  factory TreeEntry.fromJson(Map<String, dynamic> json) {
    return TreeEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      type: json['type'] as String? ?? 'blob',
    );
  }

  final String name;
  final String path;

  /// `blob` (file), `tree` (directory), or `commit` (submodule).
  final String type;

  bool get isDirectory => type == 'tree';
  bool get isSubmodule => type == 'commit';

  @override
  List<Object?> get props => [path, type];
}

/// A file's decoded contents plus metadata from the Files API.
class RepoFile extends Equatable {
  const RepoFile({
    required this.path,
    required this.name,
    required this.content,
    this.size = 0,
    this.encoding = 'base64',
    this.sha,
    this.ref,
    this.lastCommitId,
  });

  factory RepoFile.fromJson(Map<String, dynamic> json) {
    return RepoFile(
      path: json['file_path'] as String? ?? '',
      name: json['file_name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      encoding: json['encoding'] as String? ?? 'base64',
      sha: json['blob_id'] as String?,
      ref: json['ref'] as String?,
      lastCommitId: json['last_commit_id'] as String?,
    );
  }

  final String path;
  final String name;

  /// Raw body — base64 encoded unless [encoding] says otherwise.
  final String content;
  final int size;
  final String encoding;
  final String? sha;
  final String? ref;
  final String? lastCommitId;

  /// Decoded text for editing/display.
  String get decodedContent {
    if (encoding == 'base64') {
      try {
        return utf8.decode(base64.decode(content.replaceAll('\n', '')));
      } on Object {
        return content;
      }
    }
    return content;
  }

  /// Guessed language key for syntax highlighting, from the extension.
  String get language => languageForPath(path);

  static String languageForPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _extToLang[ext] ?? 'plaintext';
  }

  static const _extToLang = {
    'dart': 'dart',
    'js': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'py': 'python',
    'rb': 'ruby',
    'go': 'go',
    'rs': 'rust',
    'java': 'java',
    'kt': 'kotlin',
    'kts': 'kotlin',
    'swift': 'swift',
    'c': 'c',
    'h': 'c',
    'cpp': 'cpp',
    'cc': 'cpp',
    'hpp': 'cpp',
    'cs': 'csharp',
    'php': 'php',
    'sh': 'bash',
    'bash': 'bash',
    'zsh': 'bash',
    'yaml': 'yaml',
    'yml': 'yaml',
    'json': 'json',
    'toml': 'ini',
    'xml': 'xml',
    'html': 'xml',
    'css': 'css',
    'scss': 'scss',
    'md': 'markdown',
    'sql': 'sql',
    'lua': 'lua',
    'r': 'r',
    'scala': 'scala',
    'ex': 'elixir',
    'exs': 'elixir',
    'erl': 'erlang',
    'hs': 'haskell',
    'clj': 'clojure',
    'dockerfile': 'dockerfile',
    'makefile': 'makefile',
    'gradle': 'groovy',
    'tf': 'hcl',
    'vue': 'xml',
    'txt': 'plaintext',
  };

  @override
  List<Object?> get props => [path, sha];
}

/// One changed file inside a commit/MR diff.
class ChangeEntry extends Equatable {
  const ChangeEntry({
    required this.oldPath,
    required this.newPath,
    this.newFile = false,
    this.deletedFile = false,
    this.renamedFile = false,
    this.diff = '',
    this.generatedFile = false,
    this.collapsed = false,
    this.tooLarge = false,
  });

  factory ChangeEntry.fromJson(Map<String, dynamic> json) {
    return ChangeEntry(
      oldPath: json['old_path'] as String? ?? '',
      newPath: json['new_path'] as String? ?? '',
      newFile: json['new_file'] as bool? ?? false,
      deletedFile: json['deleted_file'] as bool? ?? false,
      renamedFile: json['renamed_file'] as bool? ?? false,
      diff: json['diff'] as String? ?? '',
      generatedFile: json['generated_file'] as bool? ?? false,
      collapsed: json['collapsed'] as bool? ?? false,
      tooLarge: json['too_large'] as bool? ?? false,
    );
  }

  final String oldPath;
  final String newPath;
  final bool newFile;
  final bool deletedFile;
  final bool renamedFile;
  final String diff;
  final bool generatedFile;
  final bool collapsed;
  final bool tooLarge;

  String get displayPath => renamedFile ? '$oldPath → $newPath' : newPath;

  @override
  List<Object?> get props => [oldPath, newPath];
}

/// A release (`/projects/:id/releases`).
class Release extends Equatable {
  const Release({
    required this.tagName,
    this.name,
    this.description,
    this.releasedAt,
    this.createdAt,
    this.author,
    this.commitSha,
    this.upcoming = false,
    this.assets = const [],
    this.milestones = const [],
  });

  factory Release.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'];
    final author = json['author'];
    final assets = json['assets'];
    List<ReleaseLink> links = const [];
    if (assets is Map<String, dynamic> && assets['links'] is List) {
      links = (assets['links'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ReleaseLink.fromJson)
          .toList();
    }
    return Release(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      releasedAt: _date(json['released_at']),
      createdAt: _date(json['created_at']),
      author: author is Map<String, dynamic>
          ? GitLabUser.fromJson(author)
          : null,
      commitSha: commit is Map<String, dynamic>
          ? commit['id'] as String?
          : null,
      upcoming: json['upcoming_release'] as bool? ?? false,
      assets: links,
      milestones: json['milestones'] is List
          ? (json['milestones'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  final String tagName;
  final String? name;
  final String? description;
  final DateTime? releasedAt;
  final DateTime? createdAt;
  final GitLabUser? author;
  final String? commitSha;
  final bool upcoming;
  final List<ReleaseLink> assets;
  final List<String> milestones;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  List<Object?> get props => [tagName, name];
}

/// A downloadable release link.
class ReleaseLink extends Equatable {
  const ReleaseLink({required this.name, required this.url, this.linkType});

  factory ReleaseLink.fromJson(Map<String, dynamic> json) {
    return ReleaseLink(
      name: json['name'] as String? ?? 'link',
      url: json['direct_asset_url'] as String? ?? json['url'] as String? ?? '',
      linkType: json['link_type'] as String?,
    );
  }

  final String name;
  final String url;
  final String? linkType;

  @override
  List<Object?> get props => [name, url];
}

/// Result of `/repository/compare`: the commits `to` has that `from`
/// lacks, plus the full diff between the two refs.
class CompareResult extends Equatable {
  const CompareResult({
    required this.commits,
    required this.diffs,
    this.compareTimeout = false,
    this.compareSameRef = false,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) decode) =>
        json[key] is List
        ? (json[key] as List)
              .whereType<Map<String, dynamic>>()
              .map(decode)
              .toList()
        : const [];
    return CompareResult(
      commits: list('commits', Commit.fromJson),
      diffs: list('diffs', ChangeEntry.fromJson),
      compareTimeout: json['compare_timeout'] as bool? ?? false,
      compareSameRef: json['compare_same_ref'] as bool? ?? false,
    );
  }

  final List<Commit> commits;
  final List<ChangeEntry> diffs;
  final bool compareTimeout;
  final bool compareSameRef;

  @override
  List<Object?> get props => [commits, diffs, compareTimeout, compareSameRef];
}

/// A `git blame` hunk: a commit plus the lines it last touched.
class BlameHunk extends Equatable {
  const BlameHunk({required this.commit, required this.lines});

  factory BlameHunk.fromJson(Map<String, dynamic> json) {
    return BlameHunk(
      commit: Commit.fromJson(json['commit'] as Map<String, dynamic>? ?? {}),
      lines: json['lines'] is List
          ? (json['lines'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  final Commit commit;
  final List<String> lines;

  @override
  List<Object?> get props => [commit, lines];
}
