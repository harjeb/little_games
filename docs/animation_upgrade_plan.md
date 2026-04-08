# Animation Upgrade Plan

## 1. Document Goal

This document defines the animation upgrade plan for the Pocket Playroom app. It addresses the following issues identified in the current implementation:

1. **Yahtzee dice lack 3D rolling animation** — dice currently only do 2D lift/rotate/scale, no face-flip or tumble effect
2. **2048 tiles lack sliding animation** — numbers appear/disappear without visible movement between cells
3. **2048 tiles lack drag-following / touch-sticky behavior** — no visual feedback that a tile "sticks" to the user's finger
4. **General animation polish** — transitions feel flat and mechanical

## 2. Current Animation Audit

### 2.1 Yahtzee Dice — Current State

**File**: `lib/features/yahtzee/presentation/widgets/animated_die.dart`

Current animation during a roll (620ms):
- **Lift**: translate Y upward ~18px, then drop back
- **Rotate**: small 2D rotation (±10–20° sine wave)
- **Scale**: subtle inflate 1.0 → 1.03 → 1.0
- **Face swap**: at 72% progress, swap to new pip value

**Problems**:
- 2D only — dice feel like flat cards wobbling, not 3D objects rolling
- no tumble/flip — the viewer never sees a different face during the roll
- no squash-and-stretch on landing — missing the "clay bounce" feeling
- all 5 dice use very similar motion curves, feels mechanical

### 2.2 2048 — Current State

If the 2048 game exists, tiles likely use simple state swaps without `AnimatedPositioned` or `SlideTransition`. Issues:
- tiles teleport to new cells instead of sliding
- no merge pop animation
- no new-tile scale-in animation
- no visual response to swipe gesture (no tile drag-follow)

## 3. Yahtzee 3D Dice Upgrade

### 3.1 Approach: Pseudo-3D with Matrix4 Perspective

Flutter does not have a built-in 3D engine, but `Matrix4` transformations with perspective entry provide convincing pseudo-3D rotation. This is sufficient for a dice roll — we do **not** need a full 3D model renderer.

**Key technique:**
```dart
Transform(
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001)    // perspective
    ..rotateX(angleX)          // tumble forward/backward
    ..rotateY(angleY)          // tumble left/right
    ..rotateZ(angleZ),         // twist
  alignment: Alignment.center,
  child: currentFaceWidget,
)
```

### 3.2 Dice Cube Widget Design

Create a new `ClayCube3D` widget that renders a pseudo-3D cube with 6 faces:

```text
┌───────────┐
│   Face 1   │  ← pip layout for value 1
│  (front)   │
└───────────┘
  Each face is a ClayDie with the corresponding pip count
  Visible face determined by rotation angles
```

**Architecture:**

```dart
class ClayCube3D extends StatelessWidget {
  final int value;          // 1–6, determines which face is "front"
  final double rotateX;     // radians
  final double rotateY;     // radians
  final double rotateZ;     // radians
  final bool held;

  // Renders a Stack of 6 face widgets with Matrix4 transforms
  // Only the visible face (and partially visible adjacent faces) are painted
}
```

**Face mapping** (standard dice convention):
- Front (rotateX=0, rotateY=0): shows `value`
- Opposite faces sum to 7 (1↔6, 2↔5, 3↔4)
- Rotation determines which face is visible

**Optimization — simplified 2-face rendering:**

For performance, we do not need all 6 faces rendered simultaneously. During a roll:
1. Determine which two faces are visible at the current rotation angle
2. Render only those two faces with appropriate transforms
3. Cross-fade between faces near the flip threshold

### 3.3 Roll Animation Sequence

```text
Phase 1: LAUNCH (0–15%)
├── Scale: 1.0 → 0.92 (squash before jump)
├── TranslateY: 0 → -6px
└── Shadow: floating → pressed (shadow shrinks)

Phase 2: TUMBLE (15–75%)
├── TranslateY: -6px → -30px → -10px (arc trajectory)
├── RotateX: 0 → random(1.5π – 3π) (forward tumble, 1–2 full rotations)
├── RotateY: 0 → random(±0.5π – ±π) (slight side tumble)
├── RotateZ: random twist (±15°)
├── Face values: cycle through random intermediate faces, land on final value
└── Shadow: offset follows translateY (grows when die is higher)

Phase 3: LAND (75–90%)
├── TranslateY: → 0 (drop)
├── Scale: → 1.08 (stretch on impact)
├── RotateX/Y: snap to final face-aligned angle
└── Shadow: → full floating shadow

Phase 4: SETTLE (90–100%)
├── Scale: 1.08 → 0.97 → 1.0 (bounce dampening)
├── TranslateY: 0 → 3px → 0 (micro-bounce)
└── RotateZ: small dampened oscillation → 0
```

