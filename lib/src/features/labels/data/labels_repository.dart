import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/features/labels/domain/label.dart';

/// `/projects/:id/labels` and `/groups/:id/labels`.
class LabelsRepository {
  const LabelsRepository(this._client);

  final GitLabApiClient _client;

  String _base(Object id, {required bool isProject}) =>
      '/${isProject ? 'projects' : 'groups'}'
      '/${GitLabApiClient.encodeProject(id)}/labels';

  Label _decode(Object? j) => Label.fromJson(j! as Map<String, dynamic>);

  Future<List<Label>> labels(
    Object id, {
    required bool isProject,
    String? search,
  }) {
    return _client.getAll(
      _base(id, isProject: isProject),
      query: {'search': ?search, 'with_counts': true},
      decoder: _decode,
    );
  }

  Future<Label> create(
    Object id, {
    required bool isProject,
    required String name,
    required String color,
    String? description,
  }) {
    return _client.post(
      _base(id, isProject: isProject),
      body: {'name': name, 'color': color, 'description': ?description},
      decoder: _decode,
    );
  }

  /// GitLab's labels API is key-based: `name` identifies the label,
  /// `new_name`/`color` carry the changes.
  Future<Label> update(
    Object id, {
    required bool isProject,
    required String name,
    String? newName,
    String? color,
    String? description,
  }) {
    return _client.put(
      _base(id, isProject: isProject),
      body: {
        'name': name,
        'new_name': ?newName,
        'color': ?color,
        'description': ?description,
      },
      decoder: _decode,
    );
  }

  Future<void> delete(
    Object id, {
    required bool isProject,
    required String name,
  }) {
    return _client.delete(
      _base(id, isProject: isProject),
      query: {'name': name},
    );
  }
}
