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
    state = state.copyWith(selectedIndex: index, clearLastErrorIndex: true);
  }

  void placeDigit(int digit) {
    if (state.isComplete || state.selectedIndex == null) {
      return;
    }

    if (state.isNoteMode) {
      toggleNote(digit);
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
    nextCells[index] = cell.copyWith(value: digit, notes: const <int>{});
    _clearPeerNotes(nextCells, index, digit);
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

  void toggleNoteMode() {
    state = state.copyWith(isNoteMode: !state.isNoteMode);
  }

  void toggleNote(int digit) {
    if (state.isComplete || state.selectedIndex == null) {
      return;
    }

    final index = state.selectedIndex!;
    final cell = state.cells[index];
    if (cell.isClue || cell.value != null) {
      return;
    }

    final nextNotes = Set<int>.from(cell.notes);
    if (!nextNotes.add(digit)) {
      nextNotes.remove(digit);
    }

    final nextCells = state.cells.toList();
    nextCells[index] = cell.copyWith(notes: nextNotes);
    state = state.copyWith(cells: nextCells, clearLastErrorIndex: true);
  }

  void eraseSelected() {
    if (state.isComplete || state.selectedIndex == null) {
      return;
    }

    final index = state.selectedIndex!;
    final cell = state.cells[index];
    if (cell.isClue || (cell.value == null && cell.notes.isEmpty)) {
      return;
    }

    final nextCells = state.cells.toList();
    nextCells[index] = cell.copyWith(value: null, notes: const <int>{});
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
          notes: const <int>{},
        ),
    ];
    final firstEditable = cells.indexWhere((cell) => !cell.isClue);

    final nextState = SudokuState(
      difficulty: difficulty,
      cells: cells,
      elapsedSeconds: 0,
      mistakes: 0,
      selectedIndex: firstEditable == -1 ? null : firstEditable,
      isNoteMode: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    return nextState;
  }

  void _clearPeerNotes(List<SudokuCell> cells, int originIndex, int digit) {
    final originRow = originIndex ~/ 9;
    final originCol = originIndex % 9;
    final originBox = (originRow ~/ 3) * 3 + (originCol ~/ 3);

    for (var index = 0; index < cells.length; index++) {
      if (index == originIndex) {
        continue;
      }

      final cell = cells[index];
      if (cell.notes.isEmpty || cell.isClue || cell.value != null) {
        continue;
      }

      final row = index ~/ 9;
      final col = index % 9;
      final box = (row ~/ 3) * 3 + (col ~/ 3);
      final isPeer = row == originRow || col == originCol || box == originBox;
      if (!isPeer || !cell.notes.contains(digit)) {
        continue;
      }

      final nextNotes = Set<int>.from(cell.notes)..remove(digit);
      cells[index] = cell.copyWith(notes: nextNotes);
    }
  }
}
