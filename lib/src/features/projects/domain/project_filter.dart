import 'package:equatable/equatable.dart';

/// Scope for the projects list — mirrors GitLab's `membership`/`starred`
/// tabs plus public explore.
enum ProjectScope {
  yours,
  starred,
  explored,
  all;

  String get label => switch (this) {
    ProjectScope.yours => 'Yours',
    ProjectScope.starred => 'Starred',
    ProjectScope.explored => 'Explore',
    ProjectScope.all => 'All',
  };
}

/// Sort options for `/projects`.
enum ProjectSort {
  lastActivity('last_activity_at', 'Last activity'),
  name('name_asc', 'Name'),
  stars('stars_desc', 'Most stars'),
  created('created_desc', 'Recently created'),
  oldest('created_asc', 'Oldest');

  const ProjectSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Filter + sort state for the projects list.
class ProjectFilter extends Equatable {
  const ProjectFilter({
    this.scope = ProjectScope.yours,
    this.sort = ProjectSort.lastActivity,
    this.search = '',
  });

  final ProjectScope scope;
  final ProjectSort sort;
  final String search;

  /// GitLab API query parameters.
  Map<String, dynamic> toQuery() {
    return {
      'order_by': switch (sort) {
        ProjectSort.name => 'name',
        ProjectSort.created || ProjectSort.oldest => 'created_at',
        ProjectSort.stars => 'star_count',
        ProjectSort.lastActivity => 'last_activity_at',
      },
      'sort': switch (sort) {
        ProjectSort.name || ProjectSort.oldest => 'asc',
        _ => 'desc',
      },
      'simple': true,
      'archived': false,
      if (search.isNotEmpty) 'search': search,
      ...switch (scope) {
        ProjectScope.yours => {'membership': true},
        ProjectScope.starred => {'starred': true},
        ProjectScope.explored => {'visibility': 'public'},
        ProjectScope.all => <String, dynamic>{},
      },
    };
  }

  ProjectFilter copyWith({
    ProjectScope? scope,
    ProjectSort? sort,
    String? search,
  }) {
    return ProjectFilter(
      scope: scope ?? this.scope,
      sort: sort ?? this.sort,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [scope, sort, search];
}
