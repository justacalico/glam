import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';

/// `/projects/:id/pipelines` and `/jobs`.
class PipelinesRepository {
  const PipelinesRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}';

  Future<Paginated<Pipeline>> pipelines(
    Object projectId, {
    String? ref,
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipelines',
      query: {'ref': ?ref, 'status': ?status, 'order_by': 'id', 'sort': 'desc'},
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

  Future<Pipeline> createPipeline(Object projectId, String ref) {
    return _client.post(
      '${_p(projectId)}/pipeline',
      body: {'ref': ref},
      decoder: (j) => Pipeline.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Jobs belonging to a pipeline.
  Future<Paginated<Job>> jobs(
    Object projectId,
    int pipelineId, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_p(projectId)}/pipelines/$pipelineId/jobs',
      page: page,
      perPage: perPage,
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
}
