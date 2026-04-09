import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/match3_engine.dart';
import '../../domain/match3_level_config.dart';
import 'match3_state.dart';

final match3RandomProvider = Provider<Random>((ref) => Random());

final match3EngineProvider = Provider<Match3Engine>((ref) {
  return const Match3Engine();
});

final match3ControllerProvider =
    NotifierProvider<Match3Controller, Match3State>(Match3Controller.new);

class Match3Controller extends Notifier<Match3State> {
  late final Match3Engine _engine;
  late final Random _random;
  Timer? _timer;

  @override
  Match3State build() {
    _engine = ref.watch(match3EngineProvider);
    _random = ref.watch(match3RandomProvider);
    ref.onDispose(() => _timer?.cancel());

    final setup = _engine.createBoard(
      level: Match3LevelConfig.defaults.first,
      random: _random,
      nextPieceId: 1,
    );
    final initial = Match3State(
      level: Match3LevelConfig.defaults.first,
      grid: setup.grid,
      score: 0,
      nextPieceId: setup.nextPieceId,
      status: Match3Status.playing,
      movesRemaining: Match3LevelConfig.defaults.first.movesLimit,
      timeRemainingSeconds: Match3LevelConfig.defaults.first.timeLimitSeconds,
      obstaclesRemaining: Match3LevelConfig.defaults.first.obstacles.length,
    );
    _configureTimer(initial.level, initial.timeRemainingSeconds);
    return initial;
  }

  void startLevel(Match3LevelConfig level) {
    final setup = _engine.createBoard(
      level: level,
      random: _random,
      nextPieceId: 1,
    );
    state = Match3State(
      level: level,
      grid: setup.grid,
      score: 0,
      nextPieceId: setup.nextPieceId,
      status: Match3Status.playing,
      movesRemaining: level.movesLimit,
      timeRemainingSeconds: level.timeLimitSeconds,
      obstaclesRemaining: level.obstacles.length,
      showLevelPicker: false,
    );
    _configureTimer(level, level.timeLimitSeconds);
  }

  void toggleLevelPicker() {
    state = state.copyWith(showLevelPicker: !state.showLevelPicker);
  }

  void dragSwap(int fromRow, int fromCol, int toRow, int toCol) {
    if (!state.isPlayable) {
      return;
    }

    _attemptSwap(
      from: (fromRow, fromCol),
      to: (toRow, toCol),
      clearSelectionOnFailure: true,
    );
  }

  void selectCell(int row, int col) {
    if (!state.isPlayable) {
      return;
    }

    final selected = state.selectedCell;
    if (selected == null) {
      state = state.copyWith(
        selectedCell: (row, col),
        clearLastSwap: true,
        lastCascadeCount: 0,
      );
      return;
    }

    if (selected == (row, col)) {
      state = state.copyWith(clearSelectedCell: true, clearLastSwap: true);
      return;
    }

    _attemptSwap(
      from: selected,
      to: (row, col),
      selectionOnFailure: (row, col),
    );
  }

  void restartCurrentLevel() {
    startLevel(state.level);
  }

  void _attemptSwap({
    required (int row, int col) from,
    required (int row, int col) to,
    (int row, int col)? selectionOnFailure,
    bool clearSelectionOnFailure = false,
  }) {
    if ((from.$1 - to.$1).abs() + (from.$2 - to.$2).abs() != 1) {
      state = state.copyWith(
        selectedCell: selectionOnFailure,
        clearSelectedCell: clearSelectionOnFailure,
        clearLastSwap: true,
        lastCascadeCount: 0,
        lastClearedCount: 0,
      );
      return;
    }

    final result = _engine.trySwap(
      grid: state.grid,
      from: from,
      to: to,
      level: state.level,
      random: _random,
      nextPieceId: state.nextPieceId,
    );
    if (!result.boardChanged) {
      state = state.copyWith(
        selectedCell: selectionOnFailure,
        clearSelectedCell: clearSelectionOnFailure,
        clearLastSwap: true,
        lastCascadeCount: 0,
        lastClearedCount: 0,
      );
      return;
    }

    final nextMoves = switch (state.level.ruleType) {
      Match3LevelRuleType.moves ||
      Match3LevelRuleType.obstacles => (state.movesRemaining ?? 0) - 1,
      Match3LevelRuleType.timer => state.movesRemaining,
    };

    var nextStatus = Match3Status.playing;
    final nextScore = state.score + result.scoreGained;
    final nextObstacles = (state.obstaclesRemaining - result.obstaclesCleared)
        .clamp(0, state.obstaclesRemaining)
        .toInt();

    if (nextScore >= state.level.targetScore &&
        (state.level.ruleType != Match3LevelRuleType.obstacles ||
            nextObstacles == 0)) {
      nextStatus = Match3Status.won;
    } else if ((state.level.ruleType != Match3LevelRuleType.timer &&
            (nextMoves ?? 0) <= 0) ||
        (state.level.ruleType == Match3LevelRuleType.obstacles &&
            nextObstacles > 0 &&
            (nextMoves ?? 0) <= 0)) {
      nextStatus = Match3Status.lost;
    }

    state = state.copyWith(
      grid: result.grid,
      score: nextScore,
      nextPieceId: result.nextPieceId,
      movesRemaining: nextMoves,
      obstaclesRemaining: nextObstacles,
      status: nextStatus,
      clearSelectedCell: true,
      lastSwap: (from, to),
      lastCascadeCount: result.cascades,
      lastClearedCount: result.clearedCount,
    );

    if (nextStatus != Match3Status.playing) {
      _timer?.cancel();
    }
  }

  void _configureTimer(Match3LevelConfig level, int? initialSeconds) {
    _timer?.cancel();
    if (level.ruleType != Match3LevelRuleType.timer || initialSeconds == null) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPlayable) {
        timer.cancel();
        return;
      }

      final remaining = (state.timeRemainingSeconds ?? 1) - 1;
      if (remaining <= 0) {
        state = state.copyWith(
          timeRemainingSeconds: 0,
          status: state.score >= state.level.targetScore
              ? Match3Status.won
              : Match3Status.lost,
        );
        timer.cancel();
        return;
      }

      state = state.copyWith(timeRemainingSeconds: remaining);
    });
  }
}
