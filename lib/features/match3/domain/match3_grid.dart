import 'match3_piece.dart';

class Match3Grid {
  const Match3Grid({required this.cells, this.width = 8, this.height = 8});

  final List<List<Match3Piece?>> cells;
  final int width;
  final int height;

  Match3Piece? pieceAt(int row, int col) => cells[row][col];

  Match3Grid copyWith({
    List<List<Match3Piece?>>? cells,
    int? width,
    int? height,
  }) {
    return Match3Grid(
      cells: cells ?? this.cells,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Match3Grid clone() {
    return Match3Grid(
      width: width,
      height: height,
      cells: <List<Match3Piece?>>[
        for (final row in cells) <Match3Piece?>[...row],
      ],
    );
  }
}
