import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../domain/score_category.dart';
import 'controllers/yahtzee_game_controller.dart';
import 'controllers/yahtzee_game_state.dart';
import 'widgets/animated_die.dart';
import 'widgets/score_category_row.dart';
import 'yahtzee_result_screen.dart';

class YahtzeeScreen extends ConsumerStatefulWidget {
  const YahtzeeScreen({super.key});

  @override
  ConsumerState<YahtzeeScreen> createState() => _YahtzeeScreenState();
}

class _YahtzeeScreenState extends ConsumerState<YahtzeeScreen> {
  bool _resultPushed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen<YahtzeeGameState>(yahtzeeGameProvider, (previous, next) {
      if (next.errorMessage case final message?) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_localizedError(l10n, message))));
        ref.read(yahtzeeGameProvider.notifier).clearError();
      }

      if (!_resultPushed && next.session.isFinished) {
        _resultPushed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            AppRouter.yahtzeeResultRoute,
            arguments: YahtzeeResultData(
              finalScore: next.session.totalScore,
              upperSectionBonus: next.session.upperSectionBonus,
              extraYahtzeeBonus: next.session.extraYahtzeeCount * 100,
            ),
          );
        });
      }
    });

    final state = ref.watch(yahtzeeGameProvider);
    final notifier = ref.read(yahtzeeGameProvider.notifier);

    return ClayScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              ClayButton(
                label: l10n.back,
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.ink,
              ),
              const Spacer(),
              ClayButton(
                label: l10n.newRun,
                icon: Icons.replay_rounded,
                onPressed: state.isRolling ? null : notifier.restart,
                backgroundColor: AppColors.butter,
                foregroundColor: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TopSummary(state: state),
          const SizedBox(height: 18),
          ClayPanel(
            backgroundColor: AppColors.white.withValues(alpha: 0.92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.diceTray,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.diceTrayHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (
                      var index = 0;
                      index < state.session.diceSet.values.length;
                      index++
                    )
                      AnimatedDie(
                        key: ValueKey('die-$index-${state.rollToken}'),
                        value: state.session.diceSet.values[index],
                        previousValue: state.previousDiceValues?[index],
                        held: state.session.diceSet.held[index],
                        isRolling: state.rollingIndices.contains(index),
                        rollToken: state.rollToken,
                        twistSeed: index + state.rollToken,
                        onTap: state.isRolling
                            ? null
                            : () => notifier.toggleHold(index),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.rerollsUsed(state.session.rerollsUsed, 2),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ClayButton(
                      label: state.session.rerollsUsed >= 2
                          ? l10n.noRerollsLeft
                          : l10n.rerollDice,
                      icon: Icons.casino_rounded,
                      onPressed:
                          state.isRolling || state.session.rerollsUsed >= 2
                          ? null
                          : () => notifier.reroll(),
                      backgroundColor: AppColors.lagoon,
                      foregroundColor: AppColors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ClayPanel(
            backgroundColor: AppColors.white.withValues(alpha: 0.94),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scoreSheet,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.scoreSheetHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                for (final category in ScoreCategory.values) ...[
                  ScoreCategoryRow(
                    category: category,
                    assignedScore: state.session.scoreCard[category],
                    previewScore: state.session.previewScoreFor(category),
                    enabled:
                        !state.isRolling &&
                        state.session.scoreCard[category] == null,
                    onTap: () => notifier.assignCategory(category),
                  ),
                  if (category != ScoreCategory.values.last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ScoreBreakdown(state: state),
        ],
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({required this.state});

  final YahtzeeGameState state;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yahtzeeRun, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          Text(
            context.l10n.roundLabel(state.session.roundIndex.clamp(1, 13), 13),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.coral),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricBubble(
                label: context.l10n.total,
                value: '${state.session.totalScore}',
                color: AppColors.melon,
              ),
              const SizedBox(width: 12),
              _MetricBubble(
                label: context.l10n.upperBonus,
                value: '${state.session.upperSectionBonus}',
                color: AppColors.butter,
              ),
              const SizedBox(width: 12),
              _MetricBubble(
                label: context.l10n.extraYahtzeeShort,
                value: '${state.session.extraYahtzeeCount * 100}',
                color: AppColors.mintCream,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
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
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.state});

  final YahtzeeGameState state;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.scoreSnapshot, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _ScoreLine(
            label: context.l10n.upperSectionSubtotal,
            value: '${state.session.upperSectionSubtotal}',
          ),
          const SizedBox(height: 8),
          _ScoreLine(
            label: context.l10n.upperSectionBonus,
            value: '${state.session.upperSectionBonus}',
          ),
          const SizedBox(height: 8),
          _ScoreLine(
            label: context.l10n.extraYahtzeeBonus,
            value: '${state.session.extraYahtzeeCount * 100}',
          ),
          const SizedBox(height: 8),
          _ScoreLine(
            label: context.l10n.runningTotal,
            value: '${state.session.totalScore}',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

String _localizedError(AppLocalizations l10n, String message) {
  if (message.startsWith('Category ') && message.endsWith(' has already been used.')) {
    final categoryName = message
        .replaceFirst('Category ', '')
        .replaceFirst(' has already been used.', '');
    final localizedCategory = l10n.categoryLabel(categoryName);
    return l10n.isChinese
        ? '$localizedCategory 已经用过了。'
        : 'Category $localizedCategory has already been used.';
  }

  return switch (message) {
    'Cannot toggle hold state after the game is finished.' =>
      l10n.runComplete,
    'Cannot reroll after the game is finished.' => l10n.runComplete,
    'No rerolls remain for the current round.' => l10n.noRerollsLeft,
    'Cannot assign a category after the game is finished.' => l10n.runComplete,
    _ => message,
  };
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(value, style: textStyle),
      ],
    );
  }
}
