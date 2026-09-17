import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/ci_variable.dart';
import 'package:glam/src/core/models/iteration.dart';
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

  /// Creates a group, optionally nested under [parentId].
  Future<Group> createGroup({
    required String name,
    required String path,
    int? parentId,
    String? description,
    String? visibility,
  }) {
    return _client.post(
      '/groups',
      body: {
        'name': name,
        'path': path,
        'parent_id': ?parentId,
        'description': ?description,
        'visibility': ?visibility,
      },
      decoder: (j) => Group.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Edits group fields. Moving a group to a new parent uses
  /// `POST /groups/:id/transfer`, not this endpoint.
  Future<Group> updateGroup(
    Object groupId, {
    String? name,
    String? path,
    String? description,
    String? visibility,
  }) {
    return _client.put(
      '/groups/${GitLabApiClient.encodeProject(groupId)}',
      body: {
        'name': ?name,
        'path': ?path,
        'description': ?description,
        'visibility': ?visibility,
      },
      decoder: (j) => Group.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Deletes a group and everything inside it.
  Future<void> deleteGroup(Object groupId) {
    return _client.delete(_g(groupId));
  }

  /// Iterations the group and its ancestors define (GitLab Premium).
  /// `state` accepts `opened`, `upcoming`, `current`, `closed`,
  /// `started` (deprecated alias of `current`), or `all`.
  Future<List<Iteration>> iterations(
    Object groupId, {
    String state = 'opened',
  }) {
    return _client.getAll(
      '${_g(groupId)}/iterations',
      query: {'state': state},
      decoder: (j) => Iteration.fromJson(j! as Map<String, dynamic>),
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

  /// Projects shared with this group (`/groups/:id/projects/shared`).
  Future<Paginated<Project>> sharedProjects(
    Object groupId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '${_g(groupId)}/projects/shared',
      page: page,
      perPage: perPage,
      decoder: (j) => Project.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Group CI/CD variables (`/groups/:id/variables`).
  Future<List<CiVariable>> groupVariables(Object groupId) {
    return _client.getAll(
      '${_g(groupId)}/variables',
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<CiVariable> createGroupVariable(
    Object groupId, {
    required String key,
    required String value,
    bool protected_ = false,
    bool masked = false,
    String environmentScope = '*',
  }) {
    return _client.post(
      '${_g(groupId)}/variables',
      body: {
        'key': key,
        'value': value,
        'protected': protected_,
        'masked': masked,
        'environment_scope': environmentScope,
      },
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<CiVariable> updateGroupVariable(
    Object groupId,
    String key, {
    required String value,
    bool? protected_,
    bool? masked,
    String? environmentScope,
  }) {
    return _client.put(
      '${_g(groupId)}/variables/$key',
      body: {
        'value': value,
        'protected': ?protected_,
        'masked': ?masked,
        'environment_scope': ?environmentScope,
      },
      decoder: (j) => CiVariable.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteGroupVariable(Object groupId, String key) {
    return _client.delete('${_g(groupId)}/variables/$key');
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

  String _membersBase(Object id, {required bool isProject}) =>
      '/${isProject ? 'projects' : 'groups'}'
      '/${GitLabApiClient.encodeProject(id)}/members';

  /// Adds a member by user id, username, or email. Emails the person
  /// an invite when the address isn't tied to an account yet.
  Future<Member> addMember(
    Object id, {
    required bool isProject,
    required int accessLevel,
    int? userId,
    String? username,
    String? email,
    String? expiresAt,
  }) {
    return _client.post(
      _membersBase(id, isProject: isProject),
      body: {
        'user_id': ?userId,
        'username': ?username,
        'email': ?email,
        'access_level': accessLevel,
        'expires_at': ?expiresAt,
      },
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Changes a member's role.
  Future<Member> updateMember(
    Object id,
    int memberId, {
    required bool isProject,
    required int accessLevel,
    String? expiresAt,
  }) {
    return _client.put(
      '${_membersBase(id, isProject: isProject)}/$memberId',
      body: {'access_level': accessLevel, 'expires_at': ?expiresAt},
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> removeMember(
    Object id,
    int memberId, {
    required bool isProject,
  }) {
    return _client.delete(
      '${_membersBase(id, isProject: isProject)}/$memberId',
    );
  }
}
