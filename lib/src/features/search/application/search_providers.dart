import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/search/data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);

/// A search request: scope + term + optional project/group container.
typedef SearchQuery = ({
  SearchScope scope,
  String term,
  Object? projectId,
  Object? groupId,
});

final searchProvider =
    AsyncNotifierProvider.family<
      SearchNotifier,
      PagedListState<Object>,
      SearchQuery
    >(SearchNotifier.new);

class SearchNotifier extends PagedListNotifier<Object> {
  SearchNotifier(this.query);

  final SearchQuery query;

  @override
  Future<Paginated<Object>> fetchPage(int page) {
    final repo = ref.watch(searchRepositoryProvider);
    if (query.projectId != null) {
      return repo.searchInProject(
        query.projectId!,
        query.scope,
        query.term,
        page: page,
      );
    }
    if (query.groupId != null) {
      return repo.searchInGroup(
        query.groupId!,
        query.scope,
        query.term,
        page: page,
      );
    }
    return repo.search(query.scope, query.term, page: page);
  }
}
