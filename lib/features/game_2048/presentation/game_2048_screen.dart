import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/game_ids.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../../leaderboard/leaderboard_providers.dart';
import '../domain/board.dart';
import '../domain/move_engine.dart';
import 'controllers/game_2048_controller.dart';
import 'game_2048_result_screen.dart';

class Game2048Screen extends ConsumerWidget {
  const Game2048Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(game2048ControllerProvider);
    final controller = ref.read(game2048ControllerProvider.notifier);
    final bestScore = ref.watch(bestScoreProvider(GameIds.game2048));

    return ClayScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
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
                        l10n.game2048Title,
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
                        l10n.game2048Hint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ScoreCard(
                              label: l10n.score,
                              value: state.board.score.toString(),
                              color: AppColors.butter,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ScoreCard(
                              label: l10n.best,
                              value: bestScore.when(
                                data: (record) =>
                                    record?.score.toString() ?? l10n.noRecord,
                                error: (_, _) => l10n.unavailable,
                                loading: () => l10n.loading,
                              ),
                              color: AppColors.mintCream,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity.abs() < 120) {
                            return;
                          }
                          controller.slide(
                            velocity < 0
                                ? SlideDirection.left
                                : SlideDirection.right,
                          );
                        },
                        onVerticalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity.abs() < 120) {
                            return;
                          }
                          controller.slide(
                            velocity < 0
                                ? SlideDirection.up
                                : SlideDirection.down,
                          );
                        },
                        child: _TileBoard(board: state.board),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ClayButton(
                            label: l10n.newGame,
                            icon: Icons.refresh_rounded,
                            onPressed: controller.newGame,
                            backgroundColor: AppColors.blueberry,
                            foregroundColor: AppColors.white,
                          ),
                          ClayButton(
                            label: l10n.finishRun,
                            icon: Icons.flag_rounded,
                            onPressed: state.board.score == 0
                                ? null
                                : () => _finishRun(context, state.board),
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.ink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.showWinOverlay || state.showLossOverlay)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClayPanel(
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.97,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.showWinOverlay
                                  ? l10n.hit2048
                                  : l10n.noMovesLeft,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.showWinOverlay
                                  ? l10n.hit2048Hint
                                  : l10n.noMovesLeftHint,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.mutedInk),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (state.showWinOverlay)
                                  ClayButton(
                                    label: l10n.keepGoing,
                                    icon: Icons.trending_up_rounded,
                                    onPressed: controller.continueAfterWin,
                                    backgroundColor: AppColors.blueberry,
                                    foregroundColor: AppColors.white,
                                  ),
                                ClayButton(
                                  label: l10n.saveResult,
                                  icon: Icons.emoji_events_rounded,
                                  onPressed: () =>
                                      _finishRun(context, state.board),
                                  backgroundColor: AppColors.coral,
                                  foregroundColor: AppColors.white,
                                ),
                                ClayButton(
                                  label: l10n.newBoard,
                                  icon: Icons.refresh_rounded,
                                  onPressed: controller.newGame,
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.ink,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _finishRun(BuildContext context, Board board) {
    Navigator.of(context).pushReplacementNamed(
      AppRouter.game2048ResultRoute,
      arguments: Game2048ResultData(
        finalScore: board.score,
        maxTile: board.maxTileValue,
        didReach2048: board.maxTileValue >= 2048,
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
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
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _TileBoard extends StatelessWidget {
  const _TileBoard({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClayPanel(
        backgroundColor: AppColors.haze.withValues(alpha: 0.96),
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Board.size,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: Board.size * Board.size,
          itemBuilder: (context, index) {
            final row = index ~/ Board.size;
            final col = index % Board.size;
            final tile = board.tileAt(row, col);
            final backgroundColor = _tileColor(tile?.value);
            final foregroundColor = (tile?.value ?? 0) >= 8
                ? AppColors.white
                : AppColors.ink;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: tile == null
                      ? const SizedBox.shrink()
                      : Text(
                          '${tile.value}',
                          key: ValueKey<int>(tile.id),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: foregroundColor,
                                fontSize: tile.value >= 1024 ? 28 : 34,
                              ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _tileColor(int? value) {
    return switch (value) {
      null => AppColors.white.withValues(alpha: 0.5),
      2 => AppColors.sky,
      4 => AppColors.butter,
      8 => AppColors.melon,
      16 => AppColors.coral,
      32 => const Color(0xFFD98557),
      64 => const Color(0xFFCB6D4A),
      128 => const Color(0xFFE5C76B),
      256 => const Color(0xFFD7B95D),
      512 => const Color(0xFFC9AA4F),
      1024 => AppColors.blueberry,
      _ => AppColors.lagoon,
    };
  }
}
