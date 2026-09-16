import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/activity/data/activity_repository.dart';
import 'package:glam/src/features/activity/domain/event.dart';
import 'package:glam/src/features/activity/domain/notification.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(apiClientProvider)),
);

/// Which feed to load: the user's own, a project's, or a user's public.
typedef EventFeed = ({String kind, Object? id});

const ownFeed = (kind: 'own', id: null);

final activityProvider =
    AsyncNotifierProvider.family<
      ActivityNotifier,
      PagedListState<ActivityEvent>,
      EventFeed
    >(ActivityNotifier.new);

class ActivityNotifier extends PagedListNotifier<ActivityEvent> {
  ActivityNotifier(this.feed);

  final EventFeed feed;

  @override
  Future<Paginated<ActivityEvent>> fetchPage(int page) {
    final repo = ref.watch(activityRepositoryProvider);
    return switch (feed.kind) {
      'project' => repo.projectEvents(feed.id!, page: page),
      'user' => repo.userEvents(feed.id!, page: page),
      _ => repo.events(page: page),
    };
  }
}

final notificationsProvider =
    AsyncNotifierProvider<
      NotificationsNotifier,
      PagedListState<GlamNotification>
    >(NotificationsNotifier.new);

class NotificationsNotifier extends PagedListNotifier<GlamNotification> {
  @override
  Future<Paginated<GlamNotification>> fetchPage(int page) {
    return ref.watch(activityRepositoryProvider).notifications(page: page);
  }

  Future<void> markAllRead() async {
    await ref.read(activityRepositoryProvider).markAllRead();
    await refresh();
  }
}
