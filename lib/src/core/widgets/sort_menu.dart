import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';

/// One entry in a [SortMenu]: the API `order_by`/`sort` pair plus a
/// label ("Newest", "Due soonest", ...).
typedef SortOption = ({String orderBy, String sort, String label});

/// Sort icon popup for paged lists. A null current pair means the
/// API default ordering, which the first option should describe.
class SortMenu extends StatelessWidget {
  const SortMenu({
    required this.orderBy,
    required this.sort,
    required this.options,
    required this.onSelect,
    super.key,
  });

  final String? orderBy;
  final String? sort;
  final List<SortOption> options;
  final ValueChanged<SortOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = (
      orderBy: orderBy ?? options.first.orderBy,
      sort: sort ?? options.first.sort,
    );
    return PopupMenuButton<SortOption>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort, size: 20),
      onSelected: onSelect,
      itemBuilder: (context) => [
        for (final o in options)
          PopupMenuItem(
            value: o,
            child: Row(
              children: [
                if (o.orderBy == current.orderBy && o.sort == current.sort)
                  Icon(Icons.check, size: 16, color: colors.accent)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: Insets.sm),
                Text(o.label),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shared option sets for the lists GitLab sorts server-side.
abstract final class SortOptions {
  /// `created_at`/`updated_at`/`due_date` — issues.
  static const issues = [
    (orderBy: 'created_at', sort: 'desc', label: 'Newest'),
    (orderBy: 'created_at', sort: 'asc', label: 'Oldest'),
    (orderBy: 'updated_at', sort: 'desc', label: 'Recently updated'),
    (orderBy: 'updated_at', sort: 'asc', label: 'Least recently updated'),
    (orderBy: 'due_date', sort: 'asc', label: 'Due soonest'),
    (orderBy: 'due_date', sort: 'desc', label: 'Due latest'),
  ];

  /// `created_at`/`updated_at`/`title` — merge requests.
  static const mergeRequests = [
    (orderBy: 'created_at', sort: 'desc', label: 'Newest'),
    (orderBy: 'created_at', sort: 'asc', label: 'Oldest'),
    (orderBy: 'updated_at', sort: 'desc', label: 'Recently updated'),
    (orderBy: 'updated_at', sort: 'asc', label: 'Least recently updated'),
    (orderBy: 'title', sort: 'asc', label: 'Title A-Z'),
    (orderBy: 'title', sort: 'desc', label: 'Title Z-A'),
  ];
}
