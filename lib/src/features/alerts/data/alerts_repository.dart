import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/alerts/domain/alert.dart';

/// Monitor > Alerts (`/alert_management/alerts`).
class AlertsRepository {
  const AlertsRepository(this._client);

  final GitLabApiClient _client;

  String _p(Object projectId) =>
      '/projects/${GitLabApiClient.encodeProject(projectId)}'
      '/alert_management/alerts';

  Future<Paginated<Alert>> alerts(
    Object projectId, {
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      _p(projectId),
      query: {'status': ?status},
      page: page,
      perPage: perPage,
      decoder: (j) => Alert.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Editable fields per the REST API: title, assignee, and status.
  Future<Alert> updateAlert(
    Object projectId,
    int iid, {
    String? title,
    String? assigneeUsername,
    String? status,
  }) {
    return _client.put(
      '${_p(projectId)}/$iid',
      body: {
        'title': ?title,
        'assignee_username': ?assigneeUsername,
        'status': ?status,
      },
      decoder: (j) => Alert.fromJson(j! as Map<String, dynamic>),
    );
  }
}
