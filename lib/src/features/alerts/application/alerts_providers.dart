import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/alerts/data/alerts_repository.dart';
import 'package:glam/src/features/alerts/domain/alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (ref) => AlertsRepository(ref.watch(apiClientProvider)),
);

typedef AlertFilter = ({Object project, String? status});

final projectAlertsProvider =
    AsyncNotifierProvider.family<
      ProjectAlertsNotifier,
      PagedListState<Alert>,
      AlertFilter
    >(ProjectAlertsNotifier.new);

class ProjectAlertsNotifier extends PagedListNotifier<Alert> {
  ProjectAlertsNotifier(this.filter);

  final AlertFilter filter;

  @override
  Future<Paginated<Alert>> fetchPage(int page) async {
    try {
      return await ref
          .watch(alertsRepositoryProvider)
          .alerts(filter.project, status: filter.status, page: page);
    } on ApiException catch (e) {
      // Alert management needs a maintainer-level token on some tiers.
      if (e.statusCode == 403 || e.statusCode == 404) {
        return const Paginated(items: <Alert>[], page: 1, perPage: 20);
      }
      rethrow;
    }
  }

  Future<void> setStatus(int iid, String status) async {
    final updated = await ref
        .read(alertsRepositoryProvider)
        .updateAlert(filter.project, iid, status: status);
    updateItems((items) => [for (final a in items) a.iid == iid ? updated : a]);
  }
}
