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
  ProviderSubscription<Match3State>? _subscription;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<Match3State>(match3ControllerProvider, (
      previous,
      next,
    ) {
      if (!_navigated &&
          previous?.status == Match3Status.playing &&
          next.status != Match3Status.playing) {
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            AppRouter.match3ResultRoute,
            arguments: Match3ResultData(
              level: next.level,
              score: next.score,
              didWin: next.status == Match3Status.won,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(match3ControllerProvider);
    final controller = ref.read(match3ControllerProvider.notifier);

    return ClayScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.match3Title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClayPanel(
              backgroundColor: AppColors.white.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.match3Hint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HudCard(
                          label: l10n.score,
                          value: '${state.score}',
                          color: AppColors.butter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HudCard(
                          label: _progressLabel(l10n, state.level),
                          value: _progressValue(state),
                          color: AppColors.mintCream,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HudCard(
                          label: l10n.target,
                          value: '${state.level.targetScore}',
                          color: AppColors.melon,
                        ),
                      ),
                    ],
                  ),
                  if (state.lastCascadeCount > 1 ||
                      state.lastClearedCount > 0) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (state.lastCascadeCount > 1)
                          _ChipBadge(
                            text: l10n.match3Combo(state.lastCascadeCount),
                            color: AppColors.blueberry,
                          ),
                        if (state.level.ruleType ==
                            Match3LevelRuleType.obstacles)
                          _ChipBadge(
                            text: l10n.match3ObstaclesLeft(
                              state.obstaclesRemaining,
                            ),
                            color: AppColors.lagoon,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (state.showLevelPicker) ...[
                    Text(
                      l10n.match3ChooseLevel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _LevelPicker(
                      activeLevel: state.level,
                      onSelect: controller.startLevel,
                    ),
                    const SizedBox(height: 18),
                  ],
                  AspectRatio(
                    aspectRatio: 1,
                    child: _Match3Board(
                      state: state,
                      onCellTap: controller.selectCell,
                      onCellDrag: controller.dragSwap,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ClayButton(
                        label: l10n.match3LevelLabel(state.level.id),
                        icon: Icons.layers_rounded,
                        onPressed: controller.toggleLevelPicker,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.ink,
                      ),
                      ClayButton(
                        label: l10n.newGame,
                        icon: Icons.refresh_rounded,
                        onPressed: controller.restartCurrentLevel,
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(AppLocalizations l10n, Match3LevelConfig level) {
    return switch (level.ruleType) {
      Match3LevelRuleType.moves => l10n.match3Moves,
      Match3LevelRuleType.timer => l10n.time,
      Match3LevelRuleType.obstacles => l10n.match3Obstacles,
    };
  }

  String _progressValue(Match3State state) {
    return switch (state.level.ruleType) {
      Match3LevelRuleType.moves => '${state.movesRemaining ?? 0}',
      Match3LevelRuleType.timer => _formatDuration(
        state.timeRemainingSeconds ?? 0,
      ),
      Match3LevelRuleType.obstacles => '${state.obstaclesRemaining}',
    };
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: color,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.86, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: lerpDouble(0.55, 1, value)!,
          child: Transform.translate(
            offset: Offset(0, lerpDouble(10, 0, value)!),
            child: Transform.scale(scale: value, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.activeLevel, required this.onSelect});

  final Match3LevelConfig activeLevel;
  final ValueChanged<Match3LevelConfig> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        for (final level in Match3LevelConfig.defaults) ...[
          InkWell(
            onTap: () => onSelect(level),
            borderRadius: BorderRadius.circular(24),
            child: ClayPanel(
              backgroundColor: level.id == activeLevel.id
                  ? AppColors.sky
                  : AppColors.white.withValues(alpha: 0.92),
              borderRadius: 24,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _levelColor(level.id),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${level.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.match3LevelLabel(level.id),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _levelSubtitle(l10n, level),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (level != Match3LevelConfig.defaults.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _levelSubtitle(AppLocalizations l10n, Match3LevelConfig level) {
    return switch (level.ruleType) {
      Match3LevelRuleType.moves =>
        '${l10n.match3Moves}: ${level.movesLimit} • ${l10n.target}: ${level.targetScore}',
      Match3LevelRuleType.timer =>
        '${l10n.time}: ${level.timeLimitSeconds}s • ${l10n.target}: ${level.targetScore}',
      Match3LevelRuleType.obstacles =>
        '${l10n.match3Obstacles}: ${level.obstacles.length} • ${l10n.match3Moves}: ${level.movesLimit}',
    };
  }

  Color _levelColor(int id) {
    return switch (id) {
      1 => AppColors.coral,
      2 => AppColors.blueberry,
      _ => AppColors.lagoon,
    };
  }
}

class _Match3Board extends StatefulWidget {
  const _Match3Board({
    required this.state,
    required this.onCellTap,
    required this.onCellDrag,
  });

  final Match3State state;
  final void Function(int row, int col) onCellTap;
  final void Function(int fromRow, int fromCol, int toRow, int toCol)
  onCellDrag;

  @override
  State<_Match3Board> createState() => _Match3BoardState();
}

class _Match3BoardState extends State<_Match3Board>
    with SingleTickerProviderStateMixin {
  static const double _dragThreshold = 20;

  (int row, int col)? _dragOrigin;
  Offset _dragDelta = Offset.zero;
  bool _dragTriggered = false;
  late final AnimationController _boardFxController;
  Map<int, (int row, int col)> _previousPositions = <int, (int row, int col)>{};
  Set<int> _animatedPieceIds = <int>{};

  @override
  void initState() {
    super.initState();
    _boardFxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _Match3Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_gridSignature(oldWidget.state.grid) ==
        _gridSignature(widget.state.grid)) {
      return;
    }

    _previousPositions = _positionsById(oldWidget.state.grid);
    final nextPositions = _positionsById(widget.state.grid);
    _animatedPieceIds = {
      for (final entry in nextPositions.entries)
        if (!_previousPositions.containsKey(entry.key) ||
            _previousPositions[entry.key] != entry.value)
          entry.key,
    };
    _boardFxController.forward(from: 0);
  }

  @override
  void dispose() {
    _boardFxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: AppColors.haze.withValues(alpha: 0.95),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          final piece = widget.state.grid.pieceAt(row, col);
          final isSelected = widget.state.selectedCell == (row, col);
          final isSwapTarget =
              widget.state.lastSwap?.$1 == (row, col) ||
              widget.state.lastSwap?.$2 == (row, col);

          return GestureDetector(
            onTap: widget.state.isPlayable
                ? () => widget.onCellTap(row, col)
                : null,
            onPanStart: widget.state.isPlayable
                ? (_) => _beginDrag(row, col)
                : null,
            onPanUpdate: widget.state.isPlayable
                ? (details) => _updateDrag(details)
                : null,
            onPanEnd: widget.state.isPlayable ? (_) => _endDrag() : null,
            onPanCancel: widget.state.isPlayable ? _cancelDrag : null,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: isSelected ? 1.06 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected
                      ? AppColors.white
                      : isSwapTarget
                      ? AppColors.sky.withValues(alpha: 0.95)
                      : AppColors.white.withValues(alpha: 0.82),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.blueberry
                        : Colors.white.withValues(alpha: 0.3),
                    width: isSelected ? 2.2 : 1,
                  ),
                ),
                child: piece == null
                    ? const SizedBox.shrink()
                    : AnimatedBuilder(
                        animation: _boardFxController,
                        builder: (context, child) {
                          final progress = _pieceAnimationProgress(piece.id);
                          final previous = _previousPositions[piece.id];
                          final rowDelta = previous == null
                              ? -1
                              : previous.$1 - row;
                          final columnDelta = previous == null
                              ? 0
                              : previous.$2 - col;
                          final yOffset = lerpDouble(
                            rowDelta == 0 ? 0 : rowDelta * 12,
                            0,
                            progress,
                          )!;
                          final xOffset = lerpDouble(
                            columnDelta == 0 ? 0 : columnDelta * 8,
                            0,
                            progress,
                          )!;

                          return Opacity(
                            opacity: lerpDouble(
                              _animatedPieceIds.contains(piece.id) ? 0.35 : 1,
                              1,
                              progress,
                            )!,
                            child: Transform.translate(
                              offset: Offset(xOffset, yOffset),
                              child: Transform.scale(
                                scale: lerpDouble(
                                  _animatedPieceIds.contains(piece.id)
                                      ? 0.88
                                      : 1,
                                  1,
                                  progress,
                                )!,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _PieceFace(piece: piece),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _beginDrag(int row, int col) {
    _dragOrigin = (row, col);
    _dragDelta = Offset.zero;
    _dragTriggered = false;
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_dragOrigin == null || _dragTriggered) {
      return;
    }

    _dragDelta += details.delta;
    if (_dragDelta.distance < _dragThreshold) {
      return;
    }

    final horizontal = _dragDelta.dx.abs() >= _dragDelta.dy.abs();
    final rowDelta = horizontal ? 0 : (_dragDelta.dy.isNegative ? -1 : 1);
    final colDelta = horizontal ? (_dragDelta.dx.isNegative ? -1 : 1) : 0;
    final target = (_dragOrigin!.$1 + rowDelta, _dragOrigin!.$2 + colDelta);
    if (target.$1 < 0 || target.$1 >= 8 || target.$2 < 0 || target.$2 >= 8) {
      _dragTriggered = true;
      return;
    }

    widget.onCellDrag(_dragOrigin!.$1, _dragOrigin!.$2, target.$1, target.$2);
    _dragTriggered = true;
  }

  void _endDrag() {
    _dragOrigin = null;
    _dragDelta = Offset.zero;
    _dragTriggered = false;
  }

  void _cancelDrag() {
    _endDrag();
  }

  double _pieceAnimationProgress(int pieceId) {
    if (!_animatedPieceIds.contains(pieceId)) {
      return 1;
    }
    return Curves.easeOutBack.transform(_boardFxController.value.clamp(0, 1));
  }

  Map<int, (int row, int col)> _positionsById(Match3Grid grid) {
    final positions = <int, (int row, int col)>{};
    for (var row = 0; row < grid.height; row++) {
      for (var col = 0; col < grid.width; col++) {
        final piece = grid.pieceAt(row, col);
        if (piece != null) {
          positions[piece.id] = (row, col);
        }
      }
    }
    return positions;
  }

  String _gridSignature(Match3Grid grid) {
    final parts = <String>[];
    for (var row = 0; row < grid.height; row++) {
      for (var col = 0; col < grid.width; col++) {
        final piece = grid.pieceAt(row, col);
        parts.add(piece == null ? '_' : '${piece.id}:${piece.type.name}');
      }
    }
    return parts.join('|');
  }
}

class _PieceFace extends StatelessWidget {
  const _PieceFace({required this.piece});

  final Match3Piece piece;

  @override
  Widget build(BuildContext context) {
    if (piece.type == Match3PieceType.obstacle) {
      return Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_motion_rounded,
            size: 16,
            color: AppColors.white,
          ),
        ),
      );
    }

    final color = _colorFor(piece.color);
    final icon = switch (piece.type) {
      Match3PieceType.rowClear => Icons.swap_horiz_rounded,
      Match3PieceType.columnClear => Icons.swap_vert_rounded,
      Match3PieceType.rainbow => Icons.auto_awesome_rounded,
      _ => null,
    };

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: icon == null ? 34 : 40,
        height: icon == null ? 34 : 40,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [Color.lerp(color, Colors.white, 0.22) ?? color, color],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: icon == null
            ? null
            : Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }

  Color _colorFor(Match3PieceColor color) {
    return switch (color) {
      Match3PieceColor.coral => AppColors.coral,
      Match3PieceColor.butter => AppColors.butter,
      Match3PieceColor.blueberry => AppColors.blueberry,
      Match3PieceColor.lagoon => AppColors.lagoon,
      Match3PieceColor.grape => const Color(0xFFAA8FD8),
      Match3PieceColor.peach => const Color(0xFFF0A56B),
      Match3PieceColor.any => AppColors.white,
    };
  }
}
