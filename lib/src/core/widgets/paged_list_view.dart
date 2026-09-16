import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/paged_list.dart';

/// Scrollable list wired to a [PagedListState]: triggers `onLoadMore`
/// near the bottom and renders a footer spinner / retry affordance.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    this.onRefresh,
    this.separator,
    this.padding = Insets.pagePadding,
    this.empty,
    super.key,
  });

  final PagedListState<T> state;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function()? onRefresh;
  final Widget? separator;
  final EdgeInsets padding;

  /// Rendered when the loaded list is empty.
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty && empty != null) {
      final child = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: empty,
          ),
        ],
      );
      if (onRefresh != null) {
        return RefreshIndicator(onRefresh: onRefresh!, child: child);
      }
      return child;
    }

    final footerCount = state.hasMore || state.loadMoreFailed ? 1 : 0;
    final itemCount = state.items.length + footerCount;

    final list = separator != null
        ? ListView.separated(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, _) => separator!,
            itemBuilder: _buildItem,
          )
        : ListView.builder(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: _buildItem,
          );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 240) {
          onLoadMore();
        }
        return false;
      },
      child: onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: list)
          : list,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index >= state.items.length) {
      return _LoadMoreFooter(failed: state.loadMoreFailed, onRetry: onLoadMore);
    }
    return itemBuilder(context, index);
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Load failed — tap to retry'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.accent,
          ),
        ),
      ),
    );
  }
}
