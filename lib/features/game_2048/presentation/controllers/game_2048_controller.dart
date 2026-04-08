import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/board.dart';
import '../../domain/move_engine.dart';
import '../../domain/spawn_service.dart';
import 'game_2048_state.dart';

final game2048RandomProvider = Provider<Random>((ref) => Random());

final game2048MoveEngineProvider = Provider<MoveEngine>((ref) {
  return const MoveEngine();
});

final game2048SpawnServiceProvider = Provider<SpawnService>((ref) {
  final random = ref.watch(game2048RandomProvider);
  return SpawnService(random);
});

final game2048ControllerProvider =
    NotifierProvider<Game2048Controller, Game2048State>(Game2048Controller.new);

class Game2048Controller extends Notifier<Game2048State> {
  late final MoveEngine _moveEngine;
  late final SpawnService _spawnService;

  @override
  Game2048State build() {
    _moveEngine = ref.watch(game2048MoveEngineProvider);
    _spawnService = ref.watch(game2048SpawnServiceProvider);
    return Game2048State(board: _newBoard());
  }

  void slide(SlideDirection direction) {
    if (state.board.lost || state.showWinOverlay) {
      return;
    }

    final result = _moveEngine.slide(state.board, direction);
    if (!result.boardChanged) {
      state = state.copyWith(board: result.board);
      return;
    }

    state = state.copyWith(board: _spawnService.spawn(result.board));
  }

  void continueAfterWin() {
    state = state.copyWith(allowPlayBeyondWin: true);
  }

  void newGame() {
    state = Game2048State(board: _newBoard());
  }

  Board _newBoard() {
    var board = Board.empty();
    board = _spawnService.spawn(board);
    board = _spawnService.spawn(board);
    return board;
  }
}
