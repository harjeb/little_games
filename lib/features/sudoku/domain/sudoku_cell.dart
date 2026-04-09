class SudokuCell {
  SudokuCell({
    required this.solutionValue,
    required this.value,
    required this.isClue,
    Set<int> notes = const <int>{},
  }) : notes = Set<int>.unmodifiable(notes);

  static const Object _unset = Object();

  final int solutionValue;
  final int? value;
  final bool isClue;
  final Set<int> notes;

  bool get isFilled => value != null;

  SudokuCell copyWith({
    int? solutionValue,
    Object? value = _unset,
    bool? isClue,
    Set<int>? notes,
  }) {
    return SudokuCell(
      solutionValue: solutionValue ?? this.solutionValue,
      value: identical(value, _unset) ? this.value : value as int?,
      isClue: isClue ?? this.isClue,
      notes: notes ?? this.notes,
    );
  }
}
