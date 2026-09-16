import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/wiki/data/wiki_repository.dart';
import 'package:glam/src/features/wiki/domain/wiki_page.dart';

final wikiRepositoryProvider = Provider<WikiRepository>(
  (ref) => WikiRepository(ref.watch(apiClientProvider)),
);

final wikiPagesProvider =
    AsyncNotifierProvider.family<
      WikiPagesNotifier,
      PagedListState<WikiPage>,
      Object
    >(WikiPagesNotifier.new);

class WikiPagesNotifier extends PagedListNotifier<WikiPage> {
  WikiPagesNotifier(this.projectId);

  final Object projectId;

  @override
  Future<Paginated<WikiPage>> fetchPage(int page) {
    return ref.watch(wikiRepositoryProvider).pages(projectId, page: page);
  }
}

typedef WikiPageRef = ({Object projectId, String slug});

final wikiPageProvider = FutureProvider.family<WikiPage, WikiPageRef>(
  (ref, loc) => ref.watch(wikiRepositoryProvider).page(loc.projectId, loc.slug),
);
