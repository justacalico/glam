import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';

class _Numbers extends PagedListNotifier<int> {
  _Numbers(this.pages, {this.failPages = const {}});

  final Map<int, List<int>> pages;
  final Set<int> failPages;
  var fetches = <int>[];

  @override
  Future<Paginated<int>> fetchPage(int page) async {
    fetches.add(page);
    if (failPages.contains(page)) {
      throw Exception('page $page failed');
    }
    final items = pages[page] ?? [];
    return Paginated(
      items: items,
      page: page,
      perPage: 2,
      nextPage: pages.containsKey(page + 1) ? page + 1 : null,
      total: pages.values.fold<int>(0, (a, b) => a + b.length),
    );
  }
}

void main() {
  late ProviderContainer container;
  late _Numbers notifier;
  late AsyncNotifierProvider<_Numbers, PagedListState<int>> provider;

  void pump(Map<int, List<int>> pages, {Set<int> failPages = const {}}) {
    notifier = _Numbers(pages, failPages: failPages);
    provider = AsyncNotifierProvider<_Numbers, PagedListState<int>>(
      () => notifier,
    );
    container = ProviderContainer();
  }

  tearDown(() => container.dispose());

  test('build loads the first page', () async {
    pump({
      1: [1, 2],
    });
    final state = await container.read(provider.future);
    expect(state.items, [1, 2]);
    expect(state.hasMore, isFalse);
    expect(state.total, 2);
  });

  test('loadMore appends the next page', () async {
    pump({
      1: [1, 2],
      2: [3, 4],
      3: [5],
    });
    await container.read(provider.future);

    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, [1, 2, 3, 4]);
    expect(container.read(provider).value!.hasMore, isTrue);

    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, [1, 2, 3, 4, 5]);
    expect(container.read(provider).value!.hasMore, isFalse);
  });

  test('loadMore is a no-op when nothing remains', () async {
    pump({
      1: [1],
    });
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, [1]);
    expect(notifier.fetches, [1]);
  });

  test('loadMore failure keeps items and flags the footer', () async {
    pump(
      {
        1: [1],
        2: [2],
      },
      failPages: {2},
    );
    await container.read(provider.future);

    await container.read(provider.notifier).loadMore();
    final state = container.read(provider).value!;
    expect(state.items, [1]);
    expect(state.loadMoreFailed, isTrue);
  });

  test('refresh reloads page one', () async {
    pump({
      1: [1],
      2: [2],
    });
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();

    await container.read(provider.notifier).refresh();
    expect(container.read(provider).value!.items, [1]);
    expect(notifier.fetches, [1, 2, 1]);
  });
}
