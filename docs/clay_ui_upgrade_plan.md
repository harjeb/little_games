# Clay UI Upgrade Plan

## 1. Document Goal

This document defines the UI upgrade plan to achieve authentic **Claymorphism (黏土形态)** styling across the Pocket Playroom app. The current implementation uses basic `BoxShadow` for floating/pressed states but is **missing the defining visual trait of Claymorphism: inner shadows that create the puffy, inflated, 3D clay feel**.

Reference: [Smashing Magazine — Claymorphism CSS](https://www.smashingmagazine.com/2022/03/claymorphism-css-ui-design-trend/), [uiprompt.site Clay 效果](https://www.uiprompt.site/zh/styles)

## 2. Current UI Audit

### 2.1 What We Have

**AppShadows** (`app_shadows.dart`):
```dart
// floating: outer dark shadow + outer light glow
BoxShadow(color: shadow, blurRadius: 28, offset: Offset(12, 14))
BoxShadow(color: glow,   blurRadius: 16, offset: Offset(-8, -8))

// pressed: reduced outer shadow + reduced glow
BoxShadow(color: shadow.alpha(0.12), blurRadius: 16, offset: Offset(6, 8))
BoxShadow(color: glow,               blurRadius: 10, offset: Offset(-4, -4))
```

**ClayPanel** (`clay_panel.dart`):
- Simple `Container` with `BoxDecoration` + `AppShadows.floating()`
- No inner shadows
- No gradient surface

**ClayButton** (`clay_button.dart`):
- Toggle between `floating()` and `pressed()` shadow sets
- No inner shadow on either state
- No "push-in" visual (clay squish)

**ClayDie** (`clay_die.dart`):
- Plain white/coral background
- Same `floating()`/`pressed()` shadows
- No inner light/dark shadows for depth
- Looks flat, not like a puffy clay object

**ClayScaffold** (`clay_scaffold.dart`):
- Gradient background (sky → haze → mintCream)
- Decorative blobs (good — keep these)
- No clay texture on background

### 2.2 What's Missing (vs True Claymorphism)

| Feature | Current | Target |
|---------|---------|--------|
| **Inner shadows** (soul of clay) | ❌ None | ✅ Light inset top-left + dark inset bottom-right |
| **Inflated/puffy feel** | ❌ Flat surfaces | ✅ Rounded edges appear thick via inner shadow gradient |
| **Surface color richness** | ⚠️ Plain solid colors | ✅ Subtle gradient from lighter top to slightly darker bottom |
| **Press interaction** | ⚠️ Shadow change only | ✅ Outer shadow shrinks + inner shadow deepens (clay squished) |
| **Border radius scale** | ⚠️ Consistent 28px | ✅ Scale by element size (small: 16, medium: 28, large: 40) |
| **Background texture** | ❌ None | ✅ Optional subtle noise overlay for matte clay feel |
| **Hover/idle animation** | ❌ None | ✅ Gentle breathe (scale oscillation) on interactive elements |

## 3. Claymorphism CSS Reference → Flutter Mapping

### 3.1 The Canonical Claymorphism CSS

From Smashing Magazine / Michał Malewicz:
```css
.clay {
  background: rgb(249, 174, 1);
  border-radius: 48px;
  box-shadow:
    8px 8px 16px 0 rgba(0, 0, 0, 0.25),           /* 1. Outer shadow (depth) */
    inset -8px -8px 12px 0 rgba(0, 0, 0, 0.25),    /* 2. Dark inner shadow (bottom-right) */
    inset 8px 8px 12px 0 rgba(255, 255, 255, 0.4);  /* 3. Light inner shadow (top-left) */
}
```

Three shadows, **not two**. The two inner shadows create the illusion of a thick, rounded edge — as if the element is a real 3D blob of clay with light hitting from the top-left.

### 3.2 Flutter BoxShadow Limitation

Flutter's `BoxShadow` does **NOT** support `inset` shadows natively. This is the root cause of the current flat look.

**Workarounds:**

| Approach | Pros | Cons |
|----------|------|------|
| **A. CustomPainter with `Paint.maskFilter`** | Full control, pixel-perfect | More code, repaint cost |
| **B. Stack with inner Container + gradient border** | Simple, declarative | Less authentic, gradient faking |
| **C. DecoratedBox + ShapeDecoration with custom painter** | Integrates with theme | Moderate complexity |
| **D. `flutter_inner_shadow` package** | Drop-in, minimal code | External dependency |

**Recommended: Approach A (CustomPainter) for core `ClayContainer`**, wrapped in a reusable widget. This gives us full Claymorphism with zero external dependencies and maximum control.

### 3.3 Inner Shadow Implementation

```dart
class ClayPainter extends CustomPainter {
  final Color surfaceColor;
  final double borderRadius;
  final Color outerShadowColor;
  final Color innerDarkColor;
  final Color innerLightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // 1. Outer shadow
    final outerShadowPaint = Paint()
      ..color = outerShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(rrect.shift(const Offset(8, 8)), outerShadowPaint);

    // 2. Surface fill
    canvas.drawRRect(rrect, Paint()..color = surfaceColor);

    // 3. Inner shadow (dark, bottom-right)
    canvas.save();
    canvas.clipRRect(rrect);
    final darkPaint = Paint()
      ..color = innerDarkColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    // Draw a shifted inverted rrect to produce inset shadow
    canvas.drawRRect(
      rrect.shift(const Offset(-8, -8)).inflate(4),
      darkPaint,
    );
    // ... (inverted drawing technique for true inset shadow)
    canvas.restore();

    // 4. Inner shadow (light, top-left)
    canvas.save();
    canvas.clipRRect(rrect);
    final lightPaint = Paint()
      ..color = innerLightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      rrect.shift(const Offset(8, 8)).inflate(4),
      lightPaint,
    );
    canvas.restore();
  }
}
```

The actual inner-shadow technique uses **clipping + inverted path difference** to draw a shadow *inside* the rounded rect. This is a well-known Flutter pattern for achieving CSS `inset box-shadow`.

## 4. Component Upgrade Specifications

### 4.1 ClayContainer (New Core Widget)

Replace the current `ClayPanel` with a new `ClayContainer` that is the foundation for **all** Clay-styled elements.

```dart
class ClayContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final ClayShadowStyle shadowStyle;   // floating, pressed, inset, flat
  final double depth;                   // controls shadow intensity (0–1)

  // Uses ClayPainter internally for true inner + outer shadows
}
```

**Shadow presets:**

| Style | Outer Shadow | Inner Dark | Inner Light | Use Case |
|-------|-------------|------------|-------------|----------|
| `floating` | 8px blur 16, offset(8,8) | inset(-6,-6) blur 10 | inset(6,6) blur 10 | Cards, panels, dice |
| `pressed` | 4px blur 8, offset(4,4) | inset(-8,-8) blur 14 | inset(4,4) blur 8 | Active buttons, held dice |
| `inset` | none | inset(-4,-4) blur 8 | inset(4,4) blur 6 | Input fields, score slots |
| `flat` | 2px blur 6, offset(2,4) | inset(-2,-2) blur 4 | inset(2,2) blur 4 | Small chips, labels |

### 4.2 ClayButton Upgrade

**Current behavior:** Shadow swap between `floating` and `pressed`.

**Target behavior:**

```text
IDLE state:
├── Shadow: floating (with inner shadows → puffy look)
├── Scale: 1.0
└── Surface: solid color

HOVER / TOUCH-DOWN state:
├── Shadow: pressed (inner shadow deepens → "squished" feel)
├── Scale: 0.96 (clay is being pressed)
├── Surface: slightly darker (mix color with 5% black)
└── Transition: 120ms, spring curve

RELEASE state:
├── Shadow: floating (bounce back)
├── Scale: 1.0 → 1.04 → 1.0 (elastic overshoot)
└── Transition: 200ms, elasticOut
```

### 4.3 ClayDie Upgrade

**Current:** Flat white/coral box with outer shadows and pip dots.

**Target:**

```text
IDLE (not held):
├── Surface: warm white with subtle top-to-bottom gradient
├── Shadow: floating with prominent inner shadows
├── Pips: small clay spheres (circle with own inner shadow, not flat dots)
├── Border radius: 24px → 20px (dice should be slightly less round than buttons)
└── Overall feel: like a real soft clay cube you could squeeze

HELD state:
├── Surface: coral with inner shadows
├── Shadow: pressed (deeper inset → visually "pushed down")
├── Pin icon: small clay badge in corner
└── Scale: 0.97 (slightly compressed)

ROLLING state:
├── Full 3D animation (see animation_upgrade_plan.md)
├── Inner shadows rotate with face
└── Landing: squash-and-stretch with shadow bounce
```

**Pip upgrade — clay spheres:**

Current pips are flat colored circles. Upgrade to mini clay spheres:

```dart
// Each pip becomes a tiny ClayContainer with its own inner shadow
Container(
  width: 10, height: 10,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: pipColor,
    // Mini inner shadows for 3D sphere look
    // Achieved via CustomPainter or gradient overlay
  ),
)
```

### 4.4 ClayPanel Upgrade

**Current:** `Container` + `BoxDecoration` with outer shadows only.

**Target:** Replace with `ClayContainer` + inner shadows.

```text
Before:
┌─────────────────────────┐
│  Flat white box          │   ← outer shadow only
│  with rounded corners    │
└─────────────────────────┘

After:
╭─────────────────────────╮
│░ Light highlight         │   ← inner light shadow (top-left)
│                          │
│                          │   ← thick rounded edge illusion
│         Content          │
│                          │
│              Dark edge ░│   ← inner dark shadow (bottom-right)
╰─────────────────────────╯
     └── outer shadow ──┘
```

### 4.5 ClayScaffold Upgrade

**Current:** Gradient background + static blobs.

**Target additions:**
- **Subtle noise texture overlay** (very low opacity, 2–4%) for matte clay surface feel
- **Animated blobs**: slow breathing animation (scale 1.0 → 1.05, 6s loop, staggered)
- **Background tint** responds to current game (e.g., warmer tones for Yahtzee, cooler for 2048)

### 4.6 Score Sheet / Game Card Upgrades

All game cards and score sheet rows should use the `inset` shadow style for data slots:

```text
┌─────────────────────────┐
│  Category Name    [ 25 ]│   ← the [25] sits in a clay "trough" (inset shadow)
│                          │
│  Category Name    [  – ]│   ← empty slot is a recessed dimple
└─────────────────────────┘
```

This matches the Claymorphism principle that input/data areas look "carved out" of the clay surface.

## 5. Color Palette Update

### 5.1 Current Palette Assessment

The current palette in `AppColors` is good but needs refinement for Claymorphism:

| Current | Issue |
|---------|-------|
| `sky: #F9F2E6` | Good warm background |
| `haze: #F6E0D7` | Good |
| `white: #FFFCF8` | Slightly too bright — surfaces should be warmer |
| `shadow: #2E9E7A79` | ⚠️ Opacity too low for outer shadow; hue is greenish — should match surface |
| `glow: #B5FFFFFF` | ⚠️ Pure white glow — should be slightly tinted to match surface |
| `insetShadow: #22A16A64` | ⚠️ Only one inset color — need both dark AND light inset |

### 5.2 Updated Shadow Colors

```dart
final class AppColors {
  // ... keep existing colors ...

  // Updated shadow system for true Claymorphism
  static const Color outerShadow = Color(0x40A08070);       // warm brown, 25% opacity
  static const Color innerShadowDark = Color(0x30806050);    // warm dark, bottom-right
  static const Color innerShadowLight = Color(0x60FFFFFF);   // white highlight, top-left
  static const Color pressedShadowDark = Color(0x40705040);  // deeper for pressed state
  static const Color pressedShadowLight = Color(0x40FFFFFF); // reduced highlight when pressed
}
```

### 5.3 Surface Color Strategy

Every clay element should have a **gradient surface**, not a flat solid color:

```dart
// Instead of: color: AppColors.coral
// Use:
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.coral.lighten(8%),   // slightly lighter top-left
    AppColors.coral,                // base color
    AppColors.coral.darken(5%),    // slightly darker bottom-right
  ],
)
```

Add a `ColorExtension` utility:
```dart
extension ClayColorExtension on Color {
  Color lighten(double percent) => Color.lerp(this, Colors.white, percent / 100)!;
  Color darken(double percent) => Color.lerp(this, Colors.black, percent / 100)!;
}
```

## 6. Typography Update

Current text styles are functional but could better match the Clay aesthetic:

| Element | Current | Target |
|---------|---------|--------|
| Display large | w900 sharp | w800 + slight letter spacing + warm color — less aggressive |
| Body text | `AppColors.ink` (dark purple) | Slightly softer `AppColors.mutedInk` for body — reserve `ink` for headings |
| Score numbers | Regular weight | w900 tabular figures — monospaced digits for score alignment |
| Pip count | Same as body | Consider a rounded display font for game numbers (e.g., Nunito, Varela Round) |

**Optional font addition:** Add **Nunito** or **Varela Round** as the game number font — their rounded letterforms match the clay aesthetic perfectly. Keep the system font for body text.

## 7. Interaction Patterns

### 7.1 Press Feedback Formula

Every interactive Clay element should follow this press formula:

```text
On touch-down (120ms, spring):
  scale: 1.0 → 0.96
  shadow: floating → pressed (inner shadow deepens)
  color: base → darken(5%)

On touch-up (200ms, elasticOut):
  scale: 0.96 → 1.03 → 1.0 (overshoot bounce)
  shadow: pressed → floating
  color: darken(5%) → base
```

### 7.2 Page Transitions

Current: default `MaterialPageRoute` slide.

Upgrade: Clay-themed transitions:
- **Enter**: scale from 0.9 + fade from 0 → 1.0, 300ms, `easeOutCubic`
- **Exit**: scale to 0.95 + fade to 0, 200ms, `easeInCubic`
- This gives the feeling of clay elements "growing" into place

## 8. Implementation Plan

### 8.1 File Changes

#### New files:
```text
lib/core/widgets/clay_container.dart      # New core widget with inner shadows
lib/core/widgets/clay_painter.dart        # CustomPainter for clay shadow rendering
lib/core/animations/clay_spring.dart      # Custom spring curves
lib/core/extensions/color_extension.dart  # lighten/darken helpers
```

#### Modified files:
```text
lib/app/theme/app_shadows.dart            # Rewrite: add inner shadow definitions
lib/app/theme/app_colors.dart             # Add inner shadow colors, refine existing
lib/app/theme/app_theme.dart              # Update typography, add rounded font
lib/core/widgets/clay_panel.dart          # Rewrite: use ClayContainer internally
lib/core/widgets/clay_button.dart         # Rewrite: add press scale + inner shadows
lib/core/widgets/clay_scaffold.dart       # Add noise texture + animated blobs
lib/features/yahtzee/presentation/widgets/clay_die.dart  # Full redesign with clay pips
lib/features/home/presentation/widgets/game_card.dart    # Use ClayContainer
lib/features/home/presentation/home_screen.dart          # Update _FactChip to clay style
```

### 8.2 Migration Strategy

1. Build `ClayContainer` and `ClayPainter` as new widgets (non-breaking)
2. Update `AppShadows` and `AppColors` (non-breaking additions)
3. Migrate `ClayPanel` to use `ClayContainer` internally (visual change, same API)
4. Migrate `ClayButton` (visual + interaction change)
5. Migrate `ClayDie` (visual change)
6. Update remaining widgets (home screen, game cards)
7. Add page transition

Each step can be merged independently — no big-bang migration needed.

## 9. Milestones

### Milestone 1: Core Clay System (~2 days)
- Build `ClayPainter` with inner + outer shadow rendering
- Build `ClayContainer` widget with shadow presets
- Add `ClayColorExtension` (lighten/darken)
- Update `AppColors` and `AppShadows`

### Milestone 2: Component Migration (~2 days)
- Migrate `ClayPanel` → `ClayContainer`
- Migrate `ClayButton` with press scale animation
- Migrate `ClayDie` with clay pips and gradient surface
- Update `_FactChip` and `GameCard`

### Milestone 3: Scaffold and Transitions (~1 day)
- Add noise texture overlay to `ClayScaffold`
- Add blob breathing animation
- Implement clay page transition
- Optional: add Nunito font for game numbers

### Milestone 4: Polish (~0.5 day)
- Fine-tune shadow intensities across all components
- Test on multiple screen sizes and Android devices
- Verify contrast and readability (accessibility)

**Estimated total: ~5.5 days**

## 10. Visual Before/After Comparison

### ClayPanel Before:
```
Outer shadow only → looks like a card floating, but surface is flat
┌───────────────────┐
│                   │   No depth on the surface itself
│     Content       │   Edges look sharp despite rounded corners
│                   │
└───────────────────┘
      ▓▓▓▓ (outer shadow)
```

### ClayPanel After:
```
Inner + outer shadows → surface looks inflated, edges look thick
╭───────────────────╮
│░░░ highlight      │   Inner light shadow (top-left)
│                   │   Surface has subtle gradient
│     Content       │   Edges appear thick and rounded
│                   │
│         ░░░ dark │   Inner dark shadow (bottom-right)
╰───────────────────╯
      ▓▓▓▓ (outer shadow)

The element looks like a puffy clay blob, not a flat card.
```

## 11. Accessibility Considerations

- inner shadows must not reduce text contrast below WCAG AA (4.5:1)
- dark inner shadow should be subtle enough to not interfere with content readability
- pressed state must maintain sufficient contrast
- test with Android TalkBack and font scaling
- respect `MediaQuery.disableAnimations` for press animations

## 12. Risk Assessment

| Risk | Mitigation |
|------|------------|
| `CustomPainter` performance with many clay elements | Use `RepaintBoundary` per element; cache shadow painting |
| Inner shadow too strong → looks dirty/muddy | Start subtle (20–30% opacity); iterate visually |
| Inner shadow too weak → not noticeable | Test on multiple screens; ensure at least 10% visible difference |
| Gradient surfaces look banded on low-res screens | Use enough gradient stops; test on MDPI devices |
| Font change breaks existing layouts | Use Nunito only for game numbers; keep system font for body |
| Migration breaks existing widget tests | Migrate one component at a time; run tests after each step |
