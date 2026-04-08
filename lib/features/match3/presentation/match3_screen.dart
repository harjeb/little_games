import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
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
    return Container(
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

class _Match3Board extends StatelessWidget {
  const _Match3Board({required this.state, required this.onCellTap});

  final Match3State state;
  final void Function(int row, int col) onCellTap;

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
          final piece = state.grid.pieceAt(row, col);
          final isSelected = state.selectedCell == (row, col);
          final isSwapTarget =
              state.lastSwap?.$1 == (row, col) ||
              state.lastSwap?.$2 == (row, col);

          return GestureDetector(
            onTap: state.isPlayable ? () => onCellTap(row, col) : null,
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
                    : _PieceFace(piece: piece),
              ),
            ),
          );
        },
      ),
    );
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
