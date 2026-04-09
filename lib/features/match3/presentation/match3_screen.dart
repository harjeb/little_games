import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../domain/match3_grid.dart';
import '../domain/match3_level_config.dart';
import '../domain/match3_piece.dart';
import 'controllers/match3_controller.dart';
import 'controllers/match3_state.dart';
import 'match3_result_screen.dart';

class Match3Screen extends ConsumerStatefulWidget {
  const Match3Screen({super.key});

  @override
  ConsumerState<Match3Screen> createState() => _Match3ScreenState();
}

class _Match3ScreenState extends ConsumerState<Match3Screen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(match3ControllerProvider);
    final controller = ref.read(match3ControllerProvider.notifier);

    ref.listen<PadState>(match3ControllerProvider, (prev, next) {
      if (_navigated) return;
      if (next.phase == PadPhase.dead ||
          next.phase == PadPhase.dungeonCleared) {
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            AppRouter.match3ResultRoute,
            arguments: Match3ResultData(
              stagesCleared: next.phase == PadPhase.dungeonCleared
                  ? DungeonConfig.stages.length
                  : next.stageIndex,
              totalDamage: next.totalDamageDealt,
              maxCombo: next.maxCombo,
              didWin: next.phase == PadPhase.dungeonCleared,
            ),
          );
        });
      }
    });

    return ClayScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.match3Title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${state.stageIndex + 1} / ${DungeonConfig.stages.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MonsterPanel(state: state),
              const SizedBox(height: 8),
              if (state.lastDamageDealt > 0 ||
                  state.lastHealingDone > 0 ||
                  state.lastMonsterDamage > 0)
                _CombatFeedback(state: state),
              const SizedBox(height: 8),
              Expanded(
                child: _PadBoard(state: state, controller: controller),
              ),
              const SizedBox(height: 8),
              _PlayerBar(state: state),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      label: l10n.newGame,
                      icon: Icons.refresh_rounded,
                      onPressed: controller.restartDungeon,
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  if (state.phase == PadPhase.stageCleared) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClayButton(
                        label: l10n.match3NextStage,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: controller.nextStageOrFinish,
                        backgroundColor: AppColors.lagoon,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonsterPanel extends StatelessWidget {
  const _MonsterPanel({required this.state});

  final PadState state;

  @override
  Widget build(BuildContext context) {
    final monster = state.monster;
    final hpFraction = (state.monsterHp / monster.hp).clamp(0.0, 1.0);

    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.92),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _elementColor(monster.element),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _elementEmoji(monster.element),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.isChinese ? monster.nameZh : monster.nameEn,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'ATK ${monster.attack}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${state.monsterHp} / ${monster.hp}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hpFraction,
              minHeight: 10,
              backgroundColor: AppColors.haze,
              valueColor: AlwaysStoppedAnimation<Color>(
                _elementColor(monster.element),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({required this.state});

  final PadState state;

  @override
  Widget build(BuildContext context) {
    final fraction = (state.playerHp / DungeonConfig.playerStartHp).clamp(
      0.0,
      1.0,
    );
    final l10n = context.l10n;

    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text('♥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.padPlayerHp}: ${state.playerHp} / ${DungeonConfig.playerStartHp}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.haze,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.coral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.phase == PadPhase.dragging) ...[
            const SizedBox(width: 12),
            Text(
              '${state.dragTimeRemaining.toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: state.dragTimeRemaining < 1.5
                    ? AppColors.coral
                    : AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CombatFeedback extends StatelessWidget {
  const _CombatFeedback({required this.state});

  final PadState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (state.lastTurnResult != null &&
            state.lastTurnResult!.comboCount > 0)
          _tag(
            '${state.lastTurnResult!.comboCount} Combo',
            AppColors.blueberry,
          ),
        if (state.lastDamageDealt > 0)
          _tag('${l10n.padDamage} ${state.lastDamageDealt}', AppColors.coral),
        if (state.lastHealingDone > 0)
          _tag('${l10n.padHeal} +${state.lastHealingDone}', AppColors.lagoon),
        if (state.lastMonsterDamage > 0)
          _tag(
            '${l10n.padMonsterAtk} -${state.lastMonsterDamage}',
            AppColors.ink,
          ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PadBoard extends StatelessWidget {
  const _PadBoard({required this.state, required this.controller});

  final PadState state;
  final Match3Controller controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 5 * 6) / 6;
        final boardHeight = cellSize * 5 + 4 * 6;

        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: boardHeight,
            child: ClayPanel(
              backgroundColor: AppColors.haze.withValues(alpha: 0.92),
              padding: const EdgeInsets.all(6),
              child: _OrbGrid(state: state, controller: controller),
            ),
          ),
        );
      },
    );
  }
}

class _OrbGrid extends StatefulWidget {
  const _OrbGrid({required this.state, required this.controller});

  final PadState state;
  final Match3Controller controller;

  @override
  State<_OrbGrid> createState() => _OrbGridState();
}

class _OrbGridState extends State<_OrbGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swapController;
  Map<int, (int row, int col)> _previousPositions = <int, (int row, int col)>{};
  Map<int, int> _spawnSourceRows = <int, int>{};
  Set<int> _movedOrbIds = <int>{};
  Map<int, _OrbGhost> _vanishingOrbs = <int, _OrbGhost>{};
  Offset? _pointerLocal;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _OrbGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_gridSignature(oldWidget.state.grid) !=
        _gridSignature(widget.state.grid)) {
      _previousPositions = _positionsById(oldWidget.state.grid);
      final previousOrbs = _orbsById(oldWidget.state.grid);
      final nextOrbs = _orbsById(widget.state.grid);
      final nextPositions = _positionsById(widget.state.grid);
      _spawnSourceRows = _computeSpawnSourceRows(widget.state.grid);
      _movedOrbIds = {
        for (final entry in nextPositions.entries)
          if (_previousPositions[entry.key] != entry.value) entry.key,
      };
      _vanishingOrbs = {
        for (final entry in previousOrbs.entries)
          if (!nextOrbs.containsKey(entry.key))
            entry.key: _OrbGhost(
              orb: entry.value,
              row: _previousPositions[entry.key]!.$1,
              col: _previousPositions[entry.key]!.$2,
            ),
      };
      if (_movedOrbIds.isNotEmpty || _vanishingOrbs.isNotEmpty) {
        _swapController.forward(from: 0);
      }
    }

    if (widget.state.phase != PadPhase.dragging && _pointerLocal != null) {
      _pointerLocal = null;
    }
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 4.0;
        final cellW = (constraints.maxWidth - gap * 5) / 6;
        final cellH = (constraints.maxHeight - gap * 4) / 5;
        final cellSize = cellW < cellH ? cellW : cellH;

        final activeDragCell = widget.state.dragCurrent;
        final activeOrb = activeDragCell == null
            ? null
            : widget.state.grid.orbAt(activeDragCell.$1, activeDragCell.$2);
        final activeOrbId = activeOrb?.id;
        final activeOffset = _activeDragOffset(
          cellSize: cellSize,
          gap: gap,
          activeCell: activeDragCell,
        );
        final preview = _dragPreview(
          cellSize: cellSize,
          currentCell: activeDragCell,
          activeOffset: activeOffset,
          activeOrbId: activeOrbId,
        );

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.state.canDrag
              ? (event) {
                  setState(() => _pointerLocal = event.localPosition);
                  final pos = _cellFromOffset(
                    event.localPosition,
                    cellSize,
                    gap,
                  );
                  if (pos != null) widget.controller.beginDrag(pos.$1, pos.$2);
                }
              : null,
          onPointerMove: widget.state.phase == PadPhase.dragging
              ? (event) {
                  setState(() => _pointerLocal = event.localPosition);
                  final pos = _cellFromOffset(
                    event.localPosition,
                    cellSize,
                    gap,
                  );
                  if (pos != null) widget.controller.moveDrag(pos.$1, pos.$2);
                }
              : null,
          onPointerUp: widget.state.phase == PadPhase.dragging
              ? (_) {
                  setState(() => _pointerLocal = null);
                  widget.controller.endDrag();
                }
              : null,
          onPointerCancel: widget.state.phase == PadPhase.dragging
              ? (_) => setState(() => _pointerLocal = null)
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var row = 0; row < 5; row++)
                for (var col = 0; col < 6; col++)
                  if (widget.state.grid.orbAt(row, col) case final orb?)
                    if (orb.id != activeOrbId)
                      _buildOrb(
                        orb: orb,
                        row: row,
                        col: col,
                        cellSize: cellSize,
                        gap: gap,
                        extraOffset: preview.targetOrbId == orb.id
                            ? preview.targetOffset
                            : Offset.zero,
                        isDragging: false,
                        previewProgress: preview.progress,
                        isPreviewTarget: preview.targetOrbId == orb.id,
                      ),
              for (final ghost in _vanishingOrbs.values)
                Positioned(
                  left: ghost.col * (cellSize + gap),
                  top: ghost.row * (cellSize + gap),
                  child: _ClearingOrb(
                    orb: ghost.orb,
                    size: cellSize,
                    animation: _swapController,
                  ),
                ),
              if (activeOrb case final orb?)
                _buildOrb(
                  orb: orb,
                  row: activeDragCell!.$1,
                  col: activeDragCell.$2,
                  cellSize: cellSize,
                  gap: gap,
                  extraOffset: activeOffset,
                  isDragging: true,
                  previewProgress: preview.progress,
                  isPreviewTarget: false,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrb({
    required Orb orb,
    required int row,
    required int col,
    required double cellSize,
    required double gap,
    required Offset extraOffset,
    required bool isDragging,
    required double previewProgress,
    required bool isPreviewTarget,
  }) {
    final cellOffset = Offset(col * (cellSize + gap), row * (cellSize + gap));
    final motionOffset = _swapMotionOffset(
      orbId: orb.id,
      row: row,
      col: col,
      cellSize: cellSize,
      gap: gap,
    );

    return Positioned(
      left: cellOffset.dx + motionOffset.dx + extraOffset.dx,
      top: cellOffset.dy + motionOffset.dy + extraOffset.dy,
      child: _OrbCell(
        orb: orb,
        size: cellSize,
        isDragging: isDragging,
        isPreviewTarget: isPreviewTarget,
        previewProgress: previewProgress,
      ),
    );
  }

  (int, int)? _cellFromOffset(Offset offset, double cellSize, double gap) {
    final col = (offset.dx / (cellSize + gap)).floor();
    final row = (offset.dy / (cellSize + gap)).floor();
    if (row < 0 || row >= 5 || col < 0 || col >= 6) return null;
    return (row, col);
  }

  Offset _activeDragOffset({
    required double cellSize,
    required double gap,
    required (int row, int col)? activeCell,
  }) {
    if (_pointerLocal == null || activeCell == null) {
      return Offset.zero;
    }

    final cellOrigin = Offset(
      activeCell.$2 * (cellSize + gap),
      activeCell.$1 * (cellSize + gap),
    );
    final center = cellOrigin + Offset(cellSize / 2, cellSize / 2);
    final delta = _pointerLocal! - center;
    return Offset(
      delta.dx.clamp(-cellSize * 0.38, cellSize * 0.38).toDouble(),
      delta.dy.clamp(-cellSize * 0.38, cellSize * 0.38).toDouble(),
    );
  }

  _DragPreview _dragPreview({
    required double cellSize,
    required (int row, int col)? currentCell,
    required Offset activeOffset,
    required int? activeOrbId,
  }) {
    if (currentCell == null || activeOrbId == null) {
      return const _DragPreview.none();
    }

    final horizontal = activeOffset.dx.abs() >= activeOffset.dy.abs();
    final dominant = horizontal ? activeOffset.dx : activeOffset.dy;
    final progress = ((dominant.abs() - cellSize * 0.08) / (cellSize * 0.24))
        .clamp(0.0, 1.0)
        .toDouble();
    if (progress <= 0) {
      return const _DragPreview.none();
    }

    final rowDelta = horizontal ? 0 : (dominant.isNegative ? -1 : 1);
    final colDelta = horizontal ? (dominant.isNegative ? -1 : 1) : 0;
    final targetRow = currentCell.$1 + rowDelta;
    final targetCol = currentCell.$2 + colDelta;
    if (targetRow < 0 ||
        targetRow >= widget.state.grid.rows ||
        targetCol < 0 ||
        targetCol >= widget.state.grid.cols) {
      return const _DragPreview.none();
    }

    final targetOrb = widget.state.grid.orbAt(targetRow, targetCol);
    if (targetOrb == null || targetOrb.id == activeOrbId) {
      return const _DragPreview.none();
    }

    final direction = Offset(colDelta.toDouble(), rowDelta.toDouble());
    return _DragPreview(
      targetOrbId: targetOrb.id,
      targetOffset: direction * (cellSize * 0.24 * progress),
      progress: progress,
    );
  }

  Offset _swapMotionOffset({
    required int orbId,
    required int row,
    required int col,
    required double cellSize,
    required double gap,
  }) {
    if (!_movedOrbIds.contains(orbId)) {
      return Offset.zero;
    }

    final previous = _previousPositions[orbId];
    if (previous == null) {
      final sourceRow = _spawnSourceRows[orbId];
      if (sourceRow == null) {
        return Offset.zero;
      }

      final progress = Curves.easeOutCubic.transform(_swapController.value);
      return Offset.lerp(
            Offset(0, (sourceRow - row) * (cellSize + gap)),
            Offset.zero,
            progress,
          ) ??
          Offset.zero;
    }

    final progress = Curves.easeOutCubic.transform(_swapController.value);
    return Offset.lerp(
          Offset(
            (previous.$2 - col) * (cellSize + gap),
            (previous.$1 - row) * (cellSize + gap),
          ),
          Offset.zero,
          progress,
        ) ??
        Offset.zero;
  }

  Map<int, (int row, int col)> _positionsById(PadGrid grid) {
    final positions = <int, (int row, int col)>{};
    for (var row = 0; row < grid.rows; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final orb = grid.orbAt(row, col);
        if (orb != null) {
          positions[orb.id] = (row, col);
        }
      }
    }
    return positions;
  }

  Map<int, int> _computeSpawnSourceRows(PadGrid grid) {
    final sourceRows = <int, int>{};
    for (var col = 0; col < grid.cols; col++) {
      final newOrbIds = <int>[];
      for (var row = 0; row < grid.rows; row++) {
        final orb = grid.orbAt(row, col);
        if (orb != null && !_previousPositions.containsKey(orb.id)) {
          newOrbIds.add(orb.id);
        }
      }

      for (var index = 0; index < newOrbIds.length; index++) {
        sourceRows[newOrbIds[index]] = -(newOrbIds.length - index);
      }
    }
    return sourceRows;
  }

  Map<int, Orb> _orbsById(PadGrid grid) {
    final orbs = <int, Orb>{};
    for (var row = 0; row < grid.rows; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final orb = grid.orbAt(row, col);
        if (orb != null) {
          orbs[orb.id] = orb;
        }
      }
    }
    return orbs;
  }

  String _gridSignature(PadGrid grid) {
    final parts = <String>[];
    for (var row = 0; row < grid.rows; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final orb = grid.orbAt(row, col);
        parts.add(orb == null ? '_' : '${orb.id}:${orb.element.name}');
      }
    }
    return parts.join('|');
  }
}

