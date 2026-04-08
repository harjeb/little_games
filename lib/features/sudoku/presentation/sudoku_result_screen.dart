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
import '../domain/sudoku_difficulty.dart';

class SudokuResultData {
  const SudokuResultData({
    required this.difficulty,
    required this.elapsedSeconds,
    required this.mistakes,
  });

  final SudokuDifficulty difficulty;
  final int elapsedSeconds;
  final int mistakes;
}

class SudokuResultScreen extends ConsumerStatefulWidget {
  const SudokuResultScreen({super.key, required this.result});

  final SudokuResultData result;

  @override
  ConsumerState<SudokuResultScreen> createState() => _SudokuResultScreenState();
}

class _SudokuResultScreenState extends ConsumerState<SudokuResultScreen> {
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
    final gameId = widget.result.difficulty.gameId;
    final previousBest = await repository.getBestScore(gameId);
    final isNewRecord =
        previousBest == null ||
        widget.result.elapsedSeconds < previousBest.score;

    if (isNewRecord) {
      await repository.submitScore(
        gameId,
        widget.result.elapsedSeconds,
        DateTime.now().toUtc(),
        higherIsBetter: false,
      );
    }

    final updatedBest = await repository.getBestScore(gameId);
    ref.invalidate(bestScoreProvider(gameId));

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
    final difficultyLabel = widget.result.difficulty.label(l10n);

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
                        _isNewRecord ? l10n.cleanSweep : l10n.puzzleSolved,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.difficultySolvedIn(
                          difficultyLabel,
                          _formatDuration(widget.result.elapsedSeconds),
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.lagoon,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ResultChip(
                            label: l10n.mistakesChip(widget.result.mistakes),
                            color: AppColors.butter,
                          ),
                          _ResultChip(
                            label: l10n.bestTimeChip(
                              _formatDuration(
                                _currentBest?.score ??
                                    widget.result.elapsedSeconds,
                              ),
                            ),
                            color: AppColors.mintCream,
                          ),
                          _ResultChip(
                            label: _isNewRecord
                                ? l10n.newBest
                                : l10n.keepSharpening,
                            color: AppColors.melon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.sudokuResultMessage(
                          isNewRecord: _isNewRecord,
                          difficulty: difficultyLabel,
                          previousBestDuration: _previousBest == null
                              ? null
                              : _formatDuration(_previousBest!.score),
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
                            ).pushReplacementNamed(AppRouter.sudokuRoute),
                            backgroundColor: AppColors.lagoon,
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

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
