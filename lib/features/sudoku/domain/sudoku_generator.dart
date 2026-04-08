import 'dart:math';

import 'sudoku_difficulty.dart';
import 'sudoku_puzzle.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  SudokuGenerator({
    required Random random,
    SudokuSolver solver = const SudokuSolver(),
  }) : _random = random,
       _solver = solver;

  final Random _random;
  final SudokuSolver _solver;

  SudokuPuzzle generate(SudokuDifficulty difficulty) {
    final solution = _generateSolvedGrid();
    final puzzle = _carvePuzzle(solution, difficulty);
    return SudokuPuzzle(
      difficulty: difficulty,
      puzzle: puzzle,
      solution: solution,
    );
  }

  List<int> _generateSolvedGrid() {
    final solved = _solver.solve(List<int>.filled(81, 0), random: _random);
    if (solved == null) {
      throw StateError('Failed to generate a solved Sudoku grid.');
    }
    return solved;
  }

  List<int> _carvePuzzle(List<int> solution, SudokuDifficulty difficulty) {
    final puzzle = List<int>.from(solution);
    final indices = List<int>.generate(81, (index) => index)..shuffle(_random);
    final targetClues = _targetClueCount(difficulty);

    for (final index in indices) {
      if (puzzle.where((value) => value != 0).length <= targetClues) {
        break;
      }

      final removedValue = puzzle[index];
      puzzle[index] = 0;
      final solutionCount = _solver.countSolutions(puzzle, limit: 2);
      if (solutionCount != 1) {
        puzzle[index] = removedValue;
      }
    }

    return List<int>.unmodifiable(puzzle);
  }

  int _targetClueCount(SudokuDifficulty difficulty) {
    return switch (difficulty) {
      SudokuDifficulty.easy => 42 + _random.nextInt(9),
      SudokuDifficulty.medium => 34 + _random.nextInt(8),
      SudokuDifficulty.hard => 28 + _random.nextInt(6),
    };
  }
}
