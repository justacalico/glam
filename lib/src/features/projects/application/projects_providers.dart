import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/projects/data/projects_repository.dart';
import 'package:glam/src/features/projects/domain/ci_variable.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.watch(apiClientProvider)),
);

/// Filter state for the projects list. Updating it re-triggers the
/// paged list below.
final projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(
      ProjectFilterController.new,
    );

class ProjectFilterController extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => const ProjectFilter();

  void update(ProjectFilter filter) => state = filter;

  void setScope(ProjectScope scope) => state = state.copyWith(scope: scope);

  void setSort(ProjectSort sort) => state = state.copyWith(sort: sort);

  void setSearch(String search) => state = state.copyWith(search: search);
}

/// Paginated projects for the current filter.
final projectsListProvider =
    AsyncNotifierProvider<ProjectListNotifier, PagedListState<Project>>(
      ProjectListNotifier.new,
    );

class ProjectListNotifier extends PagedListNotifier<Project> {
  @override
  Future<Paginated<Project>> fetchPage(int page) {
    return ref
        .watch(projectsRepositoryProvider)
        .list(filter: ref.watch(projectFilterProvider), page: page);
  }
}

/// A single project by id or `namespace/path`.
final projectProvider = FutureProvider.family<Project, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).get(id),
);

/// CI/CD variables for a project.
final projectVariablesProvider =
    FutureProvider.family<List<CiVariable>, Object>(
      (ref, id) => ref.watch(projectsRepositoryProvider).variables(id),
    );

/// Star/unstar actions that keep the list in sync optimistically.
final projectActionsProvider = Provider<ProjectActions>(ProjectActions.new);

class ProjectActions {
  const ProjectActions(this._ref);

  final Ref _ref;

  Future<void> toggleStar(Project project, {required bool starred}) async {
    final repo = _ref.read(projectsRepositoryProvider);
    if (starred) {
      await repo.unstar(project.id);
    } else {
      await repo.star(project.id);
    }
    _ref
      ..invalidate(projectProvider(project.id.toString()))
      ..invalidate(projectsListProvider);
  }
}
