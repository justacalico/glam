import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
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

/// (project, ref) for commit history.
typedef CommitsLocation = ({Object project, String? ref});

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
        .commits(loc.project, ref: loc.ref, page: page);
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

final branchesProvider =
    AsyncNotifierProvider.family<
      BranchesNotifier,
      PagedListState<Branch>,
      Object
    >(BranchesNotifier.new);

class BranchesNotifier extends PagedListNotifier<Branch> {
  BranchesNotifier(this.project);

  final Object project;

  @override
  Future<Paginated<Branch>> fetchPage(int page) {
    return ref
        .watch(repositoryRepositoryProvider)
        .branches(project, page: page);
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
