import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/environments/data/environments_repository.dart';
import 'package:glam/src/features/environments/domain/environment.dart';
import 'package:glam/src/features/environments/domain/feature_flag.dart';
import 'package:glam/src/features/environments/domain/feature_flag_user_list.dart';

final environmentsRepositoryProvider = Provider<EnvironmentsRepository>(
  (ref) => EnvironmentsRepository(ref.watch(apiClientProvider)),
);

/// Feature flags for a project.
final featureFlagsProvider = FutureProvider.family<List<FeatureFlag>, Object>(
  (ref, id) => ref.watch(environmentsRepositoryProvider).featureFlags(id),
);

/// Named user sets flags can target.
final featureFlagUserListsProvider =
    FutureProvider.family<List<FeatureFlagUserList>, Object>(
      (ref, id) =>
          ref.watch(environmentsRepositoryProvider).featureFlagUserLists(id),
    );

typedef EnvironmentFilter = ({Object project, String? states, String? search});

final environmentsProvider =
    AsyncNotifierProvider.family<
      EnvironmentsNotifier,
      PagedListState<GlEnvironment>,
      EnvironmentFilter
    >(EnvironmentsNotifier.new);

class EnvironmentsNotifier extends PagedListNotifier<GlEnvironment> {
  EnvironmentsNotifier(this.filter);

  final EnvironmentFilter filter;

  @override
  Future<Paginated<GlEnvironment>> fetchPage(int page) {
    return ref
        .watch(environmentsRepositoryProvider)
        .environments(
          filter.project,
          page: page,
          states: filter.states,
          search: filter.search,
        );
  }
}

/// (project, envId) for a single environment.
typedef EnvironmentRef = ({Object project, int envId});

final environmentProvider =
    FutureProvider.family<GlEnvironment, EnvironmentRef>(
      (ref, loc) => ref
          .watch(environmentsRepositoryProvider)
          .environment(loc.project, loc.envId),
    );

typedef DeploymentFilter = ({EnvironmentRef env, String? status});

final deploymentsProvider =
    AsyncNotifierProvider.family<
      DeploymentsNotifier,
      PagedListState<Deployment>,
      DeploymentFilter
    >(DeploymentsNotifier.new);

class DeploymentsNotifier extends PagedListNotifier<Deployment> {
  DeploymentsNotifier(this.filter);

  final DeploymentFilter filter;

  @override
  Future<Paginated<Deployment>> fetchPage(int page) {
    return ref
        .watch(environmentsRepositoryProvider)
        .deployments(
          filter.env.project,
          environmentId: filter.env.envId,
          status: filter.status,
          page: page,
        );
  }
}
