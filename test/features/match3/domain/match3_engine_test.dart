import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/match3/domain/match3_engine.dart';
import 'package:flutter_demo/features/match3/domain/match3_grid.dart';
import 'package:flutter_demo/features/match3/domain/match3_level_config.dart';
import 'package:flutter_demo/features/match3/domain/match3_piece.dart';

void main() {
  const engine = Match3Engine();

  group('Match3Engine', () {
    test('creates an initial board without immediate matches', () {
      final setup = engine.createBoard(
        level: Match3LevelConfig.defaults.first,
        random: Random(7),
        nextPieceId: 1,
      );

      expect(engine.findAllMatches(setup.grid), isEmpty);
      expect(engine.hasValidMoves(setup.grid), isTrue);
    });

    test('swapping adjacent pieces resolves a match and scores', () {
      final grid = Match3Grid(
        cells: [
          [
            _piece(1, Match3PieceColor.coral),
            _piece(2, Match3PieceColor.butter),
            _piece(3, Match3PieceColor.coral),
            _piece(4, Match3PieceColor.lagoon),
            _piece(5, Match3PieceColor.blueberry),
            _piece(6, Match3PieceColor.peach),
            _piece(7, Match3PieceColor.grape),
            _piece(8, Match3PieceColor.lagoon),
          ],
          [
            _piece(9, Match3PieceColor.butter),
            _piece(10, Match3PieceColor.coral),
            _piece(11, Match3PieceColor.butter),
            _piece(12, Match3PieceColor.lagoon),
            _piece(13, Match3PieceColor.blueberry),
            _piece(14, Match3PieceColor.peach),
            _piece(15, Match3PieceColor.grape),
            _piece(16, Match3PieceColor.lagoon),
          ],
          [
            _piece(17, Match3PieceColor.coral),
            _piece(18, Match3PieceColor.butter),
            _piece(19, Match3PieceColor.coral),
            _piece(20, Match3PieceColor.lagoon),
            _piece(21, Match3PieceColor.blueberry),
            _piece(22, Match3PieceColor.peach),
            _piece(23, Match3PieceColor.grape),
            _piece(24, Match3PieceColor.lagoon),
          ],
          [
            _piece(25, Match3PieceColor.peach),
            _piece(26, Match3PieceColor.grape),
            _piece(27, Match3PieceColor.peach),
            _piece(28, Match3PieceColor.blueberry),
            _piece(29, Match3PieceColor.lagoon),
            _piece(30, Match3PieceColor.coral),
            _piece(31, Match3PieceColor.butter),
            _piece(32, Match3PieceColor.blueberry),
          ],
          [
            _piece(33, Match3PieceColor.lagoon),
            _piece(34, Match3PieceColor.peach),
            _piece(35, Match3PieceColor.grape),
            _piece(36, Match3PieceColor.coral),
            _piece(37, Match3PieceColor.butter),
            _piece(38, Match3PieceColor.blueberry),
            _piece(39, Match3PieceColor.lagoon),
            _piece(40, Match3PieceColor.peach),
          ],
          [
            _piece(41, Match3PieceColor.blueberry),
            _piece(42, Match3PieceColor.lagoon),
            _piece(43, Match3PieceColor.peach),
            _piece(44, Match3PieceColor.butter),
            _piece(45, Match3PieceColor.coral),
            _piece(46, Match3PieceColor.grape),
            _piece(47, Match3PieceColor.peach),
            _piece(48, Match3PieceColor.coral),
          ],
          [
            _piece(49, Match3PieceColor.grape),
            _piece(50, Match3PieceColor.blueberry),
            _piece(51, Match3PieceColor.lagoon),
            _piece(52, Match3PieceColor.peach),
            _piece(53, Match3PieceColor.grape),
            _piece(54, Match3PieceColor.butter),
            _piece(55, Match3PieceColor.coral),
            _piece(56, Match3PieceColor.butter),
          ],
          [
            _piece(57, Match3PieceColor.peach),
            _piece(58, Match3PieceColor.grape),
            _piece(59, Match3PieceColor.blueberry),
            _piece(60, Match3PieceColor.lagoon),
            _piece(61, Match3PieceColor.peach),
            _piece(62, Match3PieceColor.coral),
            _piece(63, Match3PieceColor.butter),
            _piece(64, Match3PieceColor.grape),
          ],
        ],
      );

      final result = engine.trySwap(
        grid: grid,
        from: (1, 1),
        to: (1, 2),
        level: Match3LevelConfig.defaults.first,
        random: Random(3),
        nextPieceId: 65,
      );

      expect(result.boardChanged, isTrue);
      expect(result.scoreGained, greaterThan(0));
      expect(result.clearedCount, greaterThanOrEqualTo(3));
    });
  });
}

Match3Piece _piece(int id, Match3PieceColor color) {
  return Match3Piece(id: id, color: color);
}