**Duration:** 700ms total (staggered per die: +50ms offset for each die index)

**Curves:**
- Launch: `Curves.easeInQuad`
- Tumble: `Curves.linear` (constant rotation speed)
- Land: `Curves.bounceOut`
- Settle: `Curves.elasticOut`

### 3.4 Staggered Timing

Each of the 5 dice uses a different timing offset and rotation amount:

```dart
final delay = index * 50;           // 0, 50, 100, 150, 200ms
final rotations = 1.5 + random.nextDouble() * 1.5;  // 1.5–3 full rotations
final tiltY = (random.nextDouble() - 0.5) * pi;     // random side tilt
```

This prevents the mechanical "all dice move identically" feel.

### 3.5 Held Dice Behavior

- held dice do NOT animate during a roll
- held dice have a subtle "pinned" idle animation: very slow breathe (scale 1.0 → 1.01, 2s loop)
- when toggling hold: quick scale pop (1.0 → 1.1 → 1.0, 200ms) + pin icon appear

### 3.6 Implementation Plan

#### New files:
- `lib/features/yahtzee/presentation/widgets/clay_cube_3d.dart` — 3D cube widget
- `lib/features/yahtzee/presentation/widgets/dice_roll_animator.dart` — roll animation orchestrator

#### Modified files:
- `lib/features/yahtzee/presentation/widgets/animated_die.dart` — replace 2D transform with `ClayCube3D`
- `lib/features/yahtzee/presentation/widgets/clay_die.dart` — refactor as single-face widget used by cube

#### No external packages needed

The `Matrix4` approach is pure Flutter — no dependencies required. The `setEntry(3, 2, 0.001)` perspective trick is well-documented and performant.

### 3.7 Open Source Alternatives Considered

| Package | Verdict |
|---------|---------|
| `flutter_cube` | Full 3D OBJ renderer — overkill, heavy, not Clay-styled |
| `flutter_3d_controller` | GLB/GLTF viewer — too heavy for a simple dice |
| Custom `Matrix4` | ✅ Best fit — lightweight, fully controllable, no dependencies |

**Recommendation: Custom `Matrix4` approach.** A dice is a simple cube; we don't need a 3D engine.

## 4. 2048 Tile Animation Upgrade

### 4.1 Tile Sliding Animation

**Problem:** Tiles teleport to new positions after a swipe.

**Solution:** Use `AnimatedPositioned` (or explicit `PositionedTransition`) within a `Stack` to animate tile movements.

```dart
// Each tile is an AnimatedPositioned inside a Stack
AnimatedPositioned(
  duration: const Duration(milliseconds: 150),
  curve: Curves.easeOutCubic,
  left: col * cellSize,
  top: row * cellSize,
  child: TileWidget(value: tile.value),
)
```

**Key requirements:**
- each tile has a unique `id` (not just value) for identity tracking across moves
- tiles that slide must animate from old position to new position
- tiles that merge must animate to the same position, then one disappears

### 4.2 Merge Animation

When two tiles merge:
1. both tiles slide to the target cell (150ms)
2. one tile disappears (opacity 0, instant)
3. the merged tile does a scale pop: 1.0 → 1.2 → 1.0 (100ms, `Curves.easeOutBack`)

### 4.3 New Tile Spawn Animation

When a new tile appears after a move:
1. delay: 150ms (wait for slide to finish)
2. scale: 0 → 1.0 with slight bounce (200ms, `Curves.easeOutBack`)
3. optional: gentle fade-in from 0.5 → 1.0 opacity

### 4.4 Swipe Touch Feedback (Sticky Feel)

**Problem:** No visual feedback during the swipe gesture itself — tiles don't respond until the swipe completes.

**Solution:** Add gesture-phase visual feedback:

```text
Phase 1: DRAGGING (finger on screen)
├── Translate all movable tiles in swipe direction by drag delta (clamped to 0–cellSize)
├── Opacity: tiles slightly brighten in swipe direction
└── This gives the "sticky" feeling that tiles follow the finger

Phase 2: THRESHOLD REACHED (drag > 50% of cell size)
├── Commit: animate tiles to final positions
└── Trigger game logic

Phase 3: THRESHOLD NOT REACHED (drag < 50%, or finger lifted)
├── Cancel: animate tiles back to original positions (spring curve, 200ms)
```

**Implementation:**

