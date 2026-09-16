import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/core/api/paged_list.dart';
import 'package:glam/src/core/api/paginated_response.dart';
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

final groupProjectsProvider =
    AsyncNotifierProvider.family<
      GroupProjectsNotifier,
      PagedListState<Project>,
      Object
    >(GroupProjectsNotifier.new);

class GroupProjectsNotifier extends PagedListNotifier<Project> {
  GroupProjectsNotifier(this.groupId);

  final Object groupId;

  @override
  Future<Paginated<Project>> fetchPage(int page) {
    return ref
        .watch(groupsRepositoryProvider)
        .groupProjects(groupId, page: page);
  }
}

/// Members of a group or project (depending on `kind`).
typedef MemberScope = ({Object id, bool isProject});

final membersProvider =
    AsyncNotifierProvider.family<
      MembersNotifier,
      PagedListState<Member>,
      MemberScope
    >(MembersNotifier.new);

class MembersNotifier extends PagedListNotifier<Member> {
  MembersNotifier(this.scope);

  final MemberScope scope;

  @override
  Future<Paginated<Member>> fetchPage(int page) {
    final repo = ref.watch(groupsRepositoryProvider);
    return scope.isProject
        ? repo.projectMembers(scope.id, page: page)
        : repo.groupMembers(scope.id, page: page);
  }
}
