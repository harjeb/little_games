# Match-3 Game Development Plan

## 1. Document Goal

This document defines the development plan for adding a **Match-3 (三消游戏)** as a mini game in the Pocket Playroom collection. The design draws inspiration from the Unity reference project [daltonbr/Match3](https://github.com/daltonbr/Match3), adapting its core architecture (grid management, match detection, cascading fill, special pieces, and level types) to Flutter with the existing Clay UI style and Riverpod state management.

## 2. Reference Project Analysis

### 2.1 daltonbr/Match3 Architecture Summary

The reference project is a Unity Match-3 game with the following key components:

| Component | Responsibility |
|-----------|---------------|
| `GameGrid` | Core grid (xDim × yDim), manages piece spawning, gravity fill, swap, match detection, clearing, and special piece creation |
| `GamePiece` | Base piece entity with composition-based capabilities (`MovablePiece`, `ColorPiece`, `ClearablePiece`) |
| `MovablePiece` | Handles animated piece movement via coroutine-based lerp |
| `ClearablePiece` | Handles clearing animation and destruction |
| `ColorPiece` | Holds color type for match comparison |
| `ClearLinePiece` | Special piece: clears entire row or column on activation |
| `ClearColorPiece` | Special piece (Rainbow): clears all pieces of a specific color |
| `Level` (base) | Abstract level with score tracking, win/lose conditions, HUD integration |
| `LevelMoves` | Win condition: reach target score within N moves |
| `LevelTimer` | Win condition: reach target score within time limit |
| `LevelObstacles` | Win condition: clear all obstacle pieces within N moves |

### 2.2 Key Algorithms from Reference

**Match Detection (`GetMatch`)**:
- scan horizontally from swap position, collect consecutive same-color pieces
- if horizontal count >= 3, additionally scan vertically from each horizontal match piece (L/T shape detection)
- repeat with vertical-first scan
- return combined unique match set

**Special Piece Generation**:
- 4-piece match → `RowClear` or `ColumnClear` (based on swap direction)
- 5+ piece match → `Rainbow` piece (clears all pieces of a chosen color)

**Gravity Fill (`FillStep`)**:
- iterate grid bottom-to-top; if cell below is empty, move piece down
- support diagonal fill when directly below is blocked
- top row spawns new random pieces when empty
- alternate left-right scan direction (`_inverse` flag) to avoid fill bias
- repeat until no movement occurs, then check for new cascading matches

**Obstacle System**:
- `Bubble` type pieces are non-movable, non-matchable
- cleared when an adjacent piece is matched and cleared
- level counts remaining obstacles for win condition

### 2.3 What to Adopt vs Adapt

| Reference Feature | Our Approach |
|-------------------|-------------|
| Component composition (`MovablePiece`, `ColorPiece`) | Use Dart model composition (mixins or separate classes) instead of Unity `GetComponent` |
| Coroutine-based animation | Use Flutter `AnimationController` / `ImplicitlyAnimatedWidget` |
| Unity Inspector-driven config | Use Dart constants and level config data classes |
| Multiple level types via inheritance | Use strategy pattern or sealed class for level rules |
| Mouse press/enter/release for swap | Use `GestureDetector` drag for swap direction |

## 3. Game Overview

The player swaps adjacent pieces on a grid to form lines of 3 or more matching colors. Matched pieces are cleared for points, and new pieces fall from above to fill gaps. Cascading matches earn combo bonuses. The game supports multiple level types with different win conditions.

### Core Rules

- grid size: 8×8 (configurable)
- 6 piece colors (configurable per level)
- player swaps two adjacent pieces (horizontal or vertical)
- a swap is valid only if it creates at least one match of 3+ same-color pieces
- invalid swaps are rejected (pieces snap back)
- matched pieces are cleared and scored
- gravity pulls remaining pieces down; new pieces spawn from top
- cascading matches (chain reactions) earn combo multipliers
- special pieces are created from 4+ matches
- the game ends based on level type (moves, timer, or obstacles)

## 4. Technical Scope

### Deliverables

- `match3` feature module under `lib/features/match3/`
- pure domain logic: grid model, match engine, fill engine, special piece logic, level rules
- presentation layer: game screen, animated grid, piece widgets, HUD, level select
- three level types: moves-based, timer-based, obstacle-based
- three special piece types: row-clear, column-clear, rainbow
- Clay UI styling for all components
- integration with existing leaderboard system (best score per level)
- unit tests for match detection, fill logic, scoring, and level rules
- home screen integration (new GameCard)

### Deferred Items

- level editor
- star rating persistence (1/2/3 stars)
- power-ups (shuffle, hammer)
- daily challenge levels
- sound effects and haptic feedback
- additional special pieces (bomb: clear 3×3 area)

## 5. Architecture

### Directory Structure

```text
lib/features/match3/
  domain/
    piece.dart                # Piece model (color, type, id)
    piece_type.dart           # PieceType enum (normal, empty, rowClear, columnClear, rainbow, obstacle)
    piece_color.dart          # PieceColor enum (6 colors + any)
    grid.dart                 # Grid model (2D array of pieces)
    match_engine.dart         # Match detection algorithm (pure)
    fill_engine.dart          # Gravity fill and spawn logic (pure)
    swap_engine.dart          # Swap validation and execution (pure)
    special_piece_engine.dart # Special piece creation and activation (pure)
    score_engine.dart         # Score calculation with combo multipliers
    level_config.dart         # Level configuration data class
    level_rule.dart           # Level rule interface + implementations (moves, timer, obstacles)
    match3_session.dart       # Game session state (grid, score, moves, combos, level progress)
  presentation/
    match3_screen.dart        # Main game screen
    level_select_screen.dart  # Level selection screen
    controllers/
      match3_controller.dart  # Riverpod state controller (game loop orchestration)
      level_timer_controller.dart  # Timer provider for timed levels
    widgets/
      game_board.dart         # 8×8 grid widget with gesture handling
      piece_widget.dart       # Single animated piece (color, special effects)
      hud_panel.dart          # Score, moves/time remaining, target display
      combo_popup.dart        # Combo multiplier popup animation
      level_card.dart         # Level selection card
      game_over_overlay.dart  # Win/lose overlay with star rating
```

### Integration Points

- `core/constants/game_ids.dart` — add `match3` constant
- `app/router.dart` — add `/match3` and `/match3/levels` routes
- `features/home/` — add GameCard for Match-3
- `features/leaderboard/` — reuse existing `LeaderboardRepository` (best score per level)

## 6. Domain Design

### 6.1 Core Models

```dart
enum PieceColor {
  red, blue, green, yellow, purple, orange, any;
}

enum PieceType {
  empty,       // no piece (gap)
  normal,      // standard colored piece
  rowClear,    // special: clears entire row when matched
  columnClear, // special: clears entire column when matched
  rainbow,     // special: clears all pieces of a chosen color
  obstacle,    // non-movable, non-matchable (cleared by adjacent matches)
}
```

```dart
class Piece {
  final int id;             // unique id for animation tracking
  final PieceColor color;
  final PieceType type;
  final bool isMovable;     // false for obstacles and empty
  final bool isClearable;   // false for empty
}
```

```dart
class Grid {
  final List<List<Piece?>> cells;  // [col][row], null = empty slot
  final int width;                  // default 8
  final int height;                 // default 8

  Piece? pieceAt(int col, int row);
  Grid copyWith({List<List<Piece?>>? cells});
}
```

```dart
class Match {
  final Set<(int, int)> positions;   // set of (col, row) matched
  final PieceColor color;
  final MatchShape shape;            // line3, line4, line5, lShape, tShape
}

enum MatchShape { line3, line4, line5Plus, lShape, tShape }
```

```dart
sealed class LevelRule {
  final int targetScore;
}

class MovesLevelRule extends LevelRule {
  final int maxMoves;
}

class TimerLevelRule extends LevelRule {
  final int timeLimitSeconds;
}

class ObstacleLevelRule extends LevelRule {
  final int maxMoves;
  final int totalObstacles;    // must clear all to win
}
```

```dart
class LevelConfig {
  final int id;
  final String name;
  final int gridWidth;
  final int gridHeight;
  final int colorCount;         // how many colors in play (3–6)
  final LevelRule rule;
  final List<(int, int, PieceType)> initialPieces;  // pre-placed obstacles etc.
  final int score1Star;
  final int score2Star;
  final int score3Star;
}
```

```dart
class Match3Session {
  final Grid grid;
  final int score;
  final int movesUsed;
  final int comboCurrent;       // current cascade depth (0 = no combo)
  final Duration elapsed;
  final int obstaclesRemaining;
  final LevelConfig level;
  final GameStatus status;      // playing, won, lost
  final (int, int)? selectedPiece;
}

enum GameStatus { playing, won, lost }
```

### 6.2 Match Engine (Pure)

The match engine is the heart of the game. It must be a **pure function** with no side effects.

```dart
class MatchEngine {
  /// Find all matches on the current grid.
  List<Match> findAllMatches(Grid grid);

  /// Find matches that would result from swapping two positions.
  /// Returns null if the swap produces no matches (invalid swap).
  List<Match>? findMatchesAfterSwap(Grid grid, (int,int) pos1, (int,int) pos2);

  /// Check if any valid swap exists on the board (deadlock detection).
  bool hasValidMoves(Grid grid);
}
```

**Algorithm (adapted from reference `GetMatch`):**

1. For each cell, scan right collecting consecutive same-color pieces → if count >= 3, record horizontal match
2. For each cell, scan down collecting consecutive same-color pieces → if count >= 3, record vertical match
3. For each horizontal match, check perpendicular extensions from each piece in the match → detect L/T shapes
4. For each vertical match, check perpendicular extensions similarly
5. Merge overlapping matches into combined match sets
6. Classify match shapes: 3-line, 4-line, 5+, L-shape, T-shape
7. Return deduplicated list of `Match` objects

### 6.3 Fill Engine (Pure)

Handles gravity and spawning after pieces are cleared.

```dart
class FillEngine {
  /// Apply gravity: move pieces down to fill empty gaps.
  /// Returns new grid and a list of piece movements for animation.
  FillResult applyGravity(Grid grid);

  /// Spawn new pieces in empty cells at the top of each column.
  /// Returns new grid and list of spawned pieces for animation.
  SpawnResult spawnNewPieces(Grid grid, {required int colorCount});
}

class FillResult {
  final Grid grid;
  final List<PieceMovement> movements;  // (pieceId, fromPos, toPos)
}

class SpawnResult {
  final Grid grid;
  final List<SpawnedPiece> spawned;     // (pieceId, position, color)
}
```

**Gravity algorithm (adapted from reference `FillStep`):**

1. Iterate columns left-to-right, rows bottom-to-top
2. For each empty cell, find the nearest non-empty cell above it in the same column
3. Move that piece down to fill the gap
4. If no piece exists directly above, check diagonal neighbors (alternate L/R to avoid bias)
5. Record all movements for animation
6. After gravity, fill remaining top-row empty cells with new random pieces

### 6.4 Swap Engine

```dart
class SwapEngine {
  /// Validate and execute a swap. Returns null if swap is invalid.
  SwapResult? trySwap(Grid grid, (int,int) pos1, (int,int) pos2, MatchEngine matchEngine);
}

class SwapResult {
  final Grid gridAfterSwap;
  final List<Match> matches;
  final PieceType? specialPieceToCreate;   // if 4+ match
  final (int, int)? specialPiecePosition;
}
```

**Rules:**
- positions must be adjacent (horizontal or vertical, not diagonal)
- at least one of the two pieces must be movable
- swap must produce at least one match (otherwise revert)
- rainbow piece swap: always valid, clears all pieces of the other piece's color

### 6.5 Special Piece Engine

```dart
class SpecialPieceEngine {
  /// Determine what special piece to create from a match.
  SpecialPieceResult? evaluateMatch(Match match, (int,int) swapOrigin, (int,int) swapTarget);

  /// Activate a special piece and return the set of cells to clear.
  Set<(int,int)> activateSpecialPiece(Grid grid, int col, int row);
}
```

**Special piece creation rules (from reference):**

| Match | Special Piece | Behavior |
|-------|--------------|----------|
| 4 in a row (horizontal swap) | RowClear | Clears the entire row when matched |
| 4 in a row (vertical swap) | ColumnClear | Clears the entire column when matched |
| 5+ in a row | Rainbow | Player picks a color; all pieces of that color are cleared |
| L-shape or T-shape | ColumnClear or RowClear | Based on the longer arm direction |

**Special piece activation:**
- `RowClear`: clear all cells in that row
- `ColumnClear`: clear all cells in that column
- `Rainbow`: when swapped with a colored piece, clear all pieces of that color on the board
- chain reaction: if a special piece is caught in another clear, it also activates

### 6.6 Score Engine

```dart
class ScoreEngine {
  /// Calculate score for a set of cleared pieces with combo multiplier.
  int calculateScore(List<Match> matches, int comboDepth);

  /// Calculate star rating based on level thresholds.
  int calculateStars(int score, LevelConfig level);
}
```

**Scoring formula:**
- base score per piece cleared: 10 points
- combo multiplier: `comboDepth + 1` (first match = ×1, cascade match = ×2, ×3, ...)
- special piece bonus: +50 per special piece activated
- obstacle clear bonus: +100 per obstacle cleared
- remaining moves/time bonus: awarded on level win

### 6.7 Level Rules

```dart
abstract class LevelRuleEvaluator {
  /// Check if the game should end and with what result.
  GameStatus evaluate(Match3Session session);
}

class MovesLevelEvaluator implements LevelRuleEvaluator { ... }
class TimerLevelEvaluator implements LevelRuleEvaluator { ... }
class ObstacleLevelEvaluator implements LevelRuleEvaluator { ... }
```

**Win/Lose conditions (from reference):**

| Level Type | Win | Lose |
|------------|-----|------|
| Moves | Score >= target AND moves exhausted | Moves exhausted AND score < target |
| Timer | Score >= target before time runs out | Time runs out AND score < target |
| Obstacles | All obstacles cleared within move limit | Moves exhausted AND obstacles remain |

### 6.8 Obstacle System (from reference)

- obstacles are non-movable, non-matchable pieces placed on the grid at level start
- obstacles are cleared when an adjacent piece (up/down/left/right) is matched and cleared
- some obstacles may require multiple adjacent clears to break (multi-hit, deferred for v1)

## 7. State Management

### Riverpod Providers

```text
match3ControllerProvider → StateNotifier<Match3Session>
  - startLevel(LevelConfig)
  - selectPiece(int col, int row)
  - swapPiece(int col, int row)     // swap selected with target
  - onAnimationComplete()           // continue game loop after animations
  - forfeit()                       // give up current level

levelTimerProvider → Stream<Duration>  // for timer levels

levelListProvider → List<LevelConfig>  // all available levels

bestScoreProvider(GameIds.match3) → reuse existing leaderboard
```

### Game Loop (State Machine)

The game loop is driven by a state machine within the controller:

```text
┌─────────────┐
│  IDLE        │ ← waiting for player input
└──────┬──────┘
       │ player swaps
       ▼
┌─────────────┐
│  SWAPPING    │ ← animate swap
└──────┬──────┘
       │ swap animation done
       ▼
┌─────────────┐     no match
│  MATCHING    │ ──────────────→ REVERT SWAP → IDLE
└──────┬──────┘
       │ matches found
       ▼
┌─────────────┐
│  CLEARING    │ ← animate piece clearing + spawn specials
└──────┬──────┘
       │ clear animation done
       ▼
┌─────────────┐
│  FILLING     │ ← gravity drop + spawn new pieces
└──────┬──────┘
       │ fill animation done
       ▼
┌─────────────┐     matches exist
│  CASCADE     │ ──────────────→ CLEARING (combo++)
│  CHECK       │
└──────┬──────┘
       │ no more matches
       ▼
┌─────────────┐
│  EVALUATE    │ ← check win/lose/deadlock
└──────┬──────┘
       │
       ├── game continues → IDLE
       ├── game won → GAME_OVER (win)
       ├── game lost → GAME_OVER (lose)
       └── deadlock → SHUFFLE → IDLE
```

## 8. Presentation Design

### 8.1 Game Screen Layout

```text
┌────────────────────────────────┐
│  ← Back        ⭐ 12,450      │  ← score
├────────────────────────────────┤
│  Target: 10,000   Moves: 15   │  ← HUD (varies by level type)
├────────────────────────────────┤
│                                │
│   ┌──┬──┬──┬──┬──┬──┬──┬──┐   │
│   │🔴│🔵│🟢│🟡│🔴│🟣│🔵│🟢│   │
│   ├──┼──┼──┼──┼──┼──┼──┼──┤   │
│   │🟡│🔴│🔵│🟢│🟡│🔴│🟣│🔵│   │   ← 8×8 game grid
│   ├──┼──┼──┼──┼──┼──┼──┼──┤   │
│   │  ...                   │   │
│   └──┴──┴──┴──┴──┴──┴──┴──┘   │
│                                │
│          Combo ×3!             │  ← combo popup (animated)
└────────────────────────────────┘
```

### 8.2 Piece Visual Design (Clay Style)

Each piece is a soft, rounded Clay button with inner shadow depth:

| Color | Clay Palette | Hex Reference |
|-------|-------------|---------------|
| Red | Warm coral | `AppColors.coral` |
| Blue | Lagoon | `AppColors.lagoon` |
| Green | Mint cream | `AppColors.mintCream` |
| Yellow | Butter | `AppColors.butter` |
| Purple | Soft lavender | new `AppColors.lavender` |
| Orange | Melon | `AppColors.melon` |

**Special piece visuals:**
- **RowClear**: horizontal arrow overlay + subtle horizontal glow lines
- **ColumnClear**: vertical arrow overlay + subtle vertical glow lines
- **Rainbow**: radial gradient (all colors), gentle sparkle/shimmer animation
- **Obstacle**: darker, matte, "stone-like" clay texture with crack marks

**Selected piece**: gentle floating animation (translate Y -4px) + outer glow

### 8.3 Animation Strategy

| Event | Animation | Duration |
|-------|-----------|----------|
| Piece swap | Two pieces translate to each other's positions | 200ms |
| Invalid swap revert | Swap out, pause, swap back | 200ms + 100ms + 200ms |
| Match highlight | Matched pieces scale up slightly + glow | 150ms |
| Piece clear | Scale down to 0 + fade out + particle burst | 250ms |
| Gravity drop | Pieces translate downward with ease-out bounce | 150ms per row |
| New piece spawn | Scale from 0 → 1.0 dropping from above grid edge | 200ms |
| Special piece activation (row/col) | Light beam sweeps across row/column | 300ms |
| Special piece activation (rainbow) | Color wave ripple across all matching pieces | 400ms |
| Combo popup | Scale in + float up + fade out | 600ms |
| Game over overlay | Blur background + slide in result card | 400ms |

**Staggering:**
- gravity drops are staggered by column (30ms offset) for a natural "waterfall" feel
- cascade clears use increasing delay per combo level for dramatic buildup
- use `Curves.easeOutBack` for piece drops (slight bounce on landing)

### 8.4 Swap Input

- **Option A (tap-tap)**: tap first piece to select, tap adjacent piece to swap
- **Option B (drag)**: press and drag from one piece to an adjacent piece
- **Recommended**: support both for accessibility
- drag detection: `GestureDetector` with `onPanStart` / `onPanUpdate` / `onPanEnd`
- determine swap direction by comparing drag delta (> 50% of cell size triggers swap)
- disable input during animation phases

### 8.5 HUD Design

The HUD panel sits above the grid inside a `ClayPanel`:

- **Moves level**: `Moves: 15` (countdown) + `Target: 10,000` + current score
- **Timer level**: `⏱ 1:30` (countdown) + `Target: 10,000` + current score
- **Obstacles level**: `Moves: 20` (countdown) + `Remaining: 5 🫧` + current score

Star thresholds are shown as 3 hollow/filled star icons next to the score.

## 9. Level Design

### 9.1 MVP Level Pack

Include 10 pre-designed levels for MVP:

| Level | Type | Grid | Colors | Target / Condition | Moves/Time |
|-------|------|------|--------|--------------------|------------|
| 1 | Moves | 8×8 | 4 | 1,000 pts | 20 moves |
| 2 | Moves | 8×8 | 4 | 2,000 pts | 18 moves |
| 3 | Moves | 8×8 | 5 | 3,000 pts | 20 moves |
| 4 | Timer | 8×8 | 5 | 5,000 pts | 90 sec |
| 5 | Moves | 8×8 | 5 | 5,000 pts | 25 moves |
| 6 | Obstacles | 8×8 | 5 | Clear 6 obstacles | 15 moves |
| 7 | Timer | 8×8 | 5 | 8,000 pts | 120 sec |
| 8 | Obstacles | 8×8 | 6 | Clear 10 obstacles | 20 moves |
| 9 | Moves | 8×8 | 6 | 10,000 pts | 25 moves |
| 10 | Obstacles | 8×8 | 6 | Clear 15 obstacles | 25 moves |

### 9.2 Level Config Storage

Store level configs as Dart constants in `lib/features/match3/domain/levels/`. Each level is a `LevelConfig` instance. This keeps it simple and avoids JSON parsing overhead for MVP.

Future: migrate to JSON asset files for easier level creation and potential remote delivery.

## 10. Leaderboard Integration

- game id: `GameIds.match3` (single best score across all levels)
- alternatively, per-level leaderboard: `GameIds.match3Level1`, etc. (deferred)
- score submitted: total score on level completion (only on win)
- home screen GameCard shows overall best score
- reuse existing `LeaderboardRepository.submitScore()`

## 11. Deadlock Detection and Resolution

A deadlock occurs when no valid swap exists on the board.

**Detection**: after each fill+cascade cycle, call `MatchEngine.hasValidMoves(grid)`:
- for every pair of adjacent cells, simulate a swap and check if it produces a match
- if no valid swap exists → deadlock

**Resolution**:
- shuffle all non-obstacle, non-special pieces randomly
- re-check for deadlocks after shuffle (repeat if needed)
- show a brief "Shuffling..." animation to the player

## 12. Testing Strategy

### Unit Tests (domain/)

| Test Case | Expected |
|-----------|----------|
| 3 horizontal match detection | returns match with 3 positions |
| 4 horizontal match → special piece | match shape = line4 |
| 5+ match → rainbow | match shape = line5Plus |
| L-shape detection | returns combined L positions |
| T-shape detection | returns combined T positions |
| no match after swap | swap rejected, returns null |
| gravity fill: single gap | piece moves down 1 row |
| gravity fill: multiple gaps | pieces cascade correctly |
| gravity fill: diagonal fill around obstacle | pieces route around blocker |
| new piece spawn fills top row | all top-row gaps filled |
| cascade chain: match after fill triggers new clear | combo depth increments |
| special piece activation: row clear | all cells in row are cleared |
| special piece activation: column clear | all cells in column are cleared |
| special piece activation: rainbow | all pieces of target color cleared |
| special piece chain: special caught in clear activates | chain reaction fires |
| obstacle cleared by adjacent match | obstacle removed, count decrements |
| obstacle NOT cleared by non-adjacent match | obstacle remains |
| moves level: moves exhausted, score >= target | status = won |
| moves level: moves exhausted, score < target | status = lost |
| timer level: time up, score >= target | status = won |
| timer level: time up, score < target | status = lost |
| obstacle level: all obstacles cleared | status = won |
| obstacle level: moves exhausted, obstacles remain | status = lost |
| deadlock detection: no valid moves | `hasValidMoves` returns false |
| score calculation with combo multiplier | correct combo bonus |
| star rating thresholds | correct 1/2/3 star assignment |

### Widget Tests

- grid renders correct number of cells (8×8 = 64)
- tapping piece selects it (highlight visible)
- dragging between adjacent pieces triggers swap
- HUD displays correct moves/time/score
- combo popup appears on cascade
- game-over overlay shows on win/lose with star rating
- level select screen renders level cards

### Integration Tests

- complete a full level: swap → match → clear → fill → cascade → win
- verify leaderboard score submission on level completion

## 13. Milestones

### Milestone 1: Core Domain Logic (~3 days)

- implement `Piece`, `Grid`, `PieceColor`, `PieceType` models
- implement `MatchEngine` with horizontal/vertical/L/T match detection
- implement `FillEngine` with gravity and diagonal fill
- implement `SwapEngine` with validation
- full unit test coverage for match, fill, and swap

### Milestone 2: Special Pieces and Scoring (~2 days)

- implement `SpecialPieceEngine` (creation and activation)
- implement chain reaction logic (special pieces activating each other)
- implement `ScoreEngine` with combo multipliers
- implement obstacle clearing logic
- unit tests for all special piece scenarios

### Milestone 3: Level System (~1 day)

- implement `LevelConfig` and `LevelRule` models
- implement `MovesLevelEvaluator`, `TimerLevelEvaluator`, `ObstacleLevelEvaluator`
- implement deadlock detection and shuffle
- define 10 MVP level configs
- unit tests for all level type win/lose conditions

### Milestone 4: State Controller (~1.5 days)

- implement `Match3Controller` with full game loop state machine
- wire swap → match → clear → fill → cascade → evaluate cycle
- implement timer provider for timed levels
- implement animation phase gating (input disabled during animations)
- state transition tests

### Milestone 5: Presentation - Grid and Pieces (~2.5 days)

- build `Match3Screen` with `ClayScaffold`
- build `GameBoard` widget (8×8 grid layout)
- build `PieceWidget` with color and special piece visuals
- implement swap gesture handling (tap-tap + drag)
- implement piece movement animation (swap, gravity drop)
- implement piece clearing animation (scale + fade)
- implement new piece spawn animation

### Milestone 6: Presentation - HUD and Overlays (~1.5 days)

- build `HudPanel` (score, moves/time, target, stars)
- build combo popup animation
- build game-over overlay (win/lose, star rating, score summary)
- build level select screen with level cards
- implement special piece activation visual effects

### Milestone 7: Integration and Polish (~1.5 days)

- add `GameIds.match3` constant
- add routes in `AppRouter`
- add GameCard on home screen with best score
- submit score to leaderboard on level win
- tune all animation timings and Clay styling
- Android device verification
- edge-case fixes (rapid tapping, background/foreground)

**Estimated total: ~13 days**

## 14. Development Risks

| Risk | Mitigation |
|------|------------|
| Match detection edge cases (overlapping L/T shapes) | Comprehensive test suite with 20+ grid configurations |
| Animation orchestration complexity (sequential phases) | Use state machine to gate phases; never allow concurrent conflicting animations |
| Cascade performance on low-end devices | Limit max cascade depth to 10; batch UI updates per cascade level |
| Deadlock after fill | Always check `hasValidMoves` after fill; auto-shuffle if deadlocked |
| Grid too dense for Clay style on small screens | Use compact cell size (40×40dp min); reduce inner shadow intensity on grid pieces |
| Special piece chain reactions causing infinite loops | Cap chain reaction depth; add visited-set to prevent re-activation |
| Level balance (too easy/hard) | Playtest each level 5+ times; adjust target scores and move counts |

## 15. Recommended Implementation Order

1. Implement `Piece`, `Grid`, `PieceColor`, `PieceType` models
2. Implement `MatchEngine` — horizontal/vertical scanning
3. Write match detection unit tests (basic 3-match)
4. Extend `MatchEngine` — L-shape and T-shape detection
5. Write L/T match unit tests
6. Implement `FillEngine` — gravity drop
7. Implement `FillEngine` — diagonal fill and new piece spawning
8. Write fill engine unit tests
9. Implement `SwapEngine` — swap validation
10. Implement `SpecialPieceEngine` — creation rules (4-match, 5-match)
11. Implement `SpecialPieceEngine` — activation (row, column, rainbow)
12. Implement chain reaction logic
13. Write special piece unit tests
14. Implement `ScoreEngine` with combo multipliers
15. Implement `LevelConfig`, `LevelRule`, and 3 evaluators
16. Implement deadlock detection and shuffle
17. Define 10 level configs
18. Build `Match3Controller` state machine
19. Build `GameBoard` widget and `PieceWidget`
20. Implement swap gesture handling
21. Implement movement, clearing, and spawn animations
22. Build HUD, combo popup, and game-over overlay
23. Build level select screen
24. Integrate with home screen, router, and leaderboard
25. Visual polish, animation tuning, and Android verification

## 16. Open Design Decisions

1. **Tap-tap vs drag-only swap?** — Recommended: support both, but prioritize drag as primary
2. **Grid size variation per level?** — MVP: fixed 8×8; future: allow 7×7 or 9×9
3. **Hint system?** — highlight a valid swap after 5 seconds of inactivity (adds polish, low effort)
4. **Shuffle animation style?** — pieces fly to random new positions vs fade out + fade in
5. **Per-level leaderboard or single best score?** — MVP: single overall best; future: per-level
6. **Star persistence?** — track 1/2/3 stars per level for progression unlock (deferred)
