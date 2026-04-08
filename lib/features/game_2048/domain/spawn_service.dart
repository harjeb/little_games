import 'dart:math';

import 'board.dart';
import 'tile.dart';

class SpawnService {
  const SpawnService(this._random);

  final Random _random;

  Board spawn(Board board) {
    if (board.emptyCells.isEmpty) {
      return board.copyWith(lost: true);
    }

    final emptyCells = board.emptyCells;
    final target = emptyCells[_random.nextInt(emptyCells.length)];
    final nextValue = _random.nextInt(10) == 0 ? 4 : 2;
    final nextId = board.tiles.isEmpty
        ? 1
        : board.tiles
                  .map((tile) => tile.id)
                  .reduce((left, right) => left > right ? left : right) +
              1;

    final tiles = [
      ...board.tiles,
      Tile(id: nextId, value: nextValue, row: target.$1, col: target.$2),
    ];
    final nextBoard = board.copyWith(tiles: tiles);

    return nextBoard.copyWith(
      won: nextBoard.maxTileValue >= 2048,
      lost: nextBoard.emptyCells.isEmpty && !_hasAdjacentMerge(nextBoard),
    );
  }

  bool _hasAdjacentMerge(Board board) {
    for (var row = 0; row < Board.size; row++) {
      for (var col = 0; col < Board.size; col++) {
        final tile = board.tileAt(row, col);
        if (tile == null) {
          continue;
        }
        final right = col + 1 < Board.size ? board.tileAt(row, col + 1) : null;
        final down = row + 1 < Board.size ? board.tileAt(row + 1, col) : null;
        if ((right != null && right.value == tile.value) ||
            (down != null && down.value == tile.value)) {
          return true;
        }
      }
    }
    return false;
  }
}