class _OrbCell extends StatelessWidget {
  const _OrbCell({
    required this.orb,
    required this.size,
    required this.isDragging,
    required this.isPreviewTarget,
    required this.previewProgress,
  });

  final Orb? orb;
  final double size;
  final bool isDragging;
  final bool isPreviewTarget;
  final double previewProgress;

  @override
  Widget build(BuildContext context) {
    if (orb == null) {
      return SizedBox.square(dimension: size);
    }

    final color = _elementColor(orb!.element);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isDragging
          ? 1.18
          : isPreviewTarget
          ? lerpDouble(1.0, 0.92, previewProgress)!
          : 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [Color.lerp(color, Colors.white, 0.28) ?? color, color],
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDragging ? 0.48 : 0.35),
              blurRadius: isDragging ? 10 : 6,
              offset: isDragging ? const Offset(2, 8) : const Offset(1, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _elementEmoji(orb!.element),
            style: TextStyle(fontSize: size * 0.42),
          ),
        ),
      ),
    );
  }
}

class _ClearingOrb extends StatelessWidget {
  const _ClearingOrb({
    required this.orb,
    required this.size,
    required this.animation,
  });

  final Orb orb;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final pop = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
    final flash = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );

    final color = _elementColor(orb.element);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final flashProgress = flash.value.clamp(0.0, 1.0);
        final fadeProgress = fade.value.clamp(0.0, 1.0);
        final popScale = lerpDouble(1.0, 1.18, pop.value.clamp(0.0, 1.0))!;
        final shrinkScale = lerpDouble(1.0, 0.68, fadeProgress)!;
        final overlayAlpha =
            lerpDouble(0.0, 0.88, flashProgress)! * (1.0 - fadeProgress * 0.9);
        final glowAlpha = lerpDouble(0.25, 0.0, fadeProgress)!;
        final glowBlur = lerpDouble(10.0, 22.0, flashProgress)!;

        return Opacity(
          opacity: lerpDouble(1.0, 0.0, fadeProgress)!,
          child: Transform.scale(
            scale: popScale * shrinkScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                _OrbCell(
                  orb: orb,
                  size: size,
                  isDragging: false,
                  isPreviewTarget: false,
                  previewProgress: 0,
                ),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: overlayAlpha),
                        Colors.white.withValues(alpha: overlayAlpha * 0.4),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(size * 0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DragPreview {
  const _DragPreview({
    required this.targetOrbId,
    required this.targetOffset,
    required this.progress,
  });

  const _DragPreview.none()
    : targetOrbId = null,
      targetOffset = Offset.zero,
      progress = 0;

  final int? targetOrbId;
  final Offset targetOffset;
  final double progress;
}

class _OrbGhost {
  const _OrbGhost({required this.orb, required this.row, required this.col});

  final Orb orb;
  final int row;
  final int col;
}

Color _elementColor(OrbElement element) {
  return switch (element) {
    OrbElement.fire => const Color(0xFFE25050),
    OrbElement.water => const Color(0xFF4A90D9),
    OrbElement.wind => const Color(0xFF4AB866),
    OrbElement.light => const Color(0xFFD4A829),
    OrbElement.dark => const Color(0xFF8B5EB0),
    OrbElement.heart => const Color(0xFFE87DA0),
  };
}

String _elementEmoji(OrbElement element) {
  return switch (element) {
    OrbElement.fire => '🔥',
    OrbElement.water => '💧',
    OrbElement.wind => '🍃',
    OrbElement.light => '✨',
    OrbElement.dark => '🌙',
    OrbElement.heart => '♥',
  };
}
