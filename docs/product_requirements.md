# Mini Game Collection Product Requirements

## 1. Document Goal

This document defines the product requirements for a single-player mini game collection built with Flutter for Android APK delivery.

The first playable game is `Yahtzee`, based on the rules described in [docs/yahtzee_rule.md](C:\code\flutter\flutter_demo\docs\yahtzee_rule.md). The overall UI style must follow the claymorphism direction described in [UI_DESIGN.md](C:\code\flutter\flutter_demo\UI_DESIGN.md).

## 2. Product Positioning

- Product type: single-player casual mini game collection
- Primary platform: Android APK
- Release packaging target: `arm64` only
- Core value:
  - provide several short-session games inside one app
  - offer playful and tactile UI with strong visual personality
  - give each game a persistent best-score record to encourage replay

## 3. Target Users

- users who want lightweight casual games on mobile
- users who prefer short rounds and repeatable score chasing
- users who enjoy soft, toy-like, friendly visual design

## 4. Product Scope

## In Scope for MVP

- one app shell that can host multiple mini games
- a game collection home screen
- one playable game: `Yahtzee`
- per-game local best-score leaderboard capability
- local persistence for game results
- game result summary screen after each run

## Out of Scope for MVP

- online multiplayer
- cloud sync
- account system
- global internet leaderboard
- ads, IAP, social sharing
- multiple games beyond the first playable title

## 5. Global UX and Visual Requirements

The app UI must follow the claymorphism guidance from `UI_DESIGN.md`.

### Visual Principles

- use rounded, inflated, soft components instead of flat rectangles
- create a warm, playful, toy-like atmosphere
- prefer pastel or macaron color palettes with low saturation and high brightness
- use strong depth cues through soft outer shadows and subtle inner shadows
- avoid sharp corners, hard contrast, or serious dashboard-style layouts

### Interaction Principles

- interactive elements should feel pressable
- tap feedback should simulate physical compression
- transitions should feel soft and elastic, not rigid
- inputs and panels should look carved or molded into a soft surface

### UX Principles

- the home screen should immediately show available games and their best score
- each game should be playable without reading long tutorials
- scoring feedback must be explicit and easy to trust
- all important actions should be reachable with one hand on a phone

## 6. Global Functional Requirements

### 6.1 App Shell

- the app must open into a mini game collection home screen
- the home screen must show:
  - app title
  - available game cards
  - each game's current local best score
  - entry point to start each game
- games not yet implemented can be displayed as `coming soon`

### 6.2 Local Leaderboard

Each mini game must have a local score record feature.

#### MVP Requirement

- store at least the single highest valid score per game
- display the best score on the game card and in the game result area
- update the record only when the current run beats the previous best score

#### Recommended Extension

- support top 10 local records later without breaking MVP data structure
- record timestamp and game-specific metadata for future ranking pages

### 6.3 Persistence

- leaderboard data must remain available after the app is closed and reopened
- if no score exists yet, the UI must show a clear empty state such as `No record yet`

## 7. First Game: Yahtzee

## 7.1 Game Goal

The player finishes one full score sheet over 13 rounds and tries to achieve the highest total score possible.

## 7.2 Single-Player Adaptation

The original rule source describes a multiplayer game for 2 to 5 players. For this product, the first game is adapted into a single-player score attack mode.

### Confirmed Product Interpretation

- one complete run equals one player's full 13-round score sheet
- success is measured by the final total score
- leaderboard compares one run against the player's own historical best score

## 7.3 Core Game Loop

Each round must follow this sequence:

1. roll 5 dice
2. allow up to 2 rerolls
3. on each reroll, the player may choose any subset of dice to reroll
4. after rerolls are finished, the player must assign the round to exactly 1 scoring category
5. each scoring category can be used only once in a run
6. after all 13 categories are filled, the run ends and total score is calculated

## 7.4 Scoring Categories

The game uses 13 categories.

1. `Aces`: count of dice showing 1 multiplied by 1
2. `Twos`: count of dice showing 2 multiplied by 2
3. `Threes`: count of dice showing 3 multiplied by 3
4. `Fours`: count of dice showing 4 multiplied by 4
5. `Fives`: count of dice showing 5 multiplied by 5
6. `Sixes`: count of dice showing 6 multiplied by 6
7. `Three of a Kind`: sum of all 5 dice
8. `Four of a Kind`: sum of all 5 dice
9. `Full House`: 25 points
10. `Small Straight`: 30 points
11. `Large Straight`: 40 points
12. `Yahtzee`: 50 points
13. `Chance`: sum of all 5 dice

## 7.5 Bonus Rules

- upper-section bonus:
  - if the total of `Aces` through `Sixes` is at least 63, add 35 bonus points
- extra yahtzee bonus:
  - if `Yahtzee` has already been scored and the player rolls another valid yahtzee later, add 100 bonus points for each extra yahtzee

## 7.6 Rule Interpretations Needed for Implementation

The source rule text does not spell out every validation detail. The following interpretations should be treated as implementation assumptions unless later changed by product decision.

- `Three of a Kind` requires at least 3 dice with the same value
- `Four of a Kind` requires at least 4 dice with the same value
- `Full House` requires a 3-of-a-kind plus a pair
- `Small Straight` means any 4-number consecutive sequence: `1-2-3-4`, `2-3-4-5`, or `3-4-5-6`
- `Large Straight` means a 5-number consecutive sequence: `1-2-3-4-5` or `2-3-4-5-6`
- extra yahtzee bonus applies only if the player has already recorded a valid yahtzee score rather than a zero in that category

## 7.7 Main Screens for Yahtzee

### Home Card

- game title
- short game tagline
- local best score
- start button

### In-Game Screen

- round index, such as `Round 4 / 13`
- current reroll count
- 5 dice with hold or release state
- roll or reroll action button
- score sheet with all 13 categories
- available score preview for current dice result
- running subtotal, bonus, and total

### End-of-Run Result

- final total score
- best-score comparison
- whether a new record was achieved
- restart action
- return to home action

## 7.8 Functional Requirements for Yahtzee

- the player must be able to tap dice to hold or release them before reroll
- the system must prevent more than 2 rerolls per round
- the system must prevent scoring a category more than once per run
- the system must prevent ending a round without assigning a category
- the system must clearly show which categories are still available
- the total score must update immediately after category assignment
- the run must end automatically after all 13 categories are filled
- the best score must update if the final score exceeds the stored record

## 7.9 Error Prevention Requirements

- do not allow reroll when no rerolls remain
- do not allow scoring in a category that is already used
- do not allow invalid bonus application
- do not lose current run state during normal in-app navigation

## 8. Non-Functional Requirements

- target portrait mobile experience first
- interactions should remain smooth on standard Android phones
- game state calculation must be deterministic and testable
- leaderboard persistence must survive app restart
- architecture should allow future mini games to be added without rewriting the app shell

## 9. Acceptance Criteria for MVP

- the app has a home screen for the mini game collection
- `Yahtzee` is playable from start to finish in a single-player mode
- one run always contains exactly 13 scored rounds
- all score categories and bonuses are applied correctly
- a local best score is stored and displayed for `Yahtzee`
- the entire visual language follows the soft claymorphism direction

## 10. Open Decisions

- whether the product name remains `flutter_demo` or gets a game brand name
- whether best-score storage should remain single-record MVP or expand to top 10 immediately
- whether unfinished future games should be visible on the home screen from day one
