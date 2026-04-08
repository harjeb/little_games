class SudokuCell {
  const SudokuCell({
    required this.solutionValue,
    required this.value,
    required this.isClue,
  });

  final int solutionValue;
  final int? value;
  final bool isClue;

  bool get isFilled => value != null;

  SudokuCell copyWith({int? solutionValue, int? value, bool? isClue}) {
    return SudokuCell(
      solutionValue: solutionValue ?? this.solutionValue,
      value: value ?? this.value,
      isClue: isClue ?? this.isClue,
    );
  }
}
