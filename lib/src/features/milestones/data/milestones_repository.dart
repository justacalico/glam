import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/milestone.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/merge_requests/domain/merge_request.dart';

/// `/projects/:id/milestones` and `/groups/:id/milestones`.
class MilestonesRepository {
  const MilestonesRepository(this._client);

  final GitLabApiClient _client;

  String _base(Object id, {required bool isProject}) =>
      '/${isProject ? 'projects' : 'groups'}'
      '/${GitLabApiClient.encodeProject(id)}/milestones';

  Milestone _decode(Object? j) =>
      Milestone.fromJson(j! as Map<String, dynamic>);

  Future<Paginated<Milestone>> milestones(
    Object id, {
    required bool isProject,
    String? state,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      _base(id, isProject: isProject),
      query: {'state': ?state, 'search': ?search},
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  Future<Milestone> milestone(
    Object id,
    int milestoneId, {
    required bool isProject,
  }) {
    return _client.get(
      '${_base(id, isProject: isProject)}/$milestoneId',
      decoder: _decode,
    );
  }

  Future<List<Issue>> milestoneIssues(Object id, int milestoneId) {
    return _client.getAll(
      '${_base(id, isProject: true)}/$milestoneId/issues',
      decoder: (j) => Issue.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<List<MergeRequest>> milestoneMrs(Object id, int milestoneId) {
    return _client.getAll(
      '${_base(id, isProject: true)}/$milestoneId/merge_requests',
      decoder: (j) => MergeRequest.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Milestone> create(
    Object id, {
    required bool isProject,
    required String title,
    String? description,
    String? dueDate,
    String? startDate,
  }) {
    return _client.post(
      _base(id, isProject: isProject),
      body: {
        'title': title,
        'description': ?description,
        'due_date': ?dueDate,
        'start_date': ?startDate,
      },
      decoder: _decode,
    );
  }

  Future<Milestone> update(
    Object id,
    int milestoneId, {
    required bool isProject,
    String? title,
    String? description,
    String? dueDate,
    String? startDate,
    String? stateEvent,
  }) {
    return _client.put(
      '${_base(id, isProject: isProject)}/$milestoneId',
      body: {
        'title': ?title,
        'description': ?description,
        'due_date': ?dueDate,
        'start_date': ?startDate,
        'state_event': ?stateEvent,
      },
      decoder: _decode,
    );
  }
}
