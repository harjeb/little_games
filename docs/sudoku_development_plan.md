# Sudoku Game Development Plan

## 1. Document Goal

This document defines the development plan for adding **Sudoku** as a mini game in the Pocket Playroom collection. The implementation reuses the existing app shell, leaderboard system, Clay UI components, and feature-based architecture.

## 2. Game Overview

Sudoku is a logic-based number-placement puzzle. The player fills a 9×9 grid so that each row, each column, and each of the nine 3×3 sub-grids (boxes) contains all digits from 1 to 9 exactly once. A valid puzzle has a unique solution. The game tracks completion time and mistake count.

### Core Rules

- grid size: 9×9, divided into nine 3×3 boxes
- some cells are pre-filled (clues); the player fills the rest
- each row must contain digits 1–9 with no repetition
- each column must contain digits 1–9 with no repetition
- each 3×3 box must contain digits 1–9 with no repetition
- a puzzle has exactly one valid solution
- the game is complete when all cells are correctly filled

### Difficulty Levels

| Level | Clues Given | Description |
|-------|-------------|-------------|
| Easy | 36–45 | Solvable with naked singles only |
| Medium | 27–35 | Requires hidden singles and basic elimination |
| Hard | 22–26 | Requires advanced techniques (pointing pairs, box-line reduction) |

## 3. Technical Scope

### Deliverables

- `sudoku` feature module under `lib/features/sudoku/`
- puzzle generator: produce valid puzzles with unique solutions at three difficulty levels
- puzzle solver: backtracking solver for validation and generation
- domain logic: board model, input validation, mistake tracking, timer
- presentation layer: game screen, 9×9 grid, number pad, timer, hints
- Clay UI styling for all components
- integration with existing leaderboard system (best time per difficulty)
- unit tests for solver, generator, and validation logic
- home screen integration (new GameCard)

### Deferred Items

- pencil marks (candidate notes) — include in v1 if time permits, otherwise defer
- daily puzzle challenge
- puzzle sharing
- statistics dashboard (win rate, average time)
- killer sudoku variant

## 4. Architecture

### Directory Structure

```text
lib/features/sudoku/
  domain/
    sudoku_board.dart         # Board model (9×9 grid, clues vs player cells)
    sudoku_cell.dart          # Cell model (value, isClue, isError, notes)
    sudoku_solver.dart        # Backtracking solver
    sudoku_generator.dart     # Puzzle generation with difficulty control
    sudoku_validator.dart     # Row/col/box constraint checker
    sudoku_game_state.dart    # Session state (timer, mistakes, completion)
  presentation/
    sudoku_screen.dart        # Main game screen
    controllers/
      sudoku_controller.dart  # Riverpod state controller
      timer_controller.dart   # Game timer provider
    widgets/
      sudoku_grid.dart        # 9×9 grid widget
      sudoku_cell_widget.dart # Single cell with Clay styling
      number_pad.dart         # 1–9 input buttons
      difficulty_picker.dart  # Difficulty selection dialog
      game_timer.dart         # Elapsed time display
      mistake_counter.dart    # Error counter display
```

### Integration Points

- `core/constants/game_ids.dart` — add `sudoku` constant (or per-difficulty: `sudokuEasy`, `sudokuMedium`, `sudokuHard`)
- `app/router.dart` — add `/sudoku` route
- `features/home/` — add GameCard for Sudoku
- `features/leaderboard/` — reuse existing `LeaderboardRepository` (best time = lowest wins)

## 5. Domain Design

### 5.1 Core Models

```dart
class SudokuCell {
  final int? value;          // 1–9 or null (empty)
  final bool isClue;         // pre-filled by generator, immutable
  final bool isError;        // conflicts with row/col/box
  final Set<int> notes;      // pencil marks (candidates)
}
```

```dart
class SudokuBoard {
  final List<List<SudokuCell>> grid;    // 9×9
  final List<List<int>> solution;       // complete solution for validation
  final Difficulty difficulty;
  final int mistakes;                   // total incorrect placements
  final Duration elapsed;               // game timer
  final bool isComplete;                // all cells correct

  int get clueCount;
  int get filledCount;
  int get remainingCount;
}
```

