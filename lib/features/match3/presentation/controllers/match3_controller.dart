import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/match3_engine.dart';
import '../../domain/match3_grid.dart';
import '../../domain/match3_level_config.dart';
import 'match3_state.dart';

final match3RandomProvider = Provider<Random>((ref) => Random());

final match3EngineProvider = Provider<PadEngine>((ref) => const PadEngine());

final match3ControllerProvider = NotifierProvider<Match3Controller, PadState>(
  Match3Controller.new,
);

class Match3Controller extends Notifier<PadState> {
  late final PadEngine _engine;
  late final Random _random;
  Timer? _dragTimer;
  int _resolutionToken = 0;

  @override
  PadState build() {
    _engine = ref.watch(match3EngineProvider);
    _random = ref.watch(match3RandomProvider);
    ref.onDispose(() => _dragTimer?.cancel());

    final grid = _engine.createBoard(_random, 1);
    return PadState(
      grid: grid,
      nextId: grid.rows * grid.cols + 1,
      stageIndex: 0,
      playerHp: DungeonConfig.playerStartHp,
      monsterHp: DungeonConfig.stages.first.hp,
      phase: PadPhase.ready,
    );
  }

  void startDungeon() {
    _resolutionToken++;
    _dragTimer?.cancel();
    final grid = _engine.createBoard(_random, 1);
    state = PadState(
      grid: grid,
      nextId: grid.rows * grid.cols + 1,
      stageIndex: 0,
      playerHp: DungeonConfig.playerStartHp,
      monsterHp: DungeonConfig.stages.first.hp,
      phase: PadPhase.ready,
    );
  }

  void beginDrag(int row, int col) {
    if (!state.canDrag) return;
    state = state.copyWith(
      phase: PadPhase.dragging,
      dragOrigin: (row, col),
      dragCurrent: (row, col),
      dragTimeRemaining: DungeonConfig.dragTimeLimit,
    );
    _startDragTimer();
  }

  void moveDrag(int row, int col) {
    if (state.phase != PadPhase.dragging) return;
    final current = state.dragCurrent;
    if (current == null || (current.$1 == row && current.$2 == col)) return;
    if (row < 0 ||
        row >= state.grid.rows ||
        col < 0 ||
        col >= state.grid.cols) {
      return;
    }

    final cells = state.grid.clone().cells;
    final temp = cells[current.$1][current.$2];
    cells[current.$1][current.$2] = cells[row][col];
    cells[row][col] = temp;

    state = state.copyWith(
      grid: PadGrid(cells: cells, cols: state.grid.cols, rows: state.grid.rows),
      dragCurrent: (row, col),
    );
  }

  void endDrag() {
    if (state.phase != PadPhase.dragging) return;
    _dragTimer?.cancel();
    _finishTurn();
  }

  void nextStageOrFinish() {
    if (state.phase != PadPhase.stageCleared) return;
    _resolutionToken++;
    final nextIndex = state.stageIndex + 1;
    if (nextIndex >= DungeonConfig.stages.length) {
      state = state.copyWith(phase: PadPhase.dungeonCleared);
      return;
    }
    final grid = _engine.createBoard(_random, state.nextId);
    state = state.copyWith(
      grid: grid,
      nextId: state.nextId + grid.rows * grid.cols,
      stageIndex: nextIndex,
      monsterHp: DungeonConfig.stages[nextIndex].hp,
      phase: PadPhase.ready,
      clearDragOrigin: true,
      clearDragCurrent: true,
      clearLastTurnResult: true,
      lastDamageDealt: 0,
      lastHealingDone: 0,
      lastMonsterDamage: 0,
    );
  }

  void restartDungeon() {
    startDungeon();
  }

  void _startDragTimer() {
    _dragTimer?.cancel();
    _dragTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final remaining = state.dragTimeRemaining - 0.1;
      if (remaining <= 0) {
        timer.cancel();
        endDrag();
        return;
      }
      state = state.copyWith(dragTimeRemaining: remaining);
    });
  }

  void _finishTurn() {
    _resolutionToken++;
    final token = _resolutionToken;
    state = state.copyWith(
      phase: PadPhase.resolving,
      clearDragOrigin: true,
      clearDragCurrent: true,
    );

    final result = _engine.resolveBoard(
      grid: state.grid,
      random: _random,
      nextId: state.nextId,
    );

    if (result.comboCount == 0) {
      _applyMonsterAttack(result);
      return;
    }

    _playResolution(result, token);
  }

  Future<void> _playResolution(TurnResult result, int token) async {
    for (final cascade in result.cascades) {
      if (!_isResolutionCurrent(token)) {
        return;
      }

      state = state.copyWith(
        grid: cascade.gridAfterClear,
        phase: PadPhase.resolving,
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));

      if (!_isResolutionCurrent(token)) {
        return;
      }

      state = state.copyWith(
        grid: cascade.gridAfterFill,
        phase: PadPhase.resolving,
      );
      await Future<void>.delayed(const Duration(milliseconds: 190));
    }

    if (!_isResolutionCurrent(token)) {
      return;
    }

    final damage = _engine
        .calculateDamage(
          elementCounts: result.elementCounts,
          comboCount: result.comboCount,
          monsterElement: state.monster.element,
        )
        .round();

    final healing = _engine.calculateHealing(
      result.heartCount,
      result.comboCount,
    );

    final newMonsterHp = (state.monsterHp - damage).clamp(0, 999999);
    final newPlayerHp = (state.playerHp + healing).clamp(
      0,
      DungeonConfig.playerStartHp,
    );
    final newMaxCombo = result.comboCount > state.maxCombo
        ? result.comboCount
        : state.maxCombo;

    state = state.copyWith(
      grid: result.grid,
      nextId: result.nextId,
      monsterHp: newMonsterHp,
      playerHp: newPlayerHp,
      lastTurnResult: result,
      lastDamageDealt: damage,
      lastHealingDone: healing,
      totalDamageDealt: state.totalDamageDealt + damage,
      maxCombo: newMaxCombo,
    );

    if (newMonsterHp <= 0) {
      state = state.copyWith(phase: PadPhase.stageCleared);
      return;
    }

    _applyMonsterAttack(result);
  }

  bool _isResolutionCurrent(int token) => token == _resolutionToken;

  void _applyMonsterAttack(TurnResult result) {
    final monsterDamage = state.monster.attack;
    final hpAfterAttack = (state.playerHp - monsterDamage).clamp(0, 999999);

    state = state.copyWith(
      grid: result.grid,
      nextId: result.nextId,
      playerHp: hpAfterAttack,
      lastMonsterDamage: monsterDamage,
      phase: hpAfterAttack <= 0 ? PadPhase.dead : PadPhase.ready,
      lastTurnResult: result,
    );
  }
}
