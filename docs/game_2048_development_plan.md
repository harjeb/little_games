# 2048 Game Development Plan

## 1. Document Goal

This document defines the development plan for adding **2048** as the second mini game in the Pocket Playroom collection. The implementation reuses the existing app shell, leaderboard system, Clay UI components, and feature-based architecture established by the Yahtzee game.

## 2. Game Overview

2048 is a single-player sliding puzzle game played on a 4×4 grid. The player swipes in four directions to slide all numbered tiles. When two tiles with the same number collide, they merge into one tile with their sum. A new tile (2 or 4) spawns after each move. The goal is to create a tile with the value 2048 (or beyond). The game ends when no valid move remains.

### Core Rules

- grid size: 4×4 (16 cells)
- initial state: 2 random tiles placed on the board (value 2 or 4, weighted 90%/10%)
- each swipe slides all tiles in the chosen direction
- identical adjacent tiles merge once per swipe (a merged tile cannot merge again in the same swipe)
- after each valid move, one new tile spawns in a random empty cell
- score increments by the value of every newly merged tile
- the game is won when any tile reaches 2048 (player may continue playing)
- the game is lost when the board is full and no adjacent tiles share a value

## 3. Technical Scope

### Deliverables

- `game_2048` feature module under `lib/features/game_2048/`
- pure domain logic: board model, move engine, spawn logic, game-over detection
- presentation layer: game screen, tile grid, swipe handling, score display, game-over dialog
- animated tile sliding and merging with Clay UI style
- integration with existing leaderboard system
- unit tests for domain logic
- home screen integration (new GameCard)

### Deferred Items

- undo move
- board size options (5×5, 6×6)
- time-attack mode
- tile themes or skins

## 4. Architecture

### Directory Structure

```text
lib/features/game_2048/
  domain/
    board.dart              # Board model (4×4 grid state)
    tile.dart               # Tile model (value, position, id)
    move_engine.dart        # Slide and merge logic (pure)
    spawn_service.dart      # New tile generation
    game_state.dart         # Game session state (score, won, lost)
  presentation/
    game_2048_screen.dart   # Main game screen
    controllers/
      game_2048_controller.dart  # Riverpod state controller
    widgets/
      tile_board.dart       # 4×4 grid widget
      tile_widget.dart      # Single animated tile
      score_header.dart     # Current score and best score display
      game_over_overlay.dart # Win/lose overlay
```

### Integration Points

- `core/constants/game_ids.dart` — add `game2048` constant
- `app/router.dart` — add `/game-2048` route
- `features/home/` — add GameCard for 2048
- `features/leaderboard/` — reuse existing `LeaderboardRepository`

## 5. Domain Design

### 5.1 Core Models

```dart
class Tile {
  final int id;          // unique id for animation tracking
  final int value;       // 2, 4, 8, 16, ...
  final int row;
  final int col;
  final bool merged;     // was this tile just merged this turn
}
```

```dart
class Board {
  final List<List<Tile?>> grid;   // 4×4 nullable grid
  final int score;
  final bool won;                  // any tile >= 2048
  final bool lost;                 // no valid moves remain

  List<Tile> get tiles;            // flat list of non-null tiles
  List<(int, int)> get emptyCells; // coordinates of empty cells
}
```

```dart
enum SlideDirection { up, down, left, right }
```

```dart
class MoveResult {
  final Board board;
  final int scoreGained;    // sum of all merges in this move
  final bool boardChanged;  // false if the swipe had no effect
}
```

### 5.2 Move Engine

The `MoveEngine` is a pure, stateless class responsible for computing the result of a single slide.

**Algorithm outline (for one row/column):**

1. extract non-null tiles in slide order
2. iterate through the extracted list; if two consecutive tiles share the same value, merge them (double the value, mark as merged)
3. compact the merged list to remove gaps
4. place tiles at their new positions
5. repeat for all 4 rows/columns
6. return `MoveResult` with updated board, score delta, and changed flag

**Critical rules:**

- a tile that was already merged in this move must not merge again
- the move is invalid (no spawn) if `boardChanged == false`

### 5.3 Spawn Service

- picks a random empty cell
- places a new tile with value 2 (90% probability) or 4 (10%)
- random source must be injectable for testing

### 5.4 Game Over Detection

- after each move + spawn, check if any valid move exists
- a valid move exists if any empty cell remains OR any two adjacent cells share the same value
- if no valid move: `lost = true`
- if any tile value >= 2048 and not previously flagged: `won = true`

## 6. State Management

### Riverpod Providers

```text
game2048ControllerProvider  → StateNotifier<Board>
  - newGame()
  - slide(SlideDirection)
  - continueAfterWin()   // allow playing beyond 2048

bestScoreProvider(GameIds.game2048) → reuse existing leaderboard provider
```

### State Lifecycle

1. `newGame()` → create empty board, spawn 2 initial tiles
2. user swipes → `slide(direction)` → compute move → if changed, spawn new tile → check game over
3. game won → show overlay, allow continue or end
4. game lost → show overlay, submit score to leaderboard

## 7. Presentation Design

### 7.1 Game Screen Layout