```dart
enum Difficulty { easy, medium, hard }
```

### 5.2 Solver

A standard backtracking solver used for two purposes:

1. **Validation** — verify that a generated puzzle has exactly one solution
2. **Hint system** — reveal the correct value for a selected cell

**Algorithm:**

1. find the first empty cell (or return solved if none)
2. try digits 1–9 in random order
3. for each candidate, check row/col/box constraints
4. if valid, place the digit and recurse
5. if recursion fails, backtrack (remove digit, try next)
6. if no digit works, return unsolvable

**Uniqueness check:** run the solver and count solutions; if count > 1, the puzzle is invalid.

### 5.3 Generator

**Algorithm outline:**

1. generate a complete valid 9×9 grid (use solver with random digit ordering)
2. create a list of all 81 cell positions, shuffled randomly
3. iterate through the list, removing one cell at a time:
   a. temporarily remove the cell's value
   b. run the solver to check uniqueness
   c. if still unique, keep it removed
   d. if not unique, restore the value
4. stop when the target clue count for the difficulty is reached or all positions have been tried
5. return the puzzle (with clues) and the complete solution

**Performance note:** the solver must be efficient. For a 9×9 grid, backtracking with constraint propagation is fast enough (< 100ms on mobile). If generation is slow, pre-generate puzzles at build time or cache a small pool.

### 5.4 Validator

Real-time conflict detection for the player's current board state.

```dart
class SudokuValidator {
  /// Returns a set of (row, col) positions that violate constraints
  Set<(int, int)> findConflicts(List<List<SudokuCell>> grid);

  /// Checks if the board is fully and correctly filled
  bool isComplete(List<List<SudokuCell>> grid, List<List<int>> solution);
}
```

- validate on every cell input, not just on submission
- highlight conflicting cells with a soft error color (avoid harsh red; use warm coral from Clay palette)

### 5.5 Mistake Tracking

- a mistake occurs when the player places a digit that does not match the solution
- mistakes are cumulative and displayed in the UI
- optional: limit mistakes to 3 (game over on 4th mistake) — configurable per difficulty
- mistake count is independent of conflict highlighting (a placement can be non-conflicting but still wrong in the final solution context — for simplicity, only count direct conflicts as mistakes in v1)

## 6. State Management

### Riverpod Providers

```text
sudokuControllerProvider → StateNotifier<SudokuBoard>
  - newGame(Difficulty)
  - placeDigit(int row, int col, int value)
  - removeDigit(int row, int col)
  - toggleNote(int row, int col, int value)
  - useHint()               // reveal one correct cell
  - selectCell(int row, int col)

selectedCellProvider → (int, int)?    // currently selected cell coordinates
timerProvider → Stream<Duration>      // game clock
isNoteModeProvider → bool             // toggle between digit and note input

bestTimeProvider(gameId) → reuse existing leaderboard (score = seconds, lower is better)
```

### State Lifecycle

1. player selects difficulty → `newGame(difficulty)` → generate puzzle, start timer
2. player taps cell → `selectCell(row, col)` → highlight cell + related row/col/box
3. player taps number pad → `placeDigit(row, col, value)` → validate, update conflicts, check completion
4. on completion → stop timer, submit time as score to leaderboard, show result overlay
5. player can start new game at any time

## 7. Presentation Design

### 7.1 Game Screen Layout

