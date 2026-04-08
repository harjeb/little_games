import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../../leaderboard/domain/best_score_record.dart';
import '../../leaderboard/leaderboard_providers.dart';
import '../domain/match3_level_config.dart';

class Match3ResultData {
  const Match3ResultData({
    required this.level,
    required this.score,
    required this.didWin,
  });

  final Match3LevelConfig level;
  final int score;
  final bool didWin;
}

class Match3ResultScreen extends ConsumerStatefulWidget {
  const Match3ResultScreen({super.key, required this.result});

  final Match3ResultData result;

  @override
  ConsumerState<Match3ResultScreen> createState() => _Match3ResultScreenState();
}

class _Match3ResultScreenState extends ConsumerState<Match3ResultScreen> {
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
    final gameId = widget.result.level.gameId;
    final previousBest = await repository.getBestScore(gameId);
    final isNewRecord =
        previousBest == null || widget.result.score > previousBest.score;

    if (isNewRecord) {
      await repository.submitScore(
        gameId,
        widget.result.score,
        DateTime.now().toUtc(),
      );
    }

    final currentBest = await repository.getBestScore(gameId);
    ref.invalidate(bestScoreProvider(gameId));

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _isNewRecord = isNewRecord;
      _previousBest = previousBest;
      _currentBest = currentBest;
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
            backgroundColor: AppColors.white.withValues(alpha: 0.95),
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
                        widget.result.didWin
                            ? l10n.match3Victory
                            : l10n.match3OutOfMoves,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.match3LevelLabel(widget.result.level.id),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.coral,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ResultChip(
                            label: l10n.finalScoreLabel(widget.result.score),
                            color: AppColors.butter,
                          ),
                          _ResultChip(
                            label: l10n.bestChip(
                              _currentBest?.score ?? widget.result.score,
                            ),
                            color: AppColors.mintCream,
                          ),
                          _ResultChip(
                            label: _isNewRecord
                                ? l10n.newRecord
                                : l10n.keepClimbing,
                            color: AppColors.melon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.match3ResultMessage(
                          isNewRecord: _isNewRecord,
                          previousBest: _previousBest?.score,
                          didWin: widget.result.didWin,
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
                            ).pushReplacementNamed(AppRouter.match3Route),
                            backgroundColor: AppColors.coral,
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