```text
┌──────────────────────────┐
│  ← Back    Score   Best  │  ← ClayPanel header
├──────────────────────────┤
│                          │
│    ┌──┬──┬──┬──┐         │
│    │  │  │  │  │         │  ← 4×4 tile grid
│    ├──┼──┼──┼──┤         │    wrapped in ClayPanel
│    │  │  │  │  │         │    with rounded corners
│    ├──┼──┼──┼──┤         │
│    │  │  │  │  │         │
│    ├──┼──┼──┼──┤         │
│    │  │  │  │  │         │
│    └──┴──┴──┴──┘         │
│                          │
│     [ New Game ]         │  ← ClayButton
└──────────────────────────┘
```

### 7.2 Tile Visual Design (Clay Style)

- each tile is a rounded `ClayPanel` with inner shadow for the puffy clay feel
- tile colors follow the pastel/macaron palette, scaling with value:
  - 2: cream / butter
  - 4: soft peach
  - 8: warm coral
  - 16: salmon
  - 32: tangerine
  - 64: deep orange
  - 128: pale gold
  - 256: golden
  - 512: amber
  - 1024: warm magenta
  - 2048: radiant violet
- text color switches from dark to white at value >= 8
- font size decreases slightly for 4-digit numbers

### 7.3 Animation Strategy

| Event | Animation | Duration |
|-------|-----------|----------|
| Tile slide | `AnimatedPositioned` smooth translate to new grid cell | 150ms |
| Tile merge | scale pop (1.0 → 1.2 → 1.0) after slide completes | 100ms |
| New tile spawn | scale in from 0 → 1.0 with slight bounce | 200ms |
| Game over | fade-in overlay with blur background | 300ms |

- use `AnimatedContainer` or explicit `AnimationController` per tile
- tile `id` is essential for Hero-like identity during repositioning
- all animations should feel soft and bouncy (use `Curves.easeOutBack` or spring curves)

### 7.4 Swipe Input

- use `GestureDetector` with `onPanEnd` to detect swipe direction
- determine direction by comparing horizontal vs vertical delta
- ignore swipes with very small delta (< 20px) to prevent accidental triggers
- disable input while slide animation is in progress

## 8. Leaderboard Integration

- game id: `GameIds.game2048`
- score submitted: final board score when game ends (lose) or when player chooses to end after win
- reuse `bestScoreProvider` on home screen GameCard
- reuse `LeaderboardRepository.submitScore()` on game-over

## 9. Testing Strategy

### Unit Tests (domain/)

| Test Case | Expected |
|-----------|----------|
| slide left with [2, 2, 0, 0] | result [4, 0, 0, 0], score +4 |
| slide left with [2, 2, 2, 2] | result [4, 4, 0, 0], score +8 |
| slide right with [0, 2, 0, 2] | result [0, 0, 0, 4], score +4 |
| slide with no change | `boardChanged == false` |
| double merge prevention: [4, 4, 4, 0] left | [8, 4, 0, 0] not [16, 0, 0, 0] |
| spawn places tile in empty cell | new tile in one of `emptyCells` |
| game over detection: full board, no merges | `lost == true` |
| game over detection: full board, adjacent match exists | `lost == false` |
| win detection: tile reaches 2048 | `won == true` |
| score accumulation across multiple moves | correct running total |

### Widget Tests

- game screen renders 4×4 grid
- swipe triggers board state change
- score header updates after merge
- game-over overlay appears when lost
- new game button resets board

## 10. Milestones

### Milestone 1: Domain Logic (~1 day)

- implement `Tile`, `Board`, `MoveEngine`, `SpawnService`
- implement game-over and win detection
- full unit test coverage for move engine

### Milestone 2: State Controller (~0.5 day)

- implement `Game2048Controller` with Riverpod
- wire spawn, slide, new game, and continue-after-win actions
- state transition tests

### Milestone 3: Presentation (~1.5 days)

- build `Game2048Screen` with `ClayScaffold`
- build tile grid with animated tiles
- implement swipe gesture handling
- build score header and new game button
- build game-over and win overlays

### Milestone 4: Integration (~0.5 day)

- add `GameIds.game2048` constant
- add route in `AppRouter`
- add GameCard on home screen with best score
- submit score to leaderboard on game end

### Milestone 5: Polish (~0.5 day)

- tune tile colors and typography for Clay style
- refine animation curves and timing
- edge-case fixes
- Android device verification

**Estimated total: ~4 days**

## 11. Development Risks

| Risk | Mitigation |
|------|------------|
| Tile animation jank on mid-range Android | keep animation simple (translate + scale), avoid per-frame rebuilds of full grid |
| Merge logic edge cases | comprehensive unit tests with known tricky board states |
| Swipe conflict with system gestures | add sufficient dead zone and use `HorizontalDragGestureRecognizer` priority |
| Large tile numbers overflow cell | scale font size dynamically based on digit count |

## 12. Recommended Implementation Order

1. define `Tile` and `Board` models
2. implement `MoveEngine` with pure slide/merge logic
3. write unit tests for all slide directions and merge edge cases
4. implement `SpawnService` and game-over detection
5. build `Game2048Controller` (Riverpod StateNotifier)
6. build tile grid widget with position animation
7. build game screen with swipe handling and score header
8. build game-over/win overlay
9. integrate with home screen and leaderboard
10. visual polish and Android verification
