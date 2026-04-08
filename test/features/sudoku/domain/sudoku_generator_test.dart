import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:flutter_demo/features/sudoku/domain/sudoku_generator.dart';
import 'package:flutter_demo/features/sudoku/domain/sudoku_solver.dart';

void main() {
  final solver = const SudokuSolver();

  group('SudokuGenerator', () {
    test('creates an easy puzzle with clue count in expected range', () {
      final generator = SudokuGenerator(random: Random(3));

      final puzzle = generator.generate(SudokuDifficulty.easy);

      expect(puzzle.clueCount, inInclusiveRange(42, 50));
      expect(solver.countSolutions(puzzle.puzzle, limit: 2), 1);
    });

    test('creates a hard puzzle with clue count in expected range', () {
      final generator = SudokuGenerator(random: Random(11));

      final puzzle = generator.generate(SudokuDifficulty.hard);

      expect(puzzle.clueCount, inInclusiveRange(28, 33));
      expect(solver.countSolutions(puzzle.puzzle, limit: 2), 1);
    });
  });
}
