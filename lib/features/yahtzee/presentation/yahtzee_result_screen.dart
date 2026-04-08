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

class YahtzeeResultData {
  const YahtzeeResultData({
    required this.finalScore,
    required this.upperSectionBonus,
    required this.extraYahtzeeBonus,
  });

  final int finalScore;
  final int upperSectionBonus;
  final int extraYahtzeeBonus;
}

class YahtzeeResultScreen extends ConsumerStatefulWidget {
  const YahtzeeResultScreen({super.key, required this.result});

  final YahtzeeResultData result;

  @override
  ConsumerState<YahtzeeResultScreen> createState() =>
      _YahtzeeResultScreenState();
}

class _YahtzeeResultScreenState extends ConsumerState<YahtzeeResultScreen> {
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
    final previousBest = await repository.getBestScore(GameIds.yahtzee);
    final isNewRecord =
        previousBest == null || widget.result.finalScore > previousBest.score;

    if (isNewRecord) {
      await repository.submitScore(
        GameIds.yahtzee,
        widget.result.finalScore,
        DateTime.now().toUtc(),
      );
    }

    final updatedBest = await repository.getBestScore(GameIds.yahtzee);
    ref.invalidate(bestScoreProvider(GameIds.yahtzee));

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
                        _isNewRecord
                            ? l10n.yahtzeeFreshHighScore
                            : l10n.runComplete,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.finalScoreLabel(widget.result.finalScore),
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
                            label: l10n.upperBonusChip(
                              widget.result.upperSectionBonus,
                            ),
                            color: AppColors.butter,
                          ),
                          _ResultChip(
                            label: l10n.extraYahtzeeChip(
                              widget.result.extraYahtzeeBonus,
                            ),
                            color: AppColors.mintCream,
                          ),
                          _ResultChip(
                            label: l10n.bestChip(
                              _currentBest?.score ?? widget.result.finalScore,
                            ),
                            color: AppColors.melon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.yahtzeeResultMessage(
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
                            ).pushReplacementNamed(AppRouter.yahtzeeRoute),
                            backgroundColor: AppColors.coral,
                            foregroundColor: AppColors.white,
                          ),
                          ClayButton(
                            label: l10n.backHome,
                            icon: Icons.home_rounded,
                            onPressed: () => Navigator.of(context).pop(),
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
