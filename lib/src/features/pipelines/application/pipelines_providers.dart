import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/pipelines/data/pipelines_repository.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_schedule.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_trigger.dart';

final pipelinesRepositoryProvider = Provider<PipelinesRepository>(
  (ref) => PipelinesRepository(ref.watch(apiClientProvider)),
);

final pipelinesProvider =
    AsyncNotifierProvider.family<
      PipelinesNotifier,
      PagedListState<Pipeline>,
      Object
    >(PipelinesNotifier.new);

class PipelinesNotifier extends PagedListNotifier<Pipeline> {
  PipelinesNotifier(this.project);

  final Object project;

  @override
  Future<Paginated<Pipeline>> fetchPage(int page) {
    return ref
        .watch(pipelinesRepositoryProvider)
        .pipelines(project, page: page);
  }
}

typedef PipelineRef = ({Object project, int id});

final pipelineProvider = FutureProvider.family<Pipeline, PipelineRef>(
  (ref, loc) =>
      ref.watch(pipelinesRepositoryProvider).pipeline(loc.project, loc.id),
);

final pipelineJobsProvider =
    AsyncNotifierProvider.family<
      PipelineJobsNotifier,
      PagedListState<Job>,
      PipelineRef
    >(PipelineJobsNotifier.new);

class PipelineJobsNotifier extends PagedListNotifier<Job> {
  PipelineJobsNotifier(this.loc);

  final PipelineRef loc;

  @override
  Future<Paginated<Job>> fetchPage(int page) {
    return ref
        .watch(pipelinesRepositoryProvider)
        .jobs(loc.project, loc.id, page: page);
  }
}

typedef JobRef = ({Object project, int id});

final jobProvider = FutureProvider.family<Job, JobRef>(
  (ref, loc) => ref.watch(pipelinesRepositoryProvider).job(loc.project, loc.id),
);

final jobTraceProvider = FutureProvider.family<String, JobRef>(
  (ref, loc) =>
      ref.watch(pipelinesRepositoryProvider).jobTrace(loc.project, loc.id),
);

typedef ProjectJobsFilter = ({Object project, String? scope});

final projectJobsProvider =
    AsyncNotifierProvider.family<
      ProjectJobsNotifier,
      PagedListState<Job>,
      ProjectJobsFilter
    >(ProjectJobsNotifier.new);

class ProjectJobsNotifier extends PagedListNotifier<Job> {
  ProjectJobsNotifier(this.filter);

  final ProjectJobsFilter filter;

  @override
  Future<Paginated<Job>> fetchPage(int page) {
    return ref
        .watch(pipelinesRepositoryProvider)
        .projectJobs(filter.project, page: page, scope: filter.scope);
  }
}

final pipelineTriggersProvider =
    FutureProvider.family<List<PipelineTrigger>, Object>(
      (ref, project) =>
          ref.watch(pipelinesRepositoryProvider).triggers(project),
    );

final pipelineSchedulesProvider =
    AsyncNotifierProvider.family<
      PipelineSchedulesNotifier,
      PagedListState<PipelineSchedule>,
      Object
    >(PipelineSchedulesNotifier.new);

class PipelineSchedulesNotifier extends PagedListNotifier<PipelineSchedule> {
  PipelineSchedulesNotifier(this.project);

  final Object project;

  @override
  Future<Paginated<PipelineSchedule>> fetchPage(int page) {
    return ref
        .watch(pipelinesRepositoryProvider)
        .schedules(project, page: page);
  }

  /// Runs the schedule now. The refetch only updates `last_pipeline`,
  /// so a failed refresh doesn't mask the triggered run.
  Future<void> play(int id) async {
    await ref.read(pipelinesRepositoryProvider).playSchedule(project, id);
    try {
      await refresh();
    } on Object {
      // The run was still triggered; the list just stays stale.
    }
  }

  Future<void> takeOwnership(int id) async {
    final updated = await ref
        .read(pipelinesRepositoryProvider)
        .takeScheduleOwnership(project, id);
    updateItems((items) => [for (final s in items) s.id == id ? updated : s]);
  }

  Future<void> remove(int id) async {
    await ref.read(pipelinesRepositoryProvider).deleteSchedule(project, id);
    updateItems((items) => items.where((s) => s.id != id).toList());
  }
}

final scheduleDetailProvider =
    FutureProvider.family<PipelineSchedule, PipelineRef>(
      (ref, loc) => ref
          .watch(pipelinesRepositoryProvider)
          .pipelineSchedule(loc.project, loc.id),
    );
