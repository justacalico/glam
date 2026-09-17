import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/boards/data/boards_repository.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';
import 'package:glam/src/features/milestones/application/planning_providers.dart';

final boardsRepositoryProvider = Provider<BoardsRepository>(
  (ref) => BoardsRepository(ref.watch(apiClientProvider)),
);

final boardsProvider = FutureProvider.family<List<Board>, ContainerScope>(
  (ref, scope) => ref
      .watch(boardsRepositoryProvider)
      .boards(scope.id, isProject: scope.isProject),
);

typedef BoardRef = ({ContainerScope scope, int boardId});

final boardListsProvider = FutureProvider.family<List<BoardList>, BoardRef>(
  (ref, loc) => ref
      .watch(boardsRepositoryProvider)
      .lists(loc.scope.id, loc.boardId, isProject: loc.scope.isProject),
);

typedef BoardListRef = ({ContainerScope scope, int boardId, int listId});

final boardIssuesProvider = FutureProvider.family<List<Issue>, BoardListRef>(
  (ref, loc) => ref
      .watch(boardsRepositoryProvider)
      .listIssues(
        loc.scope.id,
        loc.boardId,
        loc.listId,
        isProject: loc.scope.isProject,
        perPage: 100,
      )
      .then((p) => p.items),
);
