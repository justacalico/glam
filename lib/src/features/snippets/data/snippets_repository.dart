import 'package:glam/src/core/api/gitlab_api_client.dart';
import 'package:glam/src/core/api/paginated_response.dart';
import 'package:glam/src/core/models/award_emoji.dart';
import 'package:glam/src/core/models/note.dart';
import 'package:glam/src/features/snippets/domain/snippet.dart';

/// `/snippets` for personal snippets plus `/projects/:id/snippets`.
class SnippetsRepository {
  const SnippetsRepository(this._client);

  final GitLabApiClient _client;

  Snippet _decode(Object? j) => Snippet.fromJson(j! as Map<String, dynamic>);

  /// Snippets owned by the current user.
  Future<Paginated<Snippet>> snippets({
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/snippets',
      query: {'search': ?search},
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  /// Every snippet on the instance marked public.
  Future<Paginated<Snippet>> publicSnippets({
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/snippets/public',
      query: {'search': ?search},
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  Future<Paginated<Snippet>> projectSnippets(
    Object projectId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _client.getPage(
      '/projects/${GitLabApiClient.encodeProject(projectId)}/snippets',
      page: page,
      perPage: perPage,
      decoder: _decode,
    );
  }

  Future<Snippet> snippet(int id, {Object? projectId}) {
    return _client.get(
      projectId == null
          ? '/snippets/$id'
          : '/projects/${GitLabApiClient.encodeProject(projectId)}'
                '/snippets/$id',
      decoder: _decode,
    );
  }

  /// Raw file contents. For multi-file snippets pass [filePath] to pick
  /// one file.
  Future<String> raw(int id, {Object? projectId, String? filePath}) {
    final base = projectId == null
        ? '/snippets/$id'
        : '/projects/${GitLabApiClient.encodeProject(projectId)}'
              '/snippets/$id';
    return filePath == null
        ? _client.getRaw('$base/raw')
        : _client.getRaw(
            '$base/files/main/${Uri.encodeComponent(filePath)}/raw',
          );
  }

  Future<Snippet> create({
    required String title,
    required String fileName,
    required String content,
    String? description,
    String visibility = 'private',
    Object? projectId,
  }) {
    final body = {
      'title': title,
      'file_name': fileName,
      'content': content,
      'visibility': visibility,
      'description': ?description,
    };
    return projectId == null
        ? _client.post('/snippets', body: body, decoder: _decode)
        : _client.post(
            '/projects/${GitLabApiClient.encodeProject(projectId)}/snippets',
            body: body,
            decoder: _decode,
          );
  }

  Future<Snippet> update(
    int id, {
    String? title,
    String? fileName,
    String? content,
    String? description,
    String? visibility,
    Object? projectId,
  }) {
    final body = {
      'title': ?title,
      'file_name': ?fileName,
      'content': ?content,
      'description': ?description,
      'visibility': ?visibility,
    };
    return projectId == null
        ? _client.put('/snippets/$id', body: body, decoder: _decode)
        : _client.put(
            '/projects/${GitLabApiClient.encodeProject(projectId)}'
            '/snippets/$id',
            body: body,
            decoder: _decode,
          );
  }

  Future<void> delete(int id, {Object? projectId}) {
    return _client.delete(
      projectId == null
          ? '/snippets/$id'
          : '/projects/${GitLabApiClient.encodeProject(projectId)}'
                '/snippets/$id',
    );
  }

  String _path(int id, Object? projectId, [String suffix = '']) {
    final base = projectId == null
        ? '/snippets/$id'
        : '/projects/${GitLabApiClient.encodeProject(projectId)}/snippets/$id';
    return '$base$suffix';
  }

  /// Comments on the snippet (`/notes`), oldest first.
  Future<Paginated<Note>> notes(
    int id, {
    Object? projectId,
    int page = 1,
    int perPage = 50,
  }) {
    return _client.getPage(
      _path(id, projectId, '/notes'),
      query: {'sort': 'asc', 'order_by': 'created_at'},
      page: page,
      perPage: perPage,
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Note> addNote(int id, String body, {Object? projectId}) {
    return _client.post(
      _path(id, projectId, '/notes'),
      body: {'body': body},
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<Note> updateNote(
    int id,
    int noteId,
    String body, {
    Object? projectId,
  }) {
    return _client.put(
      _path(id, projectId, '/notes/$noteId'),
      body: {'body': body},
      decoder: (j) => Note.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> deleteNote(int id, int noteId, {Object? projectId}) {
    return _client.delete(_path(id, projectId, '/notes/$noteId'));
  }

  /// Emoji reactions on the snippet or one of its notes (`/award_emoji`).
  Future<List<AwardEmoji>> awardEmojis(
    int id, {
    Object? projectId,
    int? noteId,
  }) {
    final suffix = noteId == null
        ? '/award_emoji'
        : '/notes/$noteId/award_emoji';
    return _client.getAll(
      _path(id, projectId, suffix),
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<AwardEmoji> award(
    int id,
    String name, {
    Object? projectId,
    int? noteId,
  }) {
    final suffix = noteId == null
        ? '/award_emoji'
        : '/notes/$noteId/award_emoji';
    return _client.post(
      _path(id, projectId, suffix),
      body: {'name': name},
      decoder: (j) => AwardEmoji.fromJson(j! as Map<String, dynamic>),
    );
  }

  Future<void> removeAward(
    int id,
    int awardId, {
    Object? projectId,
    int? noteId,
  }) {
    final suffix = noteId == null
        ? '/award_emoji'
        : '/notes/$noteId/award_emoji';
    return _client.delete(_path(id, projectId, '$suffix/$awardId'));
  }
}
