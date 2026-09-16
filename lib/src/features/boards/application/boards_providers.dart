import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/boards/data/boards_repository.dart';
import 'package:glam/src/features/boards/domain/board.dart';
import 'package:glam/src/features/issues/domain/issue.dart';

final boardsRepositoryProvider = Provider<BoardsRepository>(
  (ref) => BoardsRepository(ref.watch(apiClientProvider)),
);

final boardsProvider = FutureProvider.family<List<Board>, Object>(
  (ref, projectId) => ref.watch(boardsRepositoryProvider).boards(projectId),
);

typedef BoardRef = ({Object projectId, int boardId});

final boardListsProvider = FutureProvider.family<List<BoardList>, BoardRef>(
  (ref, loc) =>
      ref.watch(boardsRepositoryProvider).lists(loc.projectId, loc.boardId),
);

typedef BoardListRef = ({Object projectId, int boardId, int listId});

final boardIssuesProvider = FutureProvider.family<List<Issue>, BoardListRef>(
  (ref, loc) => ref
      .watch(boardsRepositoryProvider)
      .listIssues(loc.projectId, loc.boardId, loc.listId, perPage: 100)
      .then((p) => p.items),
);
