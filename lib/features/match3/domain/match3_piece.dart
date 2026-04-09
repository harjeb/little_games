enum Match3PieceColor { coral, butter, blueberry, lagoon, grape, peach, any }

enum Match3PieceType { normal, rowClear, columnClear, rainbow, obstacle }

class Match3Piece {
  const Match3Piece({
    required this.id,
    required this.color,
    this.type = Match3PieceType.normal,
  });

  final int id;
  final Match3PieceColor color;
  final Match3PieceType type;

  bool get isMovable => type != Match3PieceType.obstacle;
  bool get isMatchable =>
      type != Match3PieceType.obstacle && type != Match3PieceType.rainbow;

  Match3Piece copyWith({
    int? id,
    Match3PieceColor? color,
    Match3PieceType? type,
  }) {
    return Match3Piece(
      id: id ?? this.id,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }
}
