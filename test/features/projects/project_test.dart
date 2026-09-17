import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/features/projects/domain/project.dart';
import 'package:glam/src/features/projects/domain/project_filter.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('Project.fromJson', () {
    test('decodes a full project', () {
      final project = Project.fromJson(
        fixtureJson('project')! as Map<String, dynamic>,
      );

      expect(project.id, 42);
      expect(project.name, 'Glam');
      expect(project.displayName, 'Calico / Glam');
      expect(project.starCount, 128);
      expect(project.visibility, 'public');
      expect(project.namespaceKind, 'user');
      expect(project.isGroupNamespace, isFalse);
      expect(project.owner?.name, 'Calico');
      expect(project.archived, isFalse);
      expect(project.emptyRepo, isFalse);
      expect(project.lastActivityAt, isNotNull);
      expect(project.approvalsBeforeMerge, 2);
      expect(project.mergeMethod, 'rebase_merge');
      expect(project.squashOption, 'default_on');
      expect(project.onlyAllowMergeIfPipelineSucceeds, isTrue);
      expect(project.onlyAllowMergeIfAllDiscussionsAreResolved, isTrue);
      expect(project.removeSourceBranchAfterMerge, isTrue);
      expect(project.mergeCommitTemplate, contains('source_branch'));
      expect(project.sharedWithGroups.single.displayName, 'platform');
      expect(project.sharedWithGroups.single.roleLabel, 'Developer');
    });

    test('tolerates a minimal payload', () {
      final project = Project.fromJson({'id': 1});

      expect(project.id, 1);
      expect(project.name, '');
      expect(project.topics, isEmpty);
      expect(project.owner, isNull);
      expect(project.displayName, '');
    });
  });

  group('ProjectFilter.toQuery', () {
    test('membership scope', () {
      const filter = ProjectFilter(scope: ProjectScope.yours);
      expect(filter.toQuery()['membership'], true);
    });

    test('starred scope', () {
      const filter = ProjectFilter(scope: ProjectScope.starred);
      expect(filter.toQuery()['starred'], true);
    });

    test('explore scope lists public projects', () {
      const filter = ProjectFilter(scope: ProjectScope.explored);
      expect(filter.toQuery()['visibility'], 'public');
    });

    test('all scope adds nothing', () {
      const filter = ProjectFilter(scope: ProjectScope.all);
      final query = filter.toQuery();
      expect(query.containsKey('membership'), isFalse);
      expect(query.containsKey('starred'), isFalse);
      expect(query.containsKey('visibility'), isFalse);
    });

    test('search is included only when set', () {
      const withSearch = ProjectFilter(search: 'glam');
      const without = ProjectFilter();
      expect(withSearch.toQuery()['search'], 'glam');
      expect(without.toQuery().containsKey('search'), isFalse);
    });

    test('sort maps to order_by + direction', () {
      const stars = ProjectFilter(sort: ProjectSort.stars);
      expect(stars.toQuery()['order_by'], 'star_count');
      expect(stars.toQuery()['sort'], 'desc');

      const name = ProjectFilter(sort: ProjectSort.name);
      expect(name.toQuery()['order_by'], 'name');
      expect(name.toQuery()['sort'], 'asc');
    });
  });
}
