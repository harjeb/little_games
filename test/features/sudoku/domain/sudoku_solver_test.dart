import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/sudoku/domain/sudoku_generator.dart';
import 'package:flutter_demo/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:flutter_demo/features/sudoku/domain/sudoku_solver.dart';

void main() {
  const solver = SudokuSolver();

  group('SudokuSolver', () {
    test('solves a known puzzle', () {
      final puzzle = _parseGrid(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      );

      final solved = solver.solve(puzzle, random: Random(1));

      expect(solved, isNotNull);
      expect(
        solved,
        _parseGrid(
          '534678912'
          '672195348'
          '198342567'
          '859761423'
          '426853791'
          '713924856'
          '961537284'
          '287419635'
          '345286179',
        ),
      );
    });

    test('counts exactly one solution for a generated puzzle', () {
      final generator = SudokuGenerator(random: Random(7));
      final puzzle = generator.generate(SudokuDifficulty.medium);

      expect(solver.countSolutions(puzzle.puzzle, limit: 2), 1);
    });
  });
}

List<int> _parseGrid(String raw) {
  return [for (final char in raw.split('')) int.parse(char)];
}
