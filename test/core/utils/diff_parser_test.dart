import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/utils/diff_parser.dart';

void main() {
  const sample = '''
@@ -10,6 +10,8 @@ class Foo {
   final int a;
+  final int b;
-  int old() => 1;
+  int newer() => 2;
   }
\\ No newline at end of file
''';

  test('parses hunks and line kinds', () {
    final hunks = DiffParser.parse(sample);
    expect(hunks, hasLength(1));
    final lines = hunks.first.lines;
    expect(lines[0].kind, DiffLineKind.context);
    expect(lines[1].kind, DiffLineKind.added);
    expect(lines[2].kind, DiffLineKind.removed);
    expect(lines[3].kind, DiffLineKind.added);
    expect(lines[4].kind, DiffLineKind.context);
    expect(lines[5].kind, DiffLineKind.meta);
  });

  test('tracks old and new line numbers', () {
    final hunks = DiffParser.parse(sample);
    final lines = hunks.first.lines;
    expect(lines[0].oldLine, 10);
    expect(lines[0].newLine, 10);
    expect(lines[1].newLine, 11);
    expect(lines[1].oldLine, isNull);
    expect(lines[2].oldLine, 11);
    expect(lines[2].newLine, isNull);
    expect(hunks.first.oldStart, 10);
    expect(hunks.first.newStart, 10);
  });

  test('empty diff parses to no hunks', () {
    expect(DiffParser.parse(''), isEmpty);
    expect(DiffParser.parse('random text\nno hunks'), isEmpty);
  });

  test('multiple hunks parse independently', () {
    const diff = '@@ -1,1 +1,1 @@\n-a\n+b\n@@ -5,1 +5,1 @@\n-c\n+d\n';
    final hunks = DiffParser.parse(diff);
    expect(hunks, hasLength(2));
    expect(hunks[1].oldStart, 5);
  });

  test('FileDiff counts additions and deletions', () {
    final diff = FileDiff(
      oldPath: 'a.dart',
      newPath: 'a.dart',
      hunks: DiffParser.parse(sample),
    );
    expect(diff.additions, 2);
    expect(diff.deletions, 1);
    expect(diff.displayPath, 'a.dart');
  });

  test('renamed files show both paths', () {
    const diff = FileDiff(
      oldPath: 'old.dart',
      newPath: 'new.dart',
      hunks: [],
      renamedFile: true,
    );
    expect(diff.displayPath, 'old.dart → new.dart');
  });
}
