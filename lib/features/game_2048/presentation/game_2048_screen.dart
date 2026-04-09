import 'dart:ui';

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
import 'controllers/game_2048_controller.dart';
import 'controllers/game_2048_state.dart';
import 'game_2048_result_screen.dart';
import 'widgets/animated_tile_board.dart';

class Game2048Screen extends ConsumerStatefulWidget {
  const Game2048Screen({super.key});

  @override
  ConsumerState<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends ConsumerState<Game2048Screen>
    with SingleTickerProviderStateMixin {
  ProviderSubscription<Game2048State>? _subscription;
  late final AnimationController _lossOverlayController;

  @override
  void initState() {
    super.initState();
    _lossOverlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _subscription = ref.listenManual<Game2048State>(
      game2048ControllerProvider,
      (previous, next) {
        if (previous?.showLossOverlay == false && next.showLossOverlay) {
          _lossOverlayController.forward(from: 0);
        } else if (previous?.showLossOverlay == true && !next.showLossOverlay) {
          _lossOverlayController.value = 0;
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _lossOverlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      AnimatedBuilder(
                        animation: _lossOverlayController,
                        builder: (context, child) {
                          return AnimatedTileBoard(
                            board: state.board,
                            enabled:
                                !state.showLossOverlay && !state.showWinOverlay,
                            gameOverProgress: state.showLossOverlay
                                ? _lossOverlayController.value
                                : 0,
                            onSlide: controller.slide,
                          );
                        },
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
                child: _GameOverlay(
                  title: state.showWinOverlay ? l10n.hit2048 : l10n.noMovesLeft,
                  message: state.showWinOverlay
                      ? l10n.hit2048Hint
                      : l10n.noMovesLeftHint,
                  isLoss: state.showLossOverlay,
                  animation: _lossOverlayController,
                  onKeepGoing: state.showWinOverlay
                      ? controller.continueAfterWin
                      : null,
                  onSaveResult: () => _finishRun(context, state.board),
                  onNewBoard: controller.newGame,
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

class _GameOverlay extends StatelessWidget {
  const _GameOverlay({
    required this.title,
    required this.message,
    required this.isLoss,
    required this.animation,
    required this.onSaveResult,
    required this.onNewBoard,
    this.onKeepGoing,
  });

  final String title;
  final String message;
  final bool isLoss;
  final Animation<double> animation;
  final VoidCallback? onKeepGoing;
  final VoidCallback onSaveResult;
  final VoidCallback onNewBoard;

  @override
  Widget build(BuildContext context) {
    final progress = isLoss ? animation.value : 1.0;
    final overlayAlpha = isLoss ? lerpDouble(0.08, 0.26, progress)! : 0.2;
    final blurSigma = isLoss ? lerpDouble(0, 10, progress)! : 4.0;
    final cardScale = isLoss
        ? lerpDouble(0.92, 1, Curves.easeOutBack.transform(progress))!
        : 1.0;
    final cardOffset = isLoss
        ? lerpDouble(26, 0, Curves.easeOutCubic.transform(progress))!
        : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: overlayAlpha),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, cardOffset),
            child: Transform.scale(
              scale: cardScale,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClayPanel(
                  backgroundColor: AppColors.white.withValues(alpha: 0.97),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (onKeepGoing != null)
                            ClayButton(
                              label: context.l10n.keepGoing,
                              icon: Icons.trending_up_rounded,
                              onPressed: onKeepGoing,
                              backgroundColor: AppColors.blueberry,
                              foregroundColor: AppColors.white,
                            ),
                          ClayButton(
                            label: context.l10n.saveResult,
                            icon: Icons.emoji_events_rounded,
                            onPressed: onSaveResult,
                            backgroundColor: AppColors.coral,
                            foregroundColor: AppColors.white,
                          ),
                          ClayButton(
                            label: context.l10n.newBoard,
                            icon: Icons.refresh_rounded,
                            onPressed: onNewBoard,
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
    return ClayPanel(
      backgroundColor: color,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
