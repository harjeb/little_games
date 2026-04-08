import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sudoku_cell.dart';
import '../../domain/sudoku_difficulty.dart';
import '../../domain/sudoku_generator.dart';
import 'sudoku_state.dart';

final sudokuRandomProvider = Provider<Random>((ref) => Random());

final sudokuGeneratorProvider = Provider<SudokuGenerator>((ref) {
  final random = ref.watch(sudokuRandomProvider);
  return SudokuGenerator(random: random);
});

final sudokuControllerProvider =
    NotifierProvider<SudokuController, SudokuState>(SudokuController.new);

class SudokuController extends Notifier<SudokuState> {
  Timer? _timer;
  late final SudokuGenerator _generator;

  @override
  SudokuState build() {
    _generator = ref.watch(sudokuGeneratorProvider);
    ref.onDispose(() => _timer?.cancel());
    return _startPuzzle(SudokuDifficulty.easy);
  }

  void startNewGame([SudokuDifficulty? difficulty]) {
    state = _startPuzzle(difficulty ?? state.difficulty);
  }

  void selectCell(int index) {
    if (state.cells[index].isClue) {
      return;
    }
    state = state.copyWith(selectedIndex: index, clearLastErrorIndex: true);
  }

  void placeDigit(int digit) {
    if (state.isComplete || state.selectedIndex == null) {
      return;
    }

    final index = state.selectedIndex!;
    final cell = state.cells[index];
    if (cell.isClue) {
      return;
    }

    if (cell.solutionValue != digit) {
      state = state.copyWith(
        mistakes: state.mistakes + 1,
        lastErrorIndex: index,
      );
      return;
    }

    final nextCells = state.cells.toList();
    nextCells[index] = cell.copyWith(value: digit);
    final isComplete = nextCells.every(
      (nextCell) => nextCell.value == nextCell.solutionValue,
    );

    state = state.copyWith(
      cells: nextCells,
      isComplete: isComplete,
      clearLastErrorIndex: true,
    );

    if (isComplete) {
      _timer?.cancel();
    }
  }

  void eraseSelected() {
    if (state.isComplete || state.selectedIndex == null) {
      return;
    }

    final index = state.selectedIndex!;
    final cell = state.cells[index];
    if (cell.isClue || cell.value == null) {
      return;
    }

    final nextCells = state.cells.toList();
    nextCells[index] = cell.copyWith(value: null);
    state = state.copyWith(cells: nextCells, clearLastErrorIndex: true);
  }

  SudokuState _startPuzzle(SudokuDifficulty difficulty) {
    _timer?.cancel();

    final puzzle = _generator.generate(difficulty);
    final cells = <SudokuCell>[
      for (var index = 0; index < puzzle.solution.length; index++)
        SudokuCell(
          solutionValue: puzzle.solution[index],
          value: puzzle.puzzle[index] == 0 ? null : puzzle.puzzle[index],
          isClue: puzzle.puzzle[index] != 0,
        ),
    ];
    final firstEditable = cells.indexWhere((cell) => !cell.isClue);

    final nextState = SudokuState(
      difficulty: difficulty,
      cells: cells,
      elapsedSeconds: 0,
      mistakes: 0,
      selectedIndex: firstEditable == -1 ? null : firstEditable,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    return nextState;
  }
}
