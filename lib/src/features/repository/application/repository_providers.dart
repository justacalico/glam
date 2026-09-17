import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/repository/data/repository_repository.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

final repositoryRepositoryProvider = Provider<RepositoryRepository>(
  (ref) => RepositoryRepository(ref.watch(apiClientProvider)),
);

/// Identity of a tree position: which project, which ref, which folder.
typedef TreeLocation = ({Object project, String? ref, String? path});

final treeProvider =
    AsyncNotifierProvider.family<
      TreeNotifier,
      PagedListState<TreeEntry>,
      TreeLocation
    >(TreeNotifier.new);

class TreeNotifier extends PagedListNotifier<TreeEntry> {
  TreeNotifier(this.loc);

  final TreeLocation loc;

  @override
  Future<Paginated<TreeEntry>> fetchPage(int page) {
    return ref
        .watch(repositoryRepositoryProvider)
        .tree(loc.project, path: loc.path, ref: loc.ref, page: page);
  }
}

/// Directories before files, alphabetical — matches GitLab's tree view.
List<TreeEntry> sortTreeEntries(List<TreeEntry> entries) {
  final sorted = [...entries]
    ..sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return sorted;
}

/// (project, path, ref) for file requests.
typedef FileLocation = ({Object project, String path, String? ref});

final blameProvider = FutureProvider.family<List<BlameHunk>, FileLocation>(
  (ref, loc) => ref
      .watch(repositoryRepositoryProvider)
      .blame(loc.project, loc.path, ref: loc.ref),
);

final repoFileProvider = FutureProvider.family<RepoFile, FileLocation>(
  (ref, loc) => ref
      .watch(repositoryRepositoryProvider)
      .file(loc.project, loc.path, ref: loc.ref),
);

/// (project, from, to) for a ref comparison.
typedef CompareLocation = ({Object project, String from, String to});

final compareProvider = FutureProvider.family<CompareResult, CompareLocation>(
  (ref, loc) => ref
      .watch(repositoryRepositoryProvider)
      .compare(loc.project, loc.from, loc.to),
);

/// Common ancestor of the compared refs; null when unrelated.
final mergeBaseProvider = FutureProvider.family<Commit?, CompareLocation>((
  ref,
  loc,
) async {
  try {
    return await ref.watch(repositoryRepositoryProvider).mergeBase(
      loc.project,
      [loc.from, loc.to],
    );
  } on ApiException catch (e) {
    if (e.statusCode == 404 || e.statusCode == 400) {
      return null;
    }
    rethrow;
  }
});

final commitCommentsProvider =
    FutureProvider.family<List<CommitComment>, ({Object project, String sha})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .commitComments(loc.project, loc.sha),
    );

/// (project, ref, path) for commit history; `path` narrows to file
/// history.
typedef CommitsLocation = ({Object project, String? ref, String? path});

final commitsProvider =
    AsyncNotifierProvider.family<
      CommitsNotifier,
      PagedListState<Commit>,
      CommitsLocation
    >(CommitsNotifier.new);

class CommitsNotifier extends PagedListNotifier<Commit> {
  CommitsNotifier(this.loc);

  final CommitsLocation loc;

  @override
  Future<Paginated<Commit>> fetchPage(int page) {
    return ref
        .watch(repositoryRepositoryProvider)
        .commits(loc.project, ref: loc.ref, path: loc.path, page: page);
  }
}

final commitProvider =
    FutureProvider.family<Commit, ({Object project, String sha})>(
      (ref, loc) =>
          ref.watch(repositoryRepositoryProvider).commit(loc.project, loc.sha),
    );

final commitDiffProvider =
    FutureProvider.family<List<ChangeEntry>, ({Object project, String sha})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .commitDiff(loc.project, loc.sha),
    );

final commitStatusesProvider =
    FutureProvider.family<List<CommitStatus>, ({Object project, String sha})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .commitStatuses(loc.project, loc.sha),
    );

/// Description templates for issues or merge requests; empty when the
/// repo has none (or the endpoint 404s).
final descriptionTemplatesProvider =
    FutureProvider.family<
      List<DescriptionTemplate>,
      ({Object project, String type})
    >((ref, loc) async {
      try {
        return await ref
            .watch(repositoryRepositoryProvider)
            .templates(loc.project, loc.type);
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          return const [];
        }
        rethrow;
      }
    });

/// File template names for a type (`gitignores`, `dockerfiles`,
/// `gitlab_ci_ymls`, `licenses`); empty where the endpoint is absent.
final fileTemplateNamesProvider =
    FutureProvider.family<List<String>, ({Object project, String type})>((
      ref,
      loc,
    ) async {
      try {
        return await ref
            .watch(repositoryRepositoryProvider)
            .fileTemplateNames(loc.project, loc.type);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          return const [];
        }
        rethrow;
      }
    });

/// Branches and tags containing a commit.
final commitRefsProvider =
    FutureProvider.family<List<CommitRef>, ({Object project, String sha})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .commitRefs(loc.project, loc.sha),
    );

/// Merge requests containing a commit.
final commitMergeRequestsProvider =
    FutureProvider.family<List<MergeRequest>, ({Object project, String sha})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .commitMergeRequests(loc.project, loc.sha),
    );

/// Commit authors ranked by commit count for a project's default ref.
final projectContributorsProvider =
    FutureProvider.family<List<Contributor>, Object>(
      (ref, id) => ref.watch(repositoryRepositoryProvider).contributors(id),
    );

typedef BranchFilter = ({Object project, String? search});

final branchesProvider =
    AsyncNotifierProvider.family<
      BranchesNotifier,
      PagedListState<Branch>,
      BranchFilter
    >(BranchesNotifier.new);

class BranchesNotifier extends PagedListNotifier<Branch> {
  BranchesNotifier(this.filter);

  final BranchFilter filter;

  @override
  Future<Paginated<Branch>> fetchPage(int page) {
    return ref
        .watch(repositoryRepositoryProvider)
        .branches(filter.project, page: page, search: filter.search);
  }
}

final tagsProvider =
    AsyncNotifierProvider.family<TagsNotifier, PagedListState<Tag>, Object>(
      TagsNotifier.new,
    );

class TagsNotifier extends PagedListNotifier<Tag> {
  TagsNotifier(this.project);

  final Object project;

  @override
  Future<Paginated<Tag>> fetchPage(int page) {
    return ref.watch(repositoryRepositoryProvider).tags(project, page: page);
  }
}

final releasesProvider =
    AsyncNotifierProvider.family<
      ReleasesNotifier,
      PagedListState<Release>,
      Object
    >(ReleasesNotifier.new);

class ReleasesNotifier extends PagedListNotifier<Release> {
  ReleasesNotifier(this.project);

  final Object project;

  @override
  Future<Paginated<Release>> fetchPage(int page) {
    return ref
        .watch(repositoryRepositoryProvider)
        .releases(project, page: page);
  }
}

final languagesProvider = FutureProvider.family<Map<String, double>, Object>(
  (ref, project) => ref.watch(repositoryRepositoryProvider).languages(project),
);

final readmeProvider =
    FutureProvider.family<RepoFile?, ({Object project, String? ref})>(
      (ref, loc) => ref
          .watch(repositoryRepositoryProvider)
          .readme(loc.project, ref: loc.ref),
    );
