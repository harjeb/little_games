# Mini Game Collection Development Plan

## 1. Document Goal

This document translates the product requirements into an executable Flutter development plan for the Android-first mini game collection.

## 2. Development Objectives

- build a reusable app shell that can host multiple mini games
- implement `Yahtzee` as the first production-ready game
- keep game rules deterministic, testable, and isolated from UI
- persist per-game best score locally
- ensure the UI implementation follows the claymorphism direction

## 3. Technical Scope

## MVP Deliverables

- app-level navigation and theme system
- home screen for the game collection
- reusable local leaderboard storage service
- full `Yahtzee` game loop
- score engine with automated tests
- end-of-game result flow

## Deferred Items

- remote sync
- player profile
- cloud leaderboard
- analytics
- in-app content delivery for future games

## 4. Proposed Architecture

Use a feature-based Flutter structure with clear separation between presentation, domain logic, and local persistence.

### Recommended Directory Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    storage/
    widgets/
    utils/
  features/
    home/
      presentation/
    leaderboard/
      data/
      domain/
    yahtzee/
      data/
      domain/
      presentation/
      widgets/
```

### Layer Responsibilities

- `presentation`: screens, widgets, animation, user input handling
- `domain`: game rules, scoring engine, state transitions, pure models
- `data`: local persistence, DTO mapping, repository implementation
- `core`: shared theme, common widgets, storage primitives, app-wide helpers

## 5. State Management Recommendation

Use `flutter_riverpod` for feature state and dependency wiring.

### Why

- easy to test domain and state separately
- scales better than ad hoc `setState` as more mini games are added
- clean injection for local storage and rule engines

### Minimum Providers

- app theme provider
- leaderboard repository provider
- yahtzee game controller provider
- yahtzee session state provider

If package count must stay minimal, `ChangeNotifier` can be used temporarily, but Riverpod is the cleaner long-term choice for a game collection app.

## 6. Local Persistence Recommendation

For MVP, use `shared_preferences` to store per-game best-score data.

### Why

- easy setup
- enough for a single highest-score record
- no complex query needs for MVP

### Suggested Storage Model

```text
leaderboard.best_score.yahtzee = {
  score: 245,
  achievedAt: "2026-04-07T12:00:00Z"
}
```

If the product later upgrades to top 10 records or richer history, migrate the leaderboard layer to Hive or Isar without changing the feature API.

## 7. UI Implementation Strategy

The UI must inherit the claymorphism requirements from `UI_DESIGN.md`.

### Theme Tokens to Define Early

- background colors
- surface colors
- accent colors
- shadow colors
- border radius scale
- spacing scale
- animation durations

### Reusable UI Components

- `ClayScaffold`
- `ClayCard`
- `ClayButton`
- `ClayDice`
- `ClayPanel`
- `ClayScoreRow`
- `ClayDialog`

### UI Notes for Yahtzee

- dice should feel soft, pressable, and slightly inflated
- selected or held dice should be visually obvious without breaking the pastel palette
- score sheet should stay readable even with a stylized look
- avoid dense table styling that fights the playful UI direction

### Dice Animation Strategy

Use a layered animation approach instead of full 3D physics.

- during roll or reroll, each affected die should animate with:
  - quick vertical lift and drop
  - small random rotation
  - short squash-and-stretch on landing
  - face value swap only near the end of the roll window
- held dice should not perform the roll animation during reroll
- the animation should use staggered timing so the 5 dice do not feel mechanically synchronized
- recommended implementation:
  - an `AnimatedDie` widget powered by an `AnimationController`
  - `TweenSequence` for translate, rotate, and scale values
  - `AnimatedSwitcher` or custom face transition for pip changes
  - duration target: `450ms` to `700ms` for a full roll cycle
- gameplay rule resolution should happen before the animation ends, but UI must reveal the new face values only when the animation reaches the result phase
- avoid heavy particle systems or true rigid-body simulation in MVP because they add complexity without improving rule clarity

## 8. Feature Design

## 8.1 Home Feature

### Responsibilities

- display app title and mood-setting hero area
- list mini game cards
- show best score for each game
- enter implemented games
- show placeholder state for future games

### Data Needed

- game id
- game title
- game status: available or coming soon
- best score summary

## 8.2 Leaderboard Feature

### Responsibilities

- read best score by game id
- write best score after a run if score is higher
- expose empty state when no record exists

### Public Interface

```text
abstract class LeaderboardRepository {
  Future<BestScoreRecord?> getBestScore(String gameId);
  Future<bool> submitScore(String gameId, int score, DateTime achievedAt);
}
```

Expected behavior:

- `submitScore` returns `true` if a new record is created
- `submitScore` returns `false` if the score does not beat the current best

## 8.3 Yahtzee Domain

### Core Models

```text
enum ScoreCategory {
  aces,
  twos,
  threes,
  fours,
  fives,
  sixes,
  threeOfAKind,
  fourOfAKind,
  fullHouse,
  smallStraight,
  largeStraight,
  yahtzee,
  chance,
}
```

```text
class ScoreEntry {
  final ScoreCategory category;
  final int? score;
}
```

```text
class DiceSet {
  final List<int> values;
  final List<bool> held;
}
```

```text
class YahtzeeSession {
  final int roundIndex;
  final int rerollsUsed;
  final DiceSet diceSet;
  final Map<ScoreCategory, int?> scoreCard;
  final int upperSectionSubtotal;
  final int upperSectionBonus;
  final int extraYahtzeeBonus;
  final int totalScore;
  final bool isFinished;
}
```

### Domain Services

- `DiceRoller`
- `ScoreCalculator`
- `CategoryAvailabilityResolver`
- `SessionProgressor`

### Domain Rules

- all scoring calculations must be pure and deterministic
- random dice generation must be isolated behind a service boundary
- UI must never directly calculate score rules

## 8.4 Yahtzee Presentation

### Main Screen Sections

- header with round and total score
- dice tray
- roll button area
- score sheet panel
- bonus summary panel

### Dice Animation Responsibilities

- animate only dice that actually change on reroll
- lock roll controls while a roll animation is in progress
- preserve tap responsiveness for hold or release outside the active animation window
- emit a clear visual distinction between `held`, `rolling`, and `settled` states

### Interaction Flow

1. start round with 5 rolled dice
2. player taps dice to hold or release
3. player rerolls unheld dice up to 2 times
4. score sheet shows available category outcomes
5. player selects one category
6. round locks, totals update, next round begins
7. after round 13, result screen opens

## 9. Testing Strategy

Testing should focus first on pure rule correctness, then state transitions, then UI smoke coverage.

### Unit Tests

- upper-section category scoring
- three-of-a-kind validation
- four-of-a-kind validation
- full house detection
- small straight detection
- large straight detection
- yahtzee detection
- upper bonus calculation
- extra yahtzee bonus calculation
- total score aggregation

### State Tests

- reroll count cannot exceed 2
- used categories cannot be selected again
- session ends after 13 scored rounds
- best score updates only when final score is higher

### Widget Tests

- home screen renders game card and best-score area
- in-game screen renders dice and score sheet
- result screen shows final score and new record state

## 10. Suggested Milestones

### Milestone 1: App Foundation

- set up app shell, routing, theme tokens, shared clay components

### Milestone 2: Leaderboard Foundation

- implement local best-score storage and home card integration

### Milestone 3: Yahtzee Domain

- implement score categories, bonus logic, round flow, and tests

### Milestone 4: Yahtzee UI

- build gameplay screen, dice interaction, score sheet, and result flow

### Milestone 5: Polish and Validation

- visual polish, edge-case fixes, widget tests, Android smoke verification

## 11. Development Risks

- claymorphism may reduce readability if score sheet density is not controlled
- ambiguous rule details can cause scoring disputes if not locked early
- mixing UI logic and game rules will make future games harder to add
- storing only one best score is simple now but should not hard-code future limitations

## 12. Recommended Implementation Order

1. define score category models and pure scoring functions
2. add automated unit tests for every category and bonus
3. build leaderboard repository and local storage adapter
4. build home screen and game entry flow
5. build gameplay state controller
6. build gameplay widgets and clay components
7. build result flow and record update behavior
8. perform visual polish and regression checks

## 13. Verification Commands for Future Development

Use these commands during implementation:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Expected signals:

- `flutter analyze` reports no issues
- `flutter test` passes all rule and widget tests
- the app opens to the collection home screen
- `Yahtzee` can complete all 13 rounds and update best score correctly
