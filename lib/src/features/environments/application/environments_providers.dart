import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/environments/data/environments_repository.dart';
import 'package:glam/src/features/environments/domain/environment.dart';
import 'package:glam/src/features/environments/domain/feature_flag.dart';

final environmentsRepositoryProvider = Provider<EnvironmentsRepository>(
  (ref) => EnvironmentsRepository(ref.watch(apiClientProvider)),
);

/// Feature flags for a project.
final featureFlagsProvider = FutureProvider.family<List<FeatureFlag>, Object>(
  (ref, id) => ref.watch(environmentsRepositoryProvider).featureFlags(id),
);

final environmentsProvider =
    AsyncNotifierProvider.family<
      EnvironmentsNotifier,
      PagedListState<GlEnvironment>,
      Object
    >(EnvironmentsNotifier.new);

class EnvironmentsNotifier extends PagedListNotifier<GlEnvironment> {
  EnvironmentsNotifier(this.projectId);

  final Object projectId;

  @override
  Future<Paginated<GlEnvironment>> fetchPage(int page) {
    return ref
        .watch(environmentsRepositoryProvider)
        .environments(projectId, page: page);
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

final deploymentsProvider =
    AsyncNotifierProvider.family<
      DeploymentsNotifier,
      PagedListState<Deployment>,
      EnvironmentRef
    >(DeploymentsNotifier.new);

class DeploymentsNotifier extends PagedListNotifier<Deployment> {
  DeploymentsNotifier(this.loc);

  final EnvironmentRef loc;

  @override
  Future<Paginated<Deployment>> fetchPage(int page) {
    return ref
        .watch(environmentsRepositoryProvider)
        .deployments(loc.project, environmentId: loc.envId, page: page);
  }
}