```text
┌────────────────────────────────┐
│  ← Back   ⏱ 03:42   ✕ 1/3    │  ← header: timer + mistakes
├────────────────────────────────┤
│                                │
│   ┌───┬───┬───╥───┬───┬───╥   │
│   │ 5 │   │ 3 ║   │ 7 │   ║   │
│   ├───┼───┼───╫───┼───┼───╫   │  ← 9×9 Sudoku grid
│   │   │   │   ║ 1 │ 9 │ 5 ║   │    with 3×3 box borders
│   ├───┼───┼───╫───┼───┼───╫   │
│   │   │ 9 │ 8 ║   │   │   ║   │
│   ╞═══╪═══╪═══╬═══╪═══╪═══╬   │
│   │ ...                    │   │
│   └────────────────────────┘   │
│                                │
│  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┐         │
│  │1│2│3│4│5│6│7│8│9│         │  ← number pad
│  └─┴─┴─┴─┴─┴─┴─┴─┴─┘         │
│  [ ✏ Notes ]  [ 💡 Hint ]     │  ← action buttons
│  [ ⌫ Erase ]  [ 🔄 New  ]     │
└────────────────────────────────┘
```

### 7.2 Grid Visual Design (Clay Style)

- the entire grid sits inside a `ClayPanel` with pronounced inner shadow
- each cell is a soft rounded square with subtle clay depth
- 3×3 box borders are thicker/darker than cell borders to clearly delineate boxes
- **clue cells**: slightly depressed appearance (deeper inner shadow), bolder text, non-interactive
- **player cells**: raised clay feel, lighter background, interactive
- **selected cell**: accent highlight color (mint or lagoon from palette), gentle glow
- **related cells** (same row/col/box as selected): subtle tinted background
- **conflict cells**: warm coral tint, gentle pulse animation on error placement
- **completed digit** (all 9 placed): number pad button dims or shows checkmark

### 7.3 Number Pad Design

- 9 clay-style buttons in a single row (or 3×3 grid on smaller screens)
- each button shows its digit
- remaining count badge on each button (e.g., "3" remaining for digit 7)
- tapping places the digit in the selected cell
- long-press or note-mode toggle for pencil marks
- erase button to clear the selected cell

### 7.4 Animation Strategy

| Event | Animation | Duration |
|-------|-----------|----------|
| Cell selection | scale pop (1.0 → 1.05 → 1.0) + color transition | 150ms |
| Digit placement | fade in + slight scale bounce | 200ms |
| Error highlight | gentle shake (horizontal oscillation) + coral color flash | 300ms |
| Conflict clear | smooth color transition back to default | 200ms |
| Puzzle completion | sequential cell celebration (wave of scale pops across grid) | 800ms |
| Difficulty picker | bottom sheet slide up | 300ms |

### 7.5 Timer

- starts when puzzle is generated
- pauses when app goes to background (`WidgetsBindingObserver`)
- displays as `MM:SS` format
- stops on puzzle completion
- final time is the leaderboard score (lower is better)

## 8. Leaderboard Integration

- game ids: `GameIds.sudokuEasy`, `GameIds.sudokuMedium`, `GameIds.sudokuHard`
- score submitted: elapsed seconds (integer)
- **scoring inversion**: the leaderboard currently stores "higher is better"; for Sudoku, lower time is better. Two options:
  - **Option A**: store `MAX_TIME - elapsed` so higher stored value = faster completion (simple, no leaderboard changes)
  - **Option B**: add a `SortOrder` field to leaderboard (cleaner but requires leaderboard refactor)
  - **Recommended**: Option A for MVP, migrate to Option B later
- home screen GameCard shows best time formatted as `MM:SS`

## 9. Testing Strategy

### Unit Tests (domain/)

| Test Case | Expected |
|-----------|----------|
| solver: empty grid | returns a valid complete grid |
| solver: solvable puzzle | returns correct solution |
| solver: puzzle with two solutions | uniqueness check returns false |
| generator: easy puzzle | 36–45 clues, unique solution |
| generator: hard puzzle | 22–26 clues, unique solution |
| validator: valid partial board | no conflicts |
| validator: row conflict | returns conflicting positions |
| validator: column conflict | returns conflicting positions |
| validator: box conflict | returns conflicting positions |
| validator: complete correct board | `isComplete == true` |
| place digit on clue cell | rejected, board unchanged |
| place incorrect digit | mistake count increments |
| remove digit from player cell | cell cleared, conflicts recalculated |
| timer pauses on background | elapsed freezes |

