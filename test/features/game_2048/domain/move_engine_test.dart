import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/game_2048/domain/board.dart';
import 'package:flutter_demo/features/game_2048/domain/move_engine.dart';
import 'package:flutter_demo/features/game_2048/domain/tile.dart';

void main() {
  const engine = MoveEngine();

  group('MoveEngine', () {
    test('slides left and merges once per pair', () {
      final board = _boardFromRows([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final result = engine.slide(board, SlideDirection.left);

      expect(_rowsFromBoard(result.board), [
        [4, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(result.scoreGained, 4);
      expect(result.boardChanged, isTrue);
    });

    test('prevents double merge in a single move', () {
      final board = _boardFromRows([
        [4, 4, 4, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final result = engine.slide(board, SlideDirection.left);

      expect(_rowsFromBoard(result.board), [
        [8, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(result.scoreGained, 8);
    });

    test('detects a no-op move', () {
      final board = _boardFromRows([
        [2, 4, 8, 16],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final result = engine.slide(board, SlideDirection.left);

      expect(result.boardChanged, isFalse);
      expect(result.scoreGained, 0);
    });

    test('marks the board as lost when no moves remain', () {
      final board = _boardFromRows([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);

      final result = engine.slide(board, SlideDirection.left);

      expect(result.board.lost, isTrue);
      expect(result.boardChanged, isFalse);
    });
  });
}

Board _boardFromRows(List<List<int>> rows) {
  var nextId = 1;
  final tiles = <Tile>[];
  for (var row = 0; row < rows.length; row++) {
    for (var col = 0; col < rows[row].length; col++) {
      final value = rows[row][col];
      if (value == 0) {
        continue;
      }
      tiles.add(Tile(id: nextId++, value: value, row: row, col: col));
    }
  }
  return Board(tiles: tiles);
}

List<List<int>> _rowsFromBoard(Board board) {
  return [
    for (var row = 0; row < Board.size; row++)
      [
        for (var col = 0; col < Board.size; col++)
          board.tileAt(row, col)?.value ?? 0,
      ],
  ];
}
