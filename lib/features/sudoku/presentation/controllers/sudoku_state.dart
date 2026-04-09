import '../../domain/sudoku_cell.dart';
import '../../domain/sudoku_difficulty.dart';

class SudokuState {
  SudokuState({
    required this.difficulty,
    required List<SudokuCell> cells,
    required this.elapsedSeconds,
    required this.mistakes,
    this.selectedIndex,
    this.lastErrorIndex,
    this.isComplete = false,
    this.isNoteMode = false,
  }) : cells = List<SudokuCell>.unmodifiable(cells);

  final SudokuDifficulty difficulty;
  final List<SudokuCell> cells;
  final int elapsedSeconds;
  final int mistakes;
  final int? selectedIndex;
  final int? lastErrorIndex;
  final bool isComplete;
  final bool isNoteMode;

  SudokuCell cellAt(int row, int col) => cells[row * 9 + col];

  int rowFor(int index) => index ~/ 9;

  int colFor(int index) => index % 9;

  int boxFor(int index) => (rowFor(index) ~/ 3) * 3 + (colFor(index) ~/ 3);

  bool isRelatedToSelected(int index) {
    final selected = selectedIndex;
    if (selected == null || selected == index) {
      return false;
    }

    return rowFor(selected) == rowFor(index) ||
        colFor(selected) == colFor(index) ||
        boxFor(selected) == boxFor(index);
  }

  bool sharesValueWithSelected(int index) {
    final selected = selectedIndex;
    if (selected == null || selected == index) {
      return false;
    }

    final selectedValue = cells[selected].value;
    if (selectedValue == null) {
      return false;
    }

    return cells[index].value == selectedValue;
  }

  int remainingCountForDigit(int digit) {
    final placedCount = cells.where((cell) => cell.value == digit).length;
    return (9 - placedCount).clamp(0, 9);
  }

  SudokuState copyWith({
    SudokuDifficulty? difficulty,
    List<SudokuCell>? cells,
    int? elapsedSeconds,
    int? mistakes,
    int? selectedIndex,
    int? lastErrorIndex,
    bool? isComplete,
    bool? isNoteMode,
    bool clearSelectedIndex = false,
    bool clearLastErrorIndex = false,
  }) {
    return SudokuState(
      difficulty: difficulty ?? this.difficulty,
      cells: cells ?? this.cells,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      lastErrorIndex: clearLastErrorIndex
          ? null
          : lastErrorIndex ?? this.lastErrorIndex,
      isComplete: isComplete ?? this.isComplete,
      isNoteMode: isNoteMode ?? this.isNoteMode,
    );
  }
}
