import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/repository/domain/repo_models.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('TreeEntry', () {
    test('parses blob/tree/commit types', () {
      final entries = (fixtureJson('tree') as List)
          .cast<Map<String, dynamic>>()
          .map(TreeEntry.fromJson)
          .toList();

      expect(entries[0].isDirectory, isTrue);
      expect(entries[1].isDirectory, isFalse);
      expect(entries[1].isSubmodule, isFalse);
      expect(entries[2].isSubmodule, isTrue);
      expect(entries[1].path, 'README.md');
    });

    test('missing fields fall back to blob defaults', () {
      final e = TreeEntry.fromJson(const {});
      expect(e.type, 'blob');
      expect(e.name, '');
    });
  });

  group('RepoFile', () {
    test('decodes base64 content', () {
      final file = RepoFile.fromJson(
        fixtureJson('repo_file') as Map<String, dynamic>,
      );
      expect(file.name, 'main.dart');
      expect(file.decodedContent, "import 'package:flutter/material.dart';\n");
      expect(file.ref, 'main');
      expect(file.size, 27);
    });

    test('returns raw content when encoding is text', () {
      const file = RepoFile(
        path: 'a.txt',
        name: 'a.txt',
        content: 'hello',
        encoding: 'text',
      );
      expect(file.decodedContent, 'hello');
    });

    test('invalid base64 falls back to raw content', () {
      const file = RepoFile(path: 'a', name: 'a', content: '!!!');
      expect(file.decodedContent, '!!!');
    });

    test('language is guessed from the extension', () {
      expect(RepoFile.languageForPath('lib/main.dart'), 'dart');
      expect(RepoFile.languageForPath('x.yml'), 'yaml');
      expect(RepoFile.languageForPath('x.unknown'), 'plaintext');
      expect(
        const RepoFile(path: 'a.py', name: 'a.py', content: '').language,
        'python',
      );
    });
  });

  group('Commit', () {
    test('parses author, dates, and parents', () {
      final c = Commit.fromJson(fixtureJson('commit') as Map<String, dynamic>);
      expect(c.shortId, '61049424');
      expect(c.authorName, 'Venkatesh Thalluri');
      expect(c.parentIds, hasLength(2));
      expect(c.committedAt, isNotNull);
    });

    test('tolerates missing fields', () {
      final c = Commit.fromJson(const {});
      expect(c.id, '');
      expect(c.parentIds, isEmpty);
    });
  });

  group('Branch', () {
    test('parses flags and head commit', () {
      final branches = (fixtureJson('branches') as List)
          .cast<Map<String, dynamic>>()
          .map(Branch.fromJson)
          .toList();

      final main = branches[0];
      expect(main.isDefault, isTrue);
      expect(main.protected, isTrue);
      expect(main.shortSha, '7b5c3cc8');
      expect(main.commitTitle, 'add projects API');
      expect(branches[1].merged, isTrue);
    });

    test('handles a missing commit object', () {
      final b = Branch.fromJson(const {'name': 'x'});
      expect(b.shortSha, '');
      expect(b.commitTitle, isNull);
    });
  });

  group('Tag', () {
    test('detects attached releases', () {
      final tags = (fixtureJson('tags') as List)
          .cast<Map<String, dynamic>>()
          .map(Tag.fromJson)
          .toList();

      expect(tags[0].hasRelease, isTrue);
      expect(tags[0].releaseTitle, '1.2.0');
      expect(tags[1].hasRelease, isFalse);
      expect(tags[1].protected_, isTrue);
    });
  });

  group('ChangeEntry', () {
    test('parses flags and diff body', () {
      final diffs = (fixtureJson('commit_diff') as List)
          .cast<Map<String, dynamic>>()
          .map(ChangeEntry.fromJson)
          .toList();

      expect(diffs[0].diff, contains('+import'));
      expect(diffs[1].newFile, isTrue);
      expect(diffs[1].tooLarge, isTrue);
    });

    test('displayPath shows renames as old → new', () {
      const renamed = ChangeEntry(
        oldPath: 'a.dart',
        newPath: 'b.dart',
        renamedFile: true,
      );
      const plain = ChangeEntry(oldPath: 'a.dart', newPath: 'a.dart');
      expect(renamed.displayPath, 'a.dart → b.dart');
      expect(plain.displayPath, 'a.dart');
    });
  });

  group('Release', () {
    test('parses author, assets, and dates', () {
      final release = Release.fromJson(
        (fixtureJson('releases') as List).first as Map<String, dynamic>,
      );
      expect(release.tagName, 'v1.2.0');
      expect(release.author?.name, 'Jane Doe');
      expect(release.assets.single.linkType, 'package');
      expect(release.assets.single.url, contains('dl.example.com'));
      expect(release.upcoming, isFalse);
    });

    test('handles empty assets and author', () {
      final r = Release.fromJson(const {'tag_name': 'v0'});
      expect(r.assets, isEmpty);
      expect(r.author, isNull);
    });
  });

  group('ReleaseLink', () {
    test('prefers direct_asset_url over url', () {
      final link = ReleaseLink.fromJson(const {
        'name': 'pkg',
        'url': 'a',
        'direct_asset_url': 'b',
      });
      expect(link.url, 'b');
    });
  });

  group('base64 edge cases', () {
    test('content with embedded newlines decodes', () {
      final encoded = base64.encode(utf8.encode('line1\nline2\n'));
      final wrapped = '${encoded.substring(0, 4)}\n${encoded.substring(4)}';
      final file = RepoFile(path: 'a', name: 'a', content: wrapped);
      expect(file.decodedContent, 'line1\nline2\n');
    });
  });
}
