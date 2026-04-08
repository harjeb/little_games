import 'dart:math';

class SudokuSolver {
  const SudokuSolver();

  List<int>? solve(List<int> puzzle, {Random? random}) {
    final working = List<int>.from(puzzle);
    final solved = _solveRecursive(working, random: random);
    if (!solved) {
      return null;
    }
    return List<int>.unmodifiable(working);
  }

  int countSolutions(List<int> puzzle, {int limit = 2}) {
    final working = List<int>.from(puzzle);
    return _countSolutionsRecursive(working, limit);
  }

  bool isValidPlacement(List<int> grid, int index, int value) {
    final row = index ~/ 9;
    final col = index % 9;

    for (var offset = 0; offset < 9; offset++) {
      final rowIndex = row * 9 + offset;
      final colIndex = offset * 9 + col;
      if (rowIndex != index && grid[rowIndex] == value) {
        return false;
      }
      if (colIndex != index && grid[colIndex] == value) {
        return false;
      }
    }

    final boxRowStart = (row ~/ 3) * 3;
    final boxColStart = (col ~/ 3) * 3;
    for (var boxRow = boxRowStart; boxRow < boxRowStart + 3; boxRow++) {
      for (var boxCol = boxColStart; boxCol < boxColStart + 3; boxCol++) {
        final boxIndex = boxRow * 9 + boxCol;
        if (boxIndex != index && grid[boxIndex] == value) {
          return false;
        }
      }
    }

    return true;
  }

  bool _solveRecursive(List<int> grid, {Random? random}) {
    final choice = _findBestEmptyCell(grid);
    if (choice == null) {
      return true;
    }

    final index = choice.index;
    final candidates = choice.candidates.toList();
    if (random != null) {
      candidates.shuffle(random);
    }

    for (final candidate in candidates) {
      grid[index] = candidate;
      if (_solveRecursive(grid, random: random)) {
        return true;
      }
      grid[index] = 0;
    }

    return false;
  }

  int _countSolutionsRecursive(List<int> grid, int limit) {
    final choice = _findBestEmptyCell(grid);
    if (choice == null) {
      return 1;
    }

    var count = 0;
    for (final candidate in choice.candidates) {
      grid[choice.index] = candidate;
      count += _countSolutionsRecursive(grid, limit - count);
      if (count >= limit) {
        grid[choice.index] = 0;
        return count;
      }
      grid[choice.index] = 0;
    }

    return count;
  }

  _CellChoice? _findBestEmptyCell(List<int> grid) {
    _CellChoice? bestChoice;

    for (var index = 0; index < grid.length; index++) {
      if (grid[index] != 0) {
        continue;
      }

      final candidates = <int>[
        for (var value = 1; value <= 9; value++)
          if (isValidPlacement(grid, index, value)) value,
      ];

      if (candidates.isEmpty) {
        return _CellChoice(index: index, candidates: const <int>[]);
      }

      if (bestChoice == null ||
          candidates.length < bestChoice.candidates.length) {
        bestChoice = _CellChoice(index: index, candidates: candidates);
        if (candidates.length == 1) {
          return bestChoice;
        }
      }
    }

    return bestChoice;
  }
}

class _CellChoice {
  const _CellChoice({required this.index, required this.candidates});

  final int index;
  final List<int> candidates;
}