### Widget Tests

- grid renders 81 cells
- clue cells are non-interactive
- tapping cell selects it and highlights row/col/box
- number pad places digit in selected cell
- error cells show conflict styling
- completion overlay appears when puzzle is solved
- difficulty picker shows three options

### Performance Tests

- puzzle generation completes within 2 seconds on mid-range device
- solver runs within 100ms for standard puzzles
- grid rendering stays at 60fps during interaction

## 10. Milestones

### Milestone 1: Solver and Generator (~2 days)

- implement backtracking solver with constraint checking
- implement uniqueness verification
- implement puzzle generator with difficulty control
- full unit test coverage for solver and generator
- performance benchmark on target device

### Milestone 2: Board Model and Validation (~1 day)

- implement `SudokuCell`, `SudokuBoard` models
- implement real-time conflict detection (`SudokuValidator`)
- implement mistake tracking logic
- unit tests for validation

### Milestone 3: State Controller (~1 day)

- implement `SudokuController` with Riverpod
- wire all actions: new game, place digit, erase, notes, hints
- implement timer provider with background pause
- state transition tests

### Milestone 4: Presentation (~2 days)

- build `SudokuScreen` with `ClayScaffold`
- build 9×9 grid with Clay-styled cells
- implement cell selection and related-cell highlighting
- build number pad with remaining-count badges
- build difficulty picker dialog
- build timer and mistake counter display
- build completion overlay

### Milestone 5: Integration (~0.5 day)

- add `GameIds.sudoku*` constants
- add route in `AppRouter`
- add GameCard on home screen with best time display
- submit time to leaderboard on completion

### Milestone 6: Polish (~1 day)

- tune cell colors and typography for Clay style
- refine animations (placement, error, completion)
- handle edge cases (rapid input, background/foreground transitions)
- Android device verification
- accessibility check (sufficient contrast for digits)

**Estimated total: ~7.5 days**

## 11. Development Risks

| Risk | Mitigation |
|------|------------|
| Puzzle generation too slow on mobile | Pre-generate a pool of puzzles per difficulty; load from asset bundle if needed |
| 9×9 grid too dense for Clay style | Minimize cell padding, use thin inner shadows, keep border radius small (6–8px) |
| Solver correctness issues | Extensive test suite with known puzzles from published sources |
| Timer drift on background | Use `DateTime` checkpoints instead of incrementing counters |
| Leaderboard inversion (lower = better) | Use score inversion for MVP; plan leaderboard refactor as separate task |
| Touch target too small on 9×9 grid | Ensure minimum 36×36dp per cell; allow pinch-to-zoom on smaller screens if needed |

## 12. Recommended Implementation Order

1. implement backtracking solver with constraint propagation
2. write solver unit tests with known puzzles
3. implement puzzle generator with difficulty levels
4. write generator tests (clue count, uniqueness)
5. implement `SudokuCell` and `SudokuBoard` models
6. implement `SudokuValidator` with real-time conflict detection
7. write validation unit tests
8. build `SudokuController` (Riverpod StateNotifier)
9. build 9×9 grid widget with Clay styling
10. build cell selection and highlighting logic
11. build number pad and action buttons
12. build timer and mistake counter
13. build difficulty picker and completion overlay
14. integrate with home screen and leaderboard
15. visual polish and Android verification

## 13. Open Design Decisions

These items should be finalized before implementation begins:

1. **Pencil marks in v1?** — adds complexity to cell rendering and input mode toggle, but significantly improves playability for medium/hard puzzles
2. **Mistake limit?** — 3-strike game over adds tension but may frustrate casual players; consider making it optional
3. **Hint cost?** — should hints add a time penalty (e.g., +30 seconds) to discourage overuse?
4. **Per-difficulty leaderboard vs single leaderboard?** — recommended: per-difficulty for meaningful comparison
5. **Puzzle caching strategy?** — generate on-the-fly vs pre-bundled puzzle packs
