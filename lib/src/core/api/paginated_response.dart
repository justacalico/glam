import 'package:equatable/equatable.dart';

/// One page of a GitLab list endpoint, along with the pagination headers
/// GitLab sends back (`x-page`, `x-next-page`, `x-total`, ...).
class Paginated<T> extends Equatable {
  const Paginated({
    required this.items,
    required this.page,
    required this.perPage,
    this.nextPage,
    this.total,
    this.totalPages,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int? nextPage;
  final int? total;
  final int? totalPages;

  bool get hasMore => nextPage != null;

  @override
  List<Object?> get props => [items, page, perPage, nextPage, total];
}
