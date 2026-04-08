class Tile {
  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  Tile copyWith({int? id, int? value, int? row, int? col}) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
}
