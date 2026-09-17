import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/audit_event.dart';
import 'package:glam/src/core/models/ci_variable.dart';
import 'package:glam/src/core/models/deploy_token.dart';
import 'package:glam/src/core/models/iteration.dart';
import 'package:glam/src/core/models/webhook.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/groups/data/groups_repository.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/projects/domain/project.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepository(ref.watch(apiClientProvider)),
);

final groupsProvider =
    AsyncNotifierProvider.family<
      GroupsNotifier,
      PagedListState<Group>,
      String?
    >(GroupsNotifier.new);

class GroupsNotifier extends PagedListNotifier<Group> {
  GroupsNotifier(this.search);

  final String? search;

  @override
  Future<Paginated<Group>> fetchPage(int page) {
    return ref
        .watch(groupsRepositoryProvider)
        .groups(search: search, page: page);
  }
}

final groupProvider = FutureProvider.family<Group, Object>(
  (ref, id) => ref.watch(groupsRepositoryProvider).group(id),
);

/// Groups the user owns — used as the parent picker when creating groups.
final ownedGroupsProvider = FutureProvider<List<Group>>(
  (ref) async =>
      (await ref
              .watch(groupsRepositoryProvider)
              .groups(ownedOnly: true, perPage: 100))
          .items,
);

final subgroupsProvider =
    AsyncNotifierProvider.family<
      SubgroupsNotifier,
      PagedListState<Group>,
      Object
    >(SubgroupsNotifier.new);

class SubgroupsNotifier extends PagedListNotifier<Group> {
  SubgroupsNotifier(this.groupId);

  final Object groupId;

  @override
  Future<Paginated<Group>> fetchPage(int page) {
    return ref.watch(groupsRepositoryProvider).subgroups(groupId, page: page);
  }
}

typedef GroupProjectFilter = ({Object group, String? search});

final groupProjectsProvider =
    AsyncNotifierProvider.family<
      GroupProjectsNotifier,
      PagedListState<Project>,
      GroupProjectFilter
    >(GroupProjectsNotifier.new);

class GroupProjectsNotifier extends PagedListNotifier<Project> {
  GroupProjectsNotifier(this.filter);

  final GroupProjectFilter filter;

  @override
  Future<Paginated<Project>> fetchPage(int page) {
    return ref
        .watch(groupsRepositoryProvider)
        .groupProjects(filter.group, page: page, search: filter.search);
  }
}

/// Projects shared with the group.
final sharedProjectsProvider =
    AsyncNotifierProvider.family<
      SharedProjectsNotifier,
      PagedListState<Project>,
      Object
    >(SharedProjectsNotifier.new);

class SharedProjectsNotifier extends PagedListNotifier<Project> {
  SharedProjectsNotifier(this.groupId);

  final Object groupId;

  @override
  Future<Paginated<Project>> fetchPage(int page) {
    return ref
        .watch(groupsRepositoryProvider)
        .sharedProjects(groupId, page: page);
  }
}

/// Group-level CI/CD variables.
final groupVariablesProvider = FutureProvider.family<List<CiVariable>, Object>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).groupVariables(groupId),
);

final groupHooksProvider = FutureProvider.family<List<Webhook>, Object>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).webhooks(groupId),
);

/// Group-level deploy tokens.
final groupDeployTokensProvider =
    FutureProvider.family<List<DeployToken>, Object>(
      (ref, groupId) =>
          ref.watch(groupsRepositoryProvider).deployTokens(groupId),
    );

/// Iterations defined on the group and its ancestors. Empty on
/// Free tier / self-hosted CE where the endpoint is absent.
final groupIterationsProvider = FutureProvider.family<List<Iteration>, Object>((
  ref,
  groupId,
) async {
  try {
    return await ref
        .watch(groupsRepositoryProvider)
        .iterations(groupId, state: 'all');
  } on ApiException catch (e) {
    if (e.statusCode == 404 || e.statusCode == 403) {
      return const [];
    }
    rethrow;
  }
});

/// Audit events on the group. Empty where the endpoint is
/// premium-gated or absent.
final groupAuditEventsProvider =
    FutureProvider.family<List<AuditEvent>, Object>((ref, groupId) async {
      try {
        return await ref.watch(groupsRepositoryProvider).auditEvents(groupId);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          return const [];
        }
        rethrow;
      }
    });

/// Members of a group or project (depending on `kind`).
typedef MemberScope = ({Object id, bool isProject});

/// Pending access requests on the scope; empty for non-maintainers
/// or where the endpoint is absent.
final accessRequestsProvider = FutureProvider.family<List<Member>, MemberScope>(
  (ref, scope) async {
    try {
      return await ref
          .watch(groupsRepositoryProvider)
          .accessRequests(scope.id, isProject: scope.isProject);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 403) {
        return const [];
      }
      rethrow;
    }
  },
);

typedef MemberFilter = ({Object id, bool isProject, String? query});

final membersProvider =
    AsyncNotifierProvider.family<
      MembersNotifier,
      PagedListState<Member>,
      MemberFilter
    >(MembersNotifier.new);

class MembersNotifier extends PagedListNotifier<Member> {
  MembersNotifier(this.filter);

  final MemberFilter filter;

  @override
  Future<Paginated<Member>> fetchPage(int page) {
    final repo = ref.watch(groupsRepositoryProvider);
    return filter.isProject
        ? repo.projectMembers(filter.id, page: page, query: filter.query)
        : repo.groupMembers(filter.id, page: page, query: filter.query);
  }
}
