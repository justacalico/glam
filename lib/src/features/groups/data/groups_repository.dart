import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/projects/domain/project.dart';

/// `/groups` plus members endpoints for both groups and projects.
class GroupsRepository {
  const GroupsRepository(this._client);

  final GitLabApiClient _client;

  String _g(Object groupId) =>
      '/groups/${GitLabApiClient.encodeProject(groupId)}';

  /// Top-level groups the user can see.
  Future<Paginated<Group>> groups({
    String? search,
    bool ownedOnly = false,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/groups',
      query: {
        'search': ?search,
        if (ownedOnly) 'owned': true,
        'top_level_only': true,
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Group.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Group> group(Object groupId) {
    return _client.get(
      _g(groupId),
      decoder: (j) => Group.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Subgroups of a group.
  Future<Paginated<Group>> subgroups(
    Object groupId, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_g(groupId)}/subgroups',
      page: page,
      perPage: perPage,
      decoder: (j) => Group.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Projects directly inside the group (not inherited).
  Future<Paginated<Project>> groupProjects(
    Object groupId, {
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_g(groupId)}/projects',
      query: {
        'search': ?search,
        'include_subgroups': false,
        'order_by': 'last_activity_at',
      },
      page: page,
      perPage: perPage,
      decoder: (j) => Project.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Group members.
  Future<Paginated<Member>> groupMembers(
    Object groupId, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_g(groupId)}/members/all',
      page: page,
      perPage: perPage,
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Project members (direct + inherited).
  Future<Paginated<Member>> projectMembers(
    Object projectId, {
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(projectId)}/members/all',
      page: page,
      perPage: perPage,
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }
}
