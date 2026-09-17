import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/audit_event.dart';
import 'package:glam/src/core/models/ci_variable.dart';
import 'package:glam/src/core/models/deploy_token.dart';
import 'package:glam/src/core/models/iteration.dart';
import 'package:glam/src/features/groups/domain/group.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/core/models/webhook.dart';

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

  /// Group webhooks (`/groups/:id/hooks`).
  Future<List<Webhook>> webhooks(Object groupId) {
    return _client.getAll(
      '${_g(groupId)}/hooks',
      decoder: (j) => Webhook.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Webhook> createHook(
    Object groupId, {
    required String url,
    String? token,
    Map<String, bool> events = const {},
    bool enableSslVerification = true,
  }) {
    return _client.post(
      '${_g(groupId)}/hooks',
      body: {
        'url': url,
        'token': ?token,
        ...events,
        'enable_ssl_verification': enableSslVerification,
      },
      decoder: (j) => Webhook.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> testHook(Object groupId, int hookId) {
    return _client.post(
      '${_g(groupId)}/hooks/$hookId/test/push_events',
      decoder: (j) => j,
    );
  }

  Future<void> deleteHook(Object groupId, int hookId) {
    return _client.delete('${_g(groupId)}/hooks/$hookId');
  }

  /// Audit events (`/groups/:id/audit_events`); premium-gated upstream.
  Future<List<AuditEvent>> auditEvents(Object groupId) {
    return _client.getAll(
      '${_g(groupId)}/audit_events',
      decoder: (j) => AuditEvent.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Group members.
  Future<Paginated<Member>> groupMembers(
    Object groupId, {
    String? query,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '${_g(groupId)}/members/all',
      query: {'query': ?query},
      page: page,
      perPage: perPage,
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Project members (direct + inherited).
  Future<Paginated<Member>> projectMembers(
    Object projectId, {
    String? query,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(projectId)}/members/all',
      query: {'query': ?query},
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

  String _scopeBase(Object id, {required bool isProject}) =>
      '/${isProject ? 'projects' : 'groups'}'
      '/${GitLabApiClient.encodeProject(id)}';

  /// Pending access requests (`/:kind/:id/access_requests`); needs a
  /// maintainer role upstream.
  Future<List<Member>> accessRequests(Object id, {required bool isProject}) {
    return _client.getAll(
      '${_scopeBase(id, isProject: isProject)}/access_requests',
      decoder: (j) => Member.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// Approves a request, optionally at a specific level.
  Future<void> approveAccessRequest(
    Object id,
    int userId, {
    required bool isProject,
    int? accessLevel,
  }) {
    return _client.put(
      '${_scopeBase(id, isProject: isProject)}'
      '/access_requests/$userId/approve',
      body: {'access_level': ?accessLevel},
      decoder: (_) {},
    );
  }

  Future<void> denyAccessRequest(
    Object id,
    int userId, {
    required bool isProject,
  }) {
    return _client.delete(
      '${_scopeBase(id, isProject: isProject)}/access_requests/$userId',
    );
  }

  /// Shares this group with another group (`POST /groups/:id/share`).
  /// Owner role required.
  Future<void> shareGroup(
    Object id, {
    required int groupId,
    required int accessLevel,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '${_scopeBase(id, isProject: false)}/share',
      body: {
        'group_id': groupId,
        'group_access': accessLevel,
        'expires_at': ?expiresAt?.toIso8601String().substring(0, 10),
      },
      decoder: (_) {},
    );
  }

  /// Removes a group share (`DELETE /groups/:id/share/:group_id`).
  Future<void> unshareGroup(Object id, int sharedGroupId) {
    return _client.delete(
      '${_scopeBase(id, isProject: false)}/share/$sharedGroupId',
    );
  }

  /// Deploy tokens (`/groups/:id/deploy_tokens`).
  Future<List<DeployToken>> deployTokens(Object id) {
    return _client.getAll(
      '${_scopeBase(id, isProject: false)}/deploy_tokens',
      decoder: (j) => DeployToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  /// The create response carries `token` — the only time GitLab ever
  /// returns the secret.
  Future<DeployToken> createDeployToken(
    Object id, {
    required String name,
    required List<String> scopes,
    String? username,
    DateTime? expiresAt,
  }) {
    return _client.post(
      '${_scopeBase(id, isProject: false)}/deploy_tokens',
      body: {
        'name': name,
        'scopes': scopes,
        'username': ?username,
        'expires_at': ?expiresAt?.toIso8601String().substring(0, 10),
      },
      decoder: (j) => DeployToken.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteDeployToken(Object id, int tokenId) {
    return _client.delete(
      '${_scopeBase(id, isProject: false)}/deploy_tokens/$tokenId',
    );
  }
}
