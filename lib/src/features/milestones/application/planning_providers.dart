import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/labels/data/labels_repository.dart';
import 'package:glam/src/features/labels/domain/label.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';
import 'package:glam/src/features/milestones/data/milestones_repository.dart';

final milestonesRepositoryProvider = Provider<MilestonesRepository>(
  (ref) => MilestonesRepository(ref.watch(apiClientProvider)),
);

final labelsRepositoryProvider = Provider<LabelsRepository>(
  (ref) => LabelsRepository(ref.watch(apiClientProvider)),
);

/// A project or group container — milestones and labels live in both.
typedef ContainerScope = ({Object id, bool isProject});

typedef MilestoneFilter = ({ContainerScope scope, String? state});

final milestonesProvider =
    AsyncNotifierProvider.family<
      MilestonesNotifier,
      PagedListState<Milestone>,
      MilestoneFilter
    >(MilestonesNotifier.new);

class MilestonesNotifier extends PagedListNotifier<Milestone> {
  MilestonesNotifier(this.filter);

  final MilestoneFilter filter;

  @override
  Future<Paginated<Milestone>> fetchPage(int page) {
    return ref
        .watch(milestonesRepositoryProvider)
        .milestones(
          filter.scope.id,
          isProject: filter.scope.isProject,
          state: filter.state,
          page: page,
        );
  }
}

typedef MilestoneRef = ({Object projectId, int milestoneId});

final milestoneProvider = FutureProvider.family<Milestone, MilestoneRef>(
  (ref, loc) => ref
      .watch(milestonesRepositoryProvider)
      .milestone(loc.projectId, loc.milestoneId, isProject: true),
);

final milestoneIssuesProvider =
    FutureProvider.family<List<Issue>, MilestoneRef>(
      (ref, loc) => ref
          .watch(milestonesRepositoryProvider)
          .milestoneIssues(loc.projectId, loc.milestoneId),
    );

final milestoneMrsProvider =
    FutureProvider.family<List<MergeRequest>, MilestoneRef>(
      (ref, loc) => ref
          .watch(milestonesRepositoryProvider)
          .milestoneMrs(loc.projectId, loc.milestoneId),
    );

final labelsProvider = FutureProvider.family<List<Label>, ContainerScope>(
  (ref, scope) => ref
      .watch(labelsRepositoryProvider)
      .labels(scope.id, isProject: scope.isProject),
);
