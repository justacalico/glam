import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paginated_response.dart';

/// State for an infinitely-scrollable list: the items loaded so far,
/// whether more pages exist, and whether a next-page fetch is running.
class PagedListState<T> {
  const PagedListState({
    required this.items,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.total,
  });

  final List<T> items;
  final bool hasMore;
  final bool loadingMore;

  /// True when the last `loadMore` call threw. The items stay intact.
  final bool loadMoreFailed;
  final int? total;

  PagedListState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    int? total,
  }) {
    return PagedListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      total: total ?? this.total,
    );
  }
}

/// Base class for paginated list providers.
///
/// Subclasses implement [fetchPage]; the notifier handles page tracking,
/// `loadMore`, pull-to-refresh, and keeps already-loaded items on screen
/// while refreshing.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedListState<T>> {
  int _nextPage = 1;

  /// Fetch one page. [page] is 1-based.
  Future<Paginated<T>> fetchPage(int page);

  @override
  Future<PagedListState<T>> build() async {
    _nextPage = 1;
    final result = await fetchPage(1);
    _nextPage = result.nextPage ?? 0;
    return PagedListState(
      items: result.items,
      hasMore: result.hasMore,
      total: result.total,
    );
  }

  /// Loads the next page and appends it. Safe to call when already
  /// loading or when no pages remain — both are no-ops.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.loadingMore ||
        _nextPage == 0) {
      return;
    }
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final result = await fetchPage(_nextPage);
      _nextPage = result.nextPage ?? 0;
      state = AsyncData(
        PagedListState(
          items: [...current.items, ...result.items],
          hasMore: result.hasMore,
          total: result.total,
        ),
      );
    } on Object {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }

  /// Pull-to-refresh: reloads from page 1 while keeping the current
  /// items visible.
  Future<void> refresh() async {
    final result = await fetchPage(1);
    _nextPage = result.nextPage ?? 0;
    state = AsyncData(
      PagedListState(
        items: result.items,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }

  /// Mutates the loaded items without refetching. No-op before the
  /// first page lands.
  void updateItems(List<T> Function(List<T> items) update) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(items: update(current.items)));
  }
}
