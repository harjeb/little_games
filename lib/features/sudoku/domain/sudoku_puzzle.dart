import 'sudoku_difficulty.dart';

class SudokuPuzzle {
  SudokuPuzzle({
    required this.difficulty,
    required List<int> puzzle,
    required List<int> solution,
  }) : puzzle = List<int>.unmodifiable(puzzle),
       solution = List<int>.unmodifiable(solution);

  final SudokuDifficulty difficulty;
  final List<int> puzzle;
  final List<int> solution;

  int get clueCount => puzzle.where((value) => value != 0).length;
}
