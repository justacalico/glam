import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/activity/domain/event.dart';
import 'package:glam/src/features/activity/domain/notification.dart';

/// `/events` activity feeds and `/notifications`.
class ActivityRepository {
  const ActivityRepository(this._client);

  final GitLabApiClient _client;

  ActivityEvent _decode(Object? j) =>
      ActivityEvent.fromJson(j! as Map<String, dynamic>);

  /// The current user's event feed.
  Future<Paginated<ActivityEvent>> events({
    String? action,
    String? targetType,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/events',
      query: {'action': ?action, 'target_type': ?targetType},
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// Events inside one project.
  Future<Paginated<ActivityEvent>> projectEvents(
    Object projectId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(projectId)}/events',
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// Public events authored by a user.
  Future<Paginated<ActivityEvent>> userEvents(
    Object userId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/users/${GitLabApiClient.encodeProject(userId)}/events',
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// Unread notifications for the current user.
  Future<Paginated<GlamNotification>> notifications({
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/notifications',
      page: page,
      perPage: perPage,
      decoder: (j) => GlamNotification.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> markAllRead() {
    return _client.post('/notifications/mark_as_read', decoder: (_) {});
  }
}
