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
  }) : cells = List<SudokuCell>.unmodifiable(cells);

  final SudokuDifficulty difficulty;
  final List<SudokuCell> cells;
  final int elapsedSeconds;
  final int mistakes;
  final int? selectedIndex;
  final int? lastErrorIndex;
  final bool isComplete;

  SudokuCell cellAt(int row, int col) => cells[row * 9 + col];

  SudokuState copyWith({
    SudokuDifficulty? difficulty,
    List<SudokuCell>? cells,
    int? elapsedSeconds,
    int? mistakes,
    int? selectedIndex,
    int? lastErrorIndex,
    bool? isComplete,
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
    );
  }
}
