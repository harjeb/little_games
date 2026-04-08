import 'tile.dart';

class Board {
  Board({
    required List<Tile> tiles,
    this.score = 0,
    this.won = false,
    this.lost = false,
  }) : tiles = List<Tile>.unmodifiable(tiles);

  factory Board.empty() => Board(tiles: const <Tile>[]);

  final List<Tile> tiles;
  final int score;
  final bool won;
  final bool lost;

  static const int size = 4;

  List<(int row, int col)> get emptyCells {
    final occupied = <(int, int)>{
      for (final tile in tiles) (tile.row, tile.col),
    };
    final positions = <(int row, int col)>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (!occupied.contains((row, col))) {
          positions.add((row, col));
        }
      }
    }
    return positions;
  }

  int get maxTileValue => tiles.isEmpty
      ? 0
      : tiles
            .map((tile) => tile.value)
            .reduce((left, right) => left > right ? left : right);

  Tile? tileAt(int row, int col) {
    for (final tile in tiles) {
      if (tile.row == row && tile.col == col) {
        return tile;
      }
    }
    return null;
  }

  Board copyWith({List<Tile>? tiles, int? score, bool? won, bool? lost}) {
    return Board(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      won: won ?? this.won,
      lost: lost ?? this.lost,
    );
  }
}
