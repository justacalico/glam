import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/snippets/data/snippets_repository.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';

final snippetsRepositoryProvider = Provider<SnippetsRepository>(
  (ref) => SnippetsRepository(ref.watch(apiClientProvider)),
);

/// Which snippet list to show: the user's own or all public ones.
enum SnippetScope { mine, public }

typedef SnippetFilter = ({SnippetScope scope, String? search});

final snippetsProvider =
    AsyncNotifierProvider.family<
      SnippetsNotifier,
      PagedListState<Snippet>,
      SnippetFilter
    >(SnippetsNotifier.new);

class SnippetsNotifier extends PagedListNotifier<Snippet> {
  SnippetsNotifier(this.filter);

  final SnippetFilter filter;

  @override
  Future<Paginated<Snippet>> fetchPage(int page) {
    final repo = ref.watch(snippetsRepositoryProvider);
    return filter.scope == SnippetScope.mine
        ? repo.snippets(search: filter.search, page: page)
        : repo.publicSnippets(search: filter.search, page: page);
  }
}

final projectSnippetsProvider =
    AsyncNotifierProvider.family<
      ProjectSnippetsNotifier,
      PagedListState<Snippet>,
      Object
    >(ProjectSnippetsNotifier.new);

class ProjectSnippetsNotifier extends PagedListNotifier<Snippet> {
  ProjectSnippetsNotifier(this.projectId);

  final Object projectId;

  @override
  Future<Paginated<Snippet>> fetchPage(int page) {
    return ref
        .watch(snippetsRepositoryProvider)
        .projectSnippets(projectId, page: page);
  }
}

/// Locator for one snippet — `projectId` null means a personal snippet.
typedef SnippetRef = ({int id, Object? projectId});

final snippetProvider = FutureProvider.family<Snippet, SnippetRef>(
  (ref, loc) => ref
      .watch(snippetsRepositoryProvider)
      .snippet(loc.id, projectId: loc.projectId),
);

final snippetRawProvider = FutureProvider.family<String, SnippetRef>(
  (ref, loc) => ref
      .watch(snippetsRepositoryProvider)
      .raw(loc.id, projectId: loc.projectId),
);
