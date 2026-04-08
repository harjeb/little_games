import 'board.dart';
import 'tile.dart';

enum SlideDirection { up, down, left, right }

class MoveResult {
  const MoveResult({
    required this.board,
    required this.scoreGained,
    required this.boardChanged,
  });

  final Board board;
  final int scoreGained;
  final bool boardChanged;
}

class MoveEngine {
  const MoveEngine();

  MoveResult slide(Board board, SlideDirection direction) {
    final movedTiles = <Tile>[];
    var scoreGained = 0;

    for (var lineIndex = 0; lineIndex < Board.size; lineIndex++) {
      final positions = _positionsForLine(direction, lineIndex);
      final lineTiles = positions
          .map((position) => board.tileAt(position.$1, position.$2))
          .whereType<Tile>()
          .toList();

      final packedTiles = <Tile>[];
      for (var index = 0; index < lineTiles.length; index++) {
        final tile = lineTiles[index];
        if (index + 1 < lineTiles.length &&
            lineTiles[index + 1].value == tile.value) {
          final mergedValue = tile.value * 2;
          packedTiles.add(tile.copyWith(value: mergedValue));
          scoreGained += mergedValue;
          index++;
        } else {
          packedTiles.add(tile);
        }
      }

      for (var index = 0; index < packedTiles.length; index++) {
        final target = positions[index];
        movedTiles.add(
          packedTiles[index].copyWith(row: target.$1, col: target.$2),
        );
      }
    }

    final updatedBoard = board.copyWith(
      tiles: movedTiles,
      score: board.score + scoreGained,
    );
    final boardChanged = _signature(board) != _signature(updatedBoard);
    final resolvedBoard = updatedBoard.copyWith(
      won: updatedBoard.maxTileValue >= 2048,
      lost: !_hasAvailableMove(updatedBoard),
    );

    return MoveResult(
      board: resolvedBoard,
      scoreGained: scoreGained,
      boardChanged: boardChanged,
    );
  }

  List<(int row, int col)> _positionsForLine(
    SlideDirection direction,
    int lineIndex,
  ) {
    return switch (direction) {
      SlideDirection.left => [
        for (var col = 0; col < Board.size; col++) (lineIndex, col),
      ],
      SlideDirection.right => [
        for (var col = Board.size - 1; col >= 0; col--) (lineIndex, col),
      ],
      SlideDirection.up => [
        for (var row = 0; row < Board.size; row++) (row, lineIndex),
      ],
      SlideDirection.down => [
        for (var row = Board.size - 1; row >= 0; row--) (row, lineIndex),
      ],
    };
  }

  bool _hasAvailableMove(Board board) {
    if (board.emptyCells.isNotEmpty) {
      return true;
    }

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

  String _signature(Board board) {
    final parts = [
      for (final tile
          in board.tiles.toList()..sort((left, right) {
            final leftKey = left.row * Board.size + left.col;
            final rightKey = right.row * Board.size + right.col;
            return leftKey.compareTo(rightKey);
          }))
        '${tile.row},${tile.col},${tile.value}',
    ];
    return parts.join('|');
  }
}
