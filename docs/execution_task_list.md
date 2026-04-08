# Yahtzee Execution Task List

## 1. Document Goal

This document breaks the current MVP into execution-ready development tasks. Each task is designed to be reviewable, testable, and directly actionable inside the current Flutter project.

## 2. Delivery Rules

- keep patches small and reviewable
- complete domain logic before animation polish
- write tests for scoring and session flow before wiring the full UI
- do not block app-shell progress on Android SDK setup

## 3. Task List

### Task 1: Establish App Shell and Folder Structure

#### Goal

Create a scalable project structure for a multi-game collection app.

#### Deliverables

- app entry refactored out of the default counter template
- `lib/app`, `lib/core`, and `lib/features` structure created
- root app widget, router entry, and shared theme files added

#### Target Files

- `lib/main.dart`
- `lib/app/app.dart`
- `lib/app/router.dart`
- `lib/app/theme/`
- `lib/core/`
- `lib/features/`

#### Acceptance Criteria

- app starts without counter template code
- app architecture clearly supports additional games later
- no unused starter code remains

#### Verification

```powershell
flutter analyze
flutter test
```

Expected signals:

- analysis passes
- baseline tests pass after template refactor

### Task 2: Build Claymorphism Theme Foundation

#### Goal

Implement the visual system defined in `UI_DESIGN.md`.

#### Deliverables

- shared color tokens
- shared shadow recipes
- border radius and spacing scales
- reusable clay surface styles for cards, buttons, panels, and inset areas

#### Target Files

- `lib/app/theme/app_theme.dart`
- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_shadows.dart`
- `lib/core/widgets/`

#### Acceptance Criteria

- buttons and cards visibly follow a soft clay style
- surfaces use consistent radii, shadows, and palette choices
- theme tokens are reused rather than hard-coded per screen

#### Verification

```powershell
flutter analyze
flutter test
flutter run -d windows
```

Expected signals:

- app launches with non-default visual styling
- repeated components share the same visual language

### Task 3: Implement Home Screen for the Mini Game Collection

#### Goal

Create the app landing screen that lists available games and score summaries.

#### Deliverables

- collection home screen
- one active `Yahtzee` game card
- placeholder cards for future games if desired
- best-score display area on each card

#### Target Files

- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/widgets/`

#### Acceptance Criteria

- home screen opens first
- `Yahtzee` is clearly available to play
- best score is shown or empty state is shown

#### Verification

```powershell
flutter analyze
flutter test
```

Expected signals:

- widget tree renders home screen successfully
- no layout overflow on phone-sized screens

### Task 4: Implement Local Leaderboard Storage

#### Goal

Create a reusable local best-score storage layer for all games.

#### Deliverables

- leaderboard record model
- leaderboard repository interface
- `shared_preferences` implementation
- best-score query and update flow

#### Target Files

- `lib/features/leaderboard/domain/`
- `lib/features/leaderboard/data/`

#### Acceptance Criteria

- score can be read by game id
- score updates only when new score is higher
- empty-state behavior is explicit

#### Verification

```powershell
flutter analyze
flutter test
```

Expected signals:

- repository tests pass
- best-score logic behaves deterministically

### Task 5: Implement Yahtzee Domain Models and Scoring Engine

#### Goal

Build the complete pure rule engine for Yahtzee.

#### Deliverables

- score category enum
- dice models
- score calculator
- bonus calculation
- helper functions for pattern detection

#### Target Files

- `lib/features/yahtzee/domain/`
- `test/features/yahtzee/domain/`

#### Acceptance Criteria

- all 13 categories score correctly
- upper bonus is applied correctly
- extra yahtzee bonus follows the documented rule assumption
- no UI dependency exists in the scoring layer

#### Verification

```powershell
flutter test
```

Expected signals:

- unit tests cover every category and bonus case
- invalid combinations return correct zero or non-eligible results