```dart
GestureDetector(
  onPanStart: (details) { ... },
  onPanUpdate: (details) {
    // Move tiles partially in drag direction
    setState(() {
      _dragOffset = details.delta;
      _previewPositions = calculatePreviewPositions(dragDirection, dragProgress);
    });
  },
  onPanEnd: (details) {
    if (dragProgress > threshold) {
      commitSwipe(direction);
    } else {
      cancelSwipe(); // spring back
    }
  },
)
```

### 4.5 Game Over Animation

When no moves remain:
1. tiles sequentially fade to grayscale (wave from top-left to bottom-right, 30ms stagger)
2. overlay fades in with blur (300ms)
3. score and "Game Over" text scale in

### 4.6 Implementation Summary

| Animation | Widget/Approach | Duration | Curve |
|-----------|----------------|----------|-------|
| Tile slide | `AnimatedPositioned` in `Stack` | 150ms | `easeOutCubic` |
| Tile merge pop | `ScaleTransition` | 100ms | `easeOutBack` |
| New tile spawn | `ScaleTransition` + delay | 200ms | `easeOutBack` |
| Swipe preview | Manual offset in `onPanUpdate` | realtime | linear follow |
| Swipe cancel | `AnimatedContainer` spring back | 200ms | `Curves.elasticOut` |
| Game over | Sequential fade + overlay | 800ms total | `easeInOut` |

## 5. Shared Animation Utilities

Create reusable animation helpers in `lib/core/animations/`:

```text
lib/core/animations/
  clay_spring.dart          # Spring simulation curves for clay bounce
  staggered_animation.dart  # Helper for staggered child animations
  scale_pop.dart            # Reusable scale pop (1→1.2→1) widget
  bounce_in.dart            # Reusable bounce-in entrance animation
```

### Clay Spring Curve

Define a custom spring curve that matches the Clay UI "squishy" feel:

```dart
class ClaySpringCurve extends Curve {
  final double damping;
  final double stiffness;

  const ClaySpringCurve({this.damping = 12, this.stiffness = 180});

  @override
  double transformInternal(double t) {
    // Critically damped spring simulation
    final omega = sqrt(stiffness);
    final zeta = damping / (2 * omega);
    // ... spring math producing bounce-settle curve
  }
}
```

## 6. Performance Considerations

| Concern | Mitigation |
|---------|------------|
| 5 dice with 3D transforms simultaneously | Only render 2 faces per cube; use `RepaintBoundary` per die |
| 2048 grid: 16 `AnimatedPositioned` widgets | Lightweight — `AnimatedPositioned` is well-optimized in Flutter |
| Swipe preview redraw on every frame | Use `ValueNotifier` + `ValueListenableBuilder` to minimize rebuilds |
| Cascading animations (2048 merge chains) | Sequence with `Future.delayed`; never run more than 16 concurrent animations |
| Low-end Android devices | Test on mid-range device; cap animation at 60fps; disable stagger on <30fps |

## 7. Milestones

### Milestone 1: Core Animation Utilities (~0.5 day)
- Create `lib/core/animations/` with shared curves and helpers

### Milestone 2: Yahtzee 3D Dice (~2 days)
- Build `ClayCube3D` widget with `Matrix4` perspective transforms
- Build `DiceRollAnimator` with 4-phase roll sequence
- Integrate staggered timing and held-dice behavior
- Replace current `AnimatedDie` internals

### Milestone 3: 2048 Tile Sliding (~1.5 days)
- Refactor tile grid to use `Stack` + `AnimatedPositioned`
- Implement tile identity tracking (unique IDs)
- Add slide, merge-pop, and spawn animations

### Milestone 4: 2048 Touch Feedback (~1 day)
- Add swipe preview (drag-follow)
- Add threshold-based commit/cancel
- Add game-over animation sequence

### Milestone 5: Polish (~0.5 day)
- Tune timing, curves, and stagger offsets
- Android device performance verification
- Ensure held dice, rapid taps, and edge cases are smooth

**Estimated total: ~5.5 days**

## 8. Risk Assessment

| Risk | Mitigation |
|------|------------|
| Matrix4 3D rotation causes visible face clipping | Use simplified 2-face rendering with cross-fade |
| Dice look wrong when rotated (pip orientation) | Pre-render all 6 face widgets with correct orientation |
| 2048 swipe preview conflicts with system back gesture | Add horizontal dead zone on edges; test with Android gesture nav |
| Animation jank on budget phones | Profile with Flutter DevTools; add `RepaintBoundary`; reduce stagger |
| Touch feedback feels laggy | Use `onPanUpdate` (not `onPanEnd`) for real-time response |
