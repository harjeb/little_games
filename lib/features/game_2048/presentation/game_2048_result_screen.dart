import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/game_ids.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../../leaderboard/domain/best_score_record.dart';
import '../../leaderboard/leaderboard_providers.dart';

class Game2048ResultData {
  const Game2048ResultData({
    required this.finalScore,
    required this.maxTile,
    required this.didReach2048,
  });

  final int finalScore;
  final int maxTile;
  final bool didReach2048;
}

class Game2048ResultScreen extends ConsumerStatefulWidget {
  const Game2048ResultScreen({super.key, required this.result});

  final Game2048ResultData result;

  @override
  ConsumerState<Game2048ResultScreen> createState() =>
      _Game2048ResultScreenState();
}

class _Game2048ResultScreenState extends ConsumerState<Game2048ResultScreen> {
  bool _loading = true;
  bool _isNewRecord = false;
  BestScoreRecord? _previousBest;
  BestScoreRecord? _currentBest;

  @override
  void initState() {
    super.initState();
    _submitResult();
  }

  Future<void> _submitResult() async {
    final repository = ref.read(leaderboardRepositoryProvider);
    final previousBest = await repository.getBestScore(GameIds.game2048);
    final isNewRecord =
        previousBest == null || widget.result.finalScore > previousBest.score;

    if (isNewRecord) {
      await repository.submitScore(
        GameIds.game2048,
        widget.result.finalScore,
        DateTime.now().toUtc(),
      );
    }

    final updatedBest = await repository.getBestScore(GameIds.game2048);
    ref.invalidate(bestScoreProvider(GameIds.game2048));

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _isNewRecord = isNewRecord;
      _previousBest = previousBest;
      _currentBest = updatedBest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClayScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClayPanel(
            backgroundColor: AppColors.white.withValues(alpha: 0.94),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.didReach2048
                            ? l10n.reached2048
                            : l10n.boardLocked,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.finalScoreLabel(widget.result.finalScore),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.blueberry,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ResultChip(
                            label: l10n.maxTileChip(widget.result.maxTile),
                            color: AppColors.butter,
                          ),
                          _ResultChip(
                            label: l10n.bestChip(
                              _currentBest?.score ?? widget.result.finalScore,
                            ),
                            color: AppColors.mintCream,
                          ),
                          _ResultChip(
                            label:
                                _isNewRecord ? l10n.newRecord : l10n.keepClimbing,
                            color: AppColors.melon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.game2048ResultMessage(
                          isNewRecord: _isNewRecord,
                          previousBest: _previousBest?.score,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ClayButton(
                            label: l10n.playAgain,
                            icon: Icons.replay_rounded,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRouter.game2048Route),
                            backgroundColor: AppColors.blueberry,
                            foregroundColor: AppColors.white,
                          ),
                          ClayButton(
                            label: l10n.backHome,
                            icon: Icons.home_rounded,
                            onPressed: () =>
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRouter.homeRoute,
                                  (route) => false,
                                ),
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
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.ink),
      ),
    );
  }
}