### Task 6: Implement Yahtzee Session Controller

#### Goal

Model round progression, rerolls, dice holding, and category assignment.

#### Deliverables

- session state model
- roll and reroll commands
- hold or release die command
- category assignment command
- round completion and game completion logic

#### Target Files

- `lib/features/yahtzee/domain/`
- `lib/features/yahtzee/presentation/controllers/`
- `test/features/yahtzee/session/`

#### Acceptance Criteria

- each run contains exactly 13 scored rounds
- rerolls are capped at 2
- used categories cannot be selected again
- totals update after category assignment

#### Verification

```powershell
flutter test
```

Expected signals:

- session tests pass for normal and edge cases

### Task 7: Build Reusable Dice Widget and Animation System

#### Goal

Create the animated dice component for rolling, rerolling, and hold state.

#### Deliverables

- `ClayDie` visual widget
- `AnimatedDie` behavior wrapper
- rolling state, held state, settled state visuals
- staggered reroll animation for changed dice only

#### Target Files

- `lib/features/yahtzee/widgets/clay_die.dart`
- `lib/features/yahtzee/widgets/animated_die.dart`
- `test/features/yahtzee/widgets/`

#### Acceptance Criteria

- roll animation feels lively but readable
- held dice do not animate during reroll
- controls are locked during active roll animation
- new face values appear at the reveal phase, not at animation start

#### Verification

```powershell
flutter analyze
flutter test
flutter run -d windows
```

Expected signals:

- dice animate smoothly
- no visual jitter or state desync occurs during reroll

### Task 8: Build the Yahtzee Gameplay Screen

#### Goal

Assemble the full gameplay interface around the rule engine and dice widgets.

#### Deliverables

- gameplay screen layout
- dice tray
- reroll action area
- score sheet with current score previews
- subtotal, bonus, and total display

#### Target Files

- `lib/features/yahtzee/presentation/yahtzee_screen.dart`
- `lib/features/yahtzee/presentation/widgets/`

#### Acceptance Criteria

- full 13-round run is playable from the UI
- score previews update with current dice state
- category selection advances the session correctly

#### Verification

```powershell
flutter analyze
flutter test
flutter run -d windows
```

Expected signals:

- complete gameplay loop works from touch interactions

### Task 9: Build Result Screen and Record Update Flow

#### Goal

Show final score, compare against best score, and persist new records.

#### Deliverables

- result summary screen
- new record indicator
- replay action
- return-to-home action

#### Target Files

- `lib/features/yahtzee/presentation/yahtzee_result_screen.dart`
- `lib/features/leaderboard/`

#### Acceptance Criteria

- result screen appears after category 13 is filled
- best score updates correctly
- home screen reflects updated best score after return

#### Verification

```powershell
flutter analyze
flutter test
```

Expected signals:

- new record flow is persistent across app restart

### Task 10: Polish, Balancing, and Regression Coverage

#### Goal

Stabilize the MVP and remove obvious UX and logic defects.

#### Deliverables

- widget test coverage for key screens
- regression fixes for scoring and flow
- UI polish for spacing, animation timing, and readability

#### Target Files

- `test/`
- affected feature files

#### Acceptance Criteria

- no obvious scoring bugs remain
- no broken navigation or dead-end state remains
- score sheet remains readable on phone layout

#### Verification

```powershell
flutter analyze
flutter test
flutter run -d windows
```

Expected signals:

- smoke playthrough succeeds
- no analysis issues remain

## 4. Recommended Build Order

1. Task 1
2. Task 2
3. Task 3
4. Task 4
5. Task 5
6. Task 6
7. Task 7
8. Task 8
9. Task 9
10. Task 10

## 5. Current Clarifications Locked for MVP

- game name is `Yahtzee`
- this is a single-player score-attack adaptation
- leaderboard MVP stores local best score only
- Android is the target delivery platform, but development can proceed on Windows until Android SDK is ready
