import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/match3/domain/match3_engine.dart';
import 'package:flutter_demo/features/match3/domain/match3_grid.dart';
import 'package:flutter_demo/features/match3/domain/match3_level_config.dart';
import 'package:flutter_demo/features/match3/domain/match3_piece.dart';
import 'package:flutter_demo/features/match3/presentation/controllers/match3_controller.dart';

void main() {
  test('dragSwap forwards adjacent drag to the controller swap flow', () {
    final engine = _FakeMatch3Engine();
    final container = ProviderContainer(
      overrides: [
        match3EngineProvider.overrideWithValue(engine),
        match3RandomProvider.overrideWithValue(Random(0)),
      ],
    );
    addTearDown(container.dispose);

    container.read(match3ControllerProvider.notifier).dragSwap(0, 0, 0, 1);
    final state = container.read(match3ControllerProvider);

    expect(state.lastSwap, ((0, 0), (0, 1)));
    expect(state.score, 180);
    expect(state.selectedCell, isNull);
  });
}

class _FakeMatch3Engine extends Match3Engine {
  @override
  Match3SetupResult createBoard({
    required Match3LevelConfig level,
    required Random random,
    required int nextPieceId,
  }) {
    return Match3SetupResult(grid: _grid(), nextPieceId: 3);
  }

  @override
  Match3TurnResult trySwap({
    required Match3Grid grid,
    required (int row, int col) from,
    required (int row, int col) to,
    required Match3LevelConfig level,
    required Random random,
    required int nextPieceId,
  }) {
    final swapped = _grid(
      topLeft: const Match3Piece(id: 2, color: Match3PieceColor.butter),
      topRight: const Match3Piece(id: 1, color: Match3PieceColor.coral),
    );
    return Match3TurnResult.valid(
      grid: swapped,
      nextPieceId: 3,
      scoreGained: 180,
      cascades: 1,
      clearedCount: 3,
      obstaclesCleared: 0,
    );
  }

  Match3Grid _grid({Match3Piece? topLeft, Match3Piece? topRight}) {
    return Match3Grid(
      cells: List<List<Match3Piece?>>.generate(
        8,
        (row) => List<Match3Piece?>.generate(8, (col) {
          if (row == 0 && col == 0) {
            return topLeft ??
                const Match3Piece(id: 1, color: Match3PieceColor.coral);
          }
          if (row == 0 && col == 1) {
            return topRight ??
                const Match3Piece(id: 2, color: Match3PieceColor.butter);
          }
          return null;
        }),
      ),
    );
  }
}
