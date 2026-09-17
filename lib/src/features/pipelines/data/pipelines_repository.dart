import 'dart:isolate';
import 'dart:typed_data';

import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/pipelines/data/artifact_archive.dart';
import 'package:glam/src/features/pipelines/domain/artifact_entry.dart';
import 'package:glam/src/features/pipelines/domain/bridge.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_schedule.dart';
import 'package:glam/src/features/pipelines/domain/pipeline_trigger.dart';
import 'package:glam/src/features/pipelines/domain/test_report.dart';

/// `/projects/:id/pipelines` and `/jobs`.
class PipelinesRepository {
  const PipelinesRepository(this._client);

  /// Cap on anything fully buffered in memory — archives can reach
  /// hundreds of MB.
  static const _maxBufferedBytes = 256 * 1024 * 1024;

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  Future<Paginated<Pipeline>> pipelines(
    Object projectId, {
    String? ref,
    String? status,
    String? source,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipelines',
      query: {
        'ref': ?ref,
        'status': ?status,
        'source': ?source,
        'order_by': 'id',
        'sort': 'desc',
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Pipeline> pipeline(Object projectId, int id) {
    return _client.get(
      '${_p(projectId)}/pipelines/$id',
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// The most recent pipeline for the default branch
  /// (`/pipelines/latest`). 404s when the project never ran one.
  Future<Pipeline?> latestPipeline(Object projectId, {String? ref}) {
    return _client.get(
      '${_p(projectId)}/pipelines/latest',
      query: {'ref': ?ref},
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Pipeline> retryPipeline(Object projectId, int id) {
    return _client.post(
      '${_p(projectId)}/pipelines/$id/retry',
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Pipeline> cancelPipeline(Object projectId, int id) {
    return _client.post(
      '${_p(projectId)}/pipelines/$id/cancel',
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// CI/CD variables this pipeline ran with.
  Future<List<ScheduleVariable>> pipelineVariables(Object projectId, int id) {
    return _client.getAll(
      '${_p(projectId)}/pipelines/$id/variables',
      decoder: (j) => ScheduleVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Pipeline> createPipeline(Object projectId, String ref) {
    return _client.post(
      '${_p(projectId)}/pipeline',
      body: {'ref': ref},
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Aggregated test report for a pipeline. Pipelines without reports
  /// return a zeroed payload rather than an error.
  Future<TestReport> testReport(Object projectId, int id) {
    return _client.get(
      '${_p(projectId)}/pipelines/$id/test_report',
      decoder: (j) => TestReport.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Jobs belonging to a pipeline.
  Future<Paginated<Job>> jobs(
    Object projectId,
    int pipelineId, {
    bool includeRetried = false,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipelines/$pipelineId/jobs',
      query: {if (includeRetried) 'include_retried': true},
      page: page,
      perPage: perPage,
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Bridge jobs that triggered downstream pipelines
  /// (`/pipelines/:id/bridges`).
  Future<List<Bridge>> bridges(Object projectId, int pipelineId) {
    return _client.getAll(
      '${_p(projectId)}/pipelines/$pipelineId/bridges',
      decoder: (j) => Bridge.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// All jobs on the project, optionally filtered by status [scope]
  /// (e.g. `success`, `failed`, `running`).
  Future<Paginated<Job>> projectJobs(
    Object projectId, {
    int page = 1,
    String? scope,
  }) {
    return _client.getPage(
      '${_p(projectId)}/jobs',
      page: page,
      perPage: 50,
      query: {'scope': ?scope},
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Job> job(Object projectId, int jobId) {
    return _client.get(
      '${_p(projectId)}/jobs/$jobId',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// The job's console output (plain text).
  Future<String> jobTrace(Object projectId, int jobId) {
    return _client.getRaw('${_p(projectId)}/jobs/$jobId/trace');
  }

  /// Files inside the job's artifact archive.
  ///
  /// Newer GitLab versions expose `artifacts/tree`, which lists entries
  /// from metadata without downloading the zip. Instances that 404 it
  /// fall back to fetching the whole archive and unpacking it in
  /// memory.
  Future<List<ArtifactEntry>> artifactEntries(
    Object projectId,
    int jobId,
  ) async {
    try {
      final rows = await _client.getAll(
        '${_p(projectId)}/jobs/$jobId/artifacts/tree',
        query: {'recursive': true},
        decoder: (j) => j as Map<String, dynamic>,
      );
      return [
        for (final r in rows)
          if (r['type'] != 'tree') ArtifactEntry.fromJson(r),
      ]..sort((a, b) => a.path.compareTo(b.path));
    } on ApiException catch (e) {
      if (e.kind != ApiErrorKind.notFound) {
        rethrow;
      }
    }
    final zip = await artifactsArchive(projectId, jobId);
    return Isolate.run(() => decodeArtifactEntries(zip));
  }

  /// The job's artifact archive as zip bytes.
  Future<Uint8List> artifactsArchive(Object projectId, int jobId) {
    return _client.getBytes(
      '${_p(projectId)}/jobs/$jobId/artifacts',
      maxBytes: _maxBufferedBytes,
    );
  }

  /// One file inside the archive
  /// (`GET /projects/:id/jobs/:job_id/artifacts/*artifact_path`).
  Future<Uint8List> artifactFile(Object projectId, int jobId, String path) {
    final encoded = path.split('/').map(Uri.encodeComponent).join('/');
    return _client.getBytes(
      '${_p(projectId)}/jobs/$jobId/artifacts/$encoded',
      maxBytes: _maxBufferedBytes,
    );
  }

  Future<Job> retryJob(Object projectId, int jobId) {
    return _client.post(
      '${_p(projectId)}/jobs/$jobId/retry',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Job> cancelJob(Object projectId, int jobId) {
    return _client.post(
      '${_p(projectId)}/jobs/$jobId/cancel',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Manual jobs (`status: manual`) get played.
  Future<Job> playJob(Object projectId, int jobId) {
    return _client.post(
      '${_p(projectId)}/jobs/$jobId/play',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Erases the job's trace and artifacts.
  Future<Job> eraseJob(Object projectId, int jobId) {
    return _client.post(
      '${_p(projectId)}/jobs/$jobId/erase',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Prevents a successful job's artifacts from expiring.
  Future<Job> keepArtifacts(Object projectId, int jobId) {
    return _client.post(
      '${_p(projectId)}/jobs/$jobId/artifacts/keep',
      decoder: (j) => Job.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Deletes the job's artifacts (must be unlocked first upstream).
  Future<void> deleteArtifacts(Object projectId, int jobId) {
    return _client.delete('${_p(projectId)}/jobs/$jobId/artifacts');
  }

  /// Pipeline trigger tokens (`/projects/:id/triggers`).
  Future<List<PipelineTrigger>> triggers(Object projectId) {
    return _client.getAll(
      '${_p(projectId)}/triggers',
      decoder: (j) => PipelineTrigger.fromJson(j as Map<String, dynamic>),
    );
  }

  /// Creates a trigger. The full token is only in this response.
  Future<PipelineTrigger> createTrigger(Object projectId, String description) {
    return _client.post(
      '${_p(projectId)}/triggers',
      body: {'description': description},
      decoder: (j) => PipelineTrigger.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteTrigger(Object projectId, int triggerId) {
    return _client.delete('${_p(projectId)}/triggers/$triggerId');
  }

  /// Validates `.gitlab-ci.yml` content (`POST /projects/:id/ci/lint`).
  Future<CiLintResult> ciLint(Object projectId, String content) {
    return _client.post(
      '${_p(projectId)}/ci/lint',
      body: {'content': content, 'include_jobs': true},
      decoder: (j) => CiLintResult.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Scheduled pipelines (`/pipeline_schedules`).
  Future<Paginated<PipelineSchedule>> schedules(
    Object projectId, {
    int page = 1,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipeline_schedules',
      page: page,
      decoder: (j) => PipelineSchedule.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Detail carries the schedule's variables; the list payload doesn't.
  Future<PipelineSchedule> pipelineSchedule(Object projectId, int id) {
    return _client.get(
      '${_p(projectId)}/pipeline_schedules/$id',
      decoder: (j) => PipelineSchedule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<PipelineSchedule> createSchedule(
    Object projectId, {
    required String description,
    required String ref,
    required String cron,
    String? cronTimezone,
    bool active = true,
  }) {
    return _client.post(
      '${_p(projectId)}/pipeline_schedules',
      body: {
        'description': description,
        'ref': ref,
        'cron': cron,
        'cron_timezone': ?cronTimezone,
        'active': active,
      },
      decoder: (j) => PipelineSchedule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<PipelineSchedule> updateSchedule(
    Object projectId,
    int id, {
    String? description,
    String? ref,
    String? cron,
    String? cronTimezone,
    bool? active,
  }) {
    return _client.put(
      '${_p(projectId)}/pipeline_schedules/$id',
      body: {
        'description': ?description,
        'ref': ?ref,
        'cron': ?cron,
        'cron_timezone': ?cronTimezone,
        'active': ?active,
      },
      decoder: (j) => PipelineSchedule.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteSchedule(Object projectId, int id) {
    return _client.delete('${_p(projectId)}/pipeline_schedules/$id');
  }

  /// Triggers a run outside the schedule. GitLab only returns a
  /// `201 Created` message, so there's nothing to decode.
  Future<void> playSchedule(Object projectId, int id) {
    return _client.post(
      '${_p(projectId)}/pipeline_schedules/$id/play',
      decoder: (j) => j,
    );
  }

  /// Claims a schedule owned by someone else.
  Future<PipelineSchedule> takeScheduleOwnership(Object projectId, int id) {
    return _client.post(
      '${_p(projectId)}/pipeline_schedules/$id/take_ownership',
      decoder: (j) => PipelineSchedule.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Pipelines a schedule produced (`/pipeline_schedules/:id/pipelines`).
  Future<Paginated<Pipeline>> schedulePipelines(
    Object projectId,
    int id, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipeline_schedules/$id/pipelines',
      page: page,
      perPage: perPage,
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Test coverage for the pipeline (`/pipelines/:id/test_report_summary`);
  /// null when the pipeline reports none.
  Future<double?> testReportCoverage(Object projectId, int pipelineId) {
    return _client.get(
      '${_p(projectId)}/pipelines/$pipelineId/test_report_summary',
      decoder: (j) {
        final raw = (j! as Map<String, dynamic>)['coverage'];
        return raw is num ? raw.toDouble() : double.tryParse('$raw');
      },
    );
  }

  /// Schedule variables are their own sub-resource: POST creates, PUT
  /// updates an existing key.
  Future<void> createScheduleVariable(
    Object projectId,
    int id, {
    required String key,
    required String value,
    String variableType = 'env_var',
  }) {
    return _client.post(
      '${_p(projectId)}/pipeline_schedules/$id/variables',
      body: {'key': key, 'value': value, 'variable_type': variableType},
      decoder: (j) => j,
    );
  }

  Future<void> updateScheduleVariable(
    Object projectId,
    int id,
    String key, {
    required String value,
    String variableType = 'env_var',
  }) {
    return _client.put(
      '${_p(projectId)}/pipeline_schedules/$id/variables/'
      '${Uri.encodeComponent(key)}',
      body: {'value': value, 'variable_type': variableType},
      decoder: (j) => j,
    );
  }

  Future<void> deleteScheduleVariable(Object projectId, int id, String key) {
    return _client.delete(
      '${_p(projectId)}/pipeline_schedules/$id/variables/'
      '${Uri.encodeComponent(key)}',
    );
  }
}
