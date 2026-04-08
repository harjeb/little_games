import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_locale_controller.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/game_ids.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../../leaderboard/leaderboard_providers.dart';
import 'widgets/game_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(appLocaleProvider);
    final yahtzeeBestScore = ref.watch(bestScoreProvider(GameIds.yahtzee));
    final game2048BestScore = ref.watch(bestScoreProvider(GameIds.game2048));
    final match3Level1Best = ref.watch(
      bestScoreProvider(GameIds.match3Level(1)),
    );
    final match3Level2Best = ref.watch(
      bestScoreProvider(GameIds.match3Level(2)),
    );
    final match3Level3Best = ref.watch(
      bestScoreProvider(GameIds.match3Level(3)),
    );
    final sudokuEasyBest = ref.watch(bestScoreProvider(GameIds.sudokuEasy));
    final sudokuMediumBest = ref.watch(bestScoreProvider(GameIds.sudokuMedium));
    final sudokuHardBest = ref.watch(bestScoreProvider(GameIds.sudokuHard));

    return ClayScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ClayPanel(
            backgroundColor: AppColors.white.withValues(alpha: 0.88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.homeTagline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.languageLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('language-en'),
                      label: Text(l10n.englishLabel),
                      selected: locale.languageCode == 'en',
                      onSelected: (_) => ref
                          .read(appLocaleProvider.notifier)
                          .setLocale(const Locale('en')),
                    ),
                    ChoiceChip(
                      key: const ValueKey('language-zh'),
                      label: Text(l10n.chineseLabel),
                      selected: locale.languageCode == 'zh',
                      onSelected: (_) => ref
                          .read(appLocaleProvider.notifier)
                          .setLocale(const Locale('zh')),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FactChip(
                      label: l10n.androidFirst,
                      color: AppColors.butter,
                    ),
                    _FactChip(
                      label: l10n.singlePlayer,
                      color: AppColors.mintCream,
                    ),
                    _FactChip(label: l10n.clayUi, color: AppColors.melon),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(l10n.gameShelf, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          yahtzeeBestScore.when(
            data: (record) => GameCard(
              title: 'Yahtzee',
              description: l10n.yahtzeeDescription,
              bestScoreLabel: record?.score.toString() ?? l10n.noRecordYet,
              accentColor: AppColors.coral,
              playLabel: l10n.playYahtzee,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.yahtzeeRoute),
            ),
            error: (_, _) => GameCard(
              title: 'Yahtzee',
              description: l10n.yahtzeeDescription,
              bestScoreLabel: l10n.recordUnavailable,
              accentColor: AppColors.coral,
              playLabel: l10n.playYahtzee,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.yahtzeeRoute),
            ),
            loading: () => GameCard(
              title: 'Yahtzee',
              description: l10n.yahtzeeDescription,
              bestScoreLabel: l10n.loading,
              accentColor: AppColors.coral,
              playLabel: l10n.playYahtzee,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.yahtzeeRoute),
            ),
          ),
          const SizedBox(height: 16),
          game2048BestScore.when(
            data: (record) => GameCard(
              title: '2048',
              description: l10n.game2048Description,
              bestScoreLabel: record?.score.toString() ?? l10n.noRecordYet,
              accentColor: AppColors.blueberry,
              playLabel: l10n.play2048,
              icon: Icons.grid_4x4_rounded,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.game2048Route),
            ),
            error: (_, _) => GameCard(
              title: '2048',
              description: l10n.game2048Description,
              bestScoreLabel: l10n.recordUnavailable,
              accentColor: AppColors.blueberry,
              playLabel: l10n.play2048,
              icon: Icons.grid_4x4_rounded,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.game2048Route),
            ),
            loading: () => GameCard(
              title: '2048',
              description: l10n.game2048Description,
              bestScoreLabel: l10n.loading,
              accentColor: AppColors.blueberry,
              playLabel: l10n.play2048,
              icon: Icons.grid_4x4_rounded,
              onPlay: () =>
                  Navigator.of(context).pushNamed(AppRouter.game2048Route),
            ),
          ),
          const SizedBox(height: 16),
          GameCard(
            title: 'Match-3',
            description: l10n.match3Description,
            bestScoreLabel: _formatMatch3Shelf(
              l10n: l10n,
              level1: match3Level1Best,
              level2: match3Level2Best,
              level3: match3Level3Best,
            ),
            accentColor: AppColors.lagoon,
            playLabel: l10n.playMatch3,
            icon: Icons.auto_awesome_motion_rounded,
            onPlay: () =>
                Navigator.of(context).pushNamed(AppRouter.match3Route),
          ),
          const SizedBox(height: 16),
          GameCard(
            title: 'Sudoku',
            description: l10n.sudokuDescription,
            bestScoreLabel: _formatSudokuShelf(
              l10n: l10n,
              easy: sudokuEasyBest,
              medium: sudokuMediumBest,
              hard: sudokuHardBest,
            ),
            accentColor: AppColors.lagoon,
            playLabel: l10n.playSudoku,
            scoreLabel: l10n.bestTime,
            icon: Icons.apps_rounded,
            onPlay: () =>
                Navigator.of(context).pushNamed(AppRouter.sudokuRoute),
          ),
        ],
      ),
    );
  }

  String _formatSudokuShelf({
    required AppLocalizations l10n,
    required AsyncValue<dynamic> easy,
    required AsyncValue<dynamic> medium,
    required AsyncValue<dynamic> hard,
  }) {
    String formatRecord(AsyncValue<dynamic> value) {
      return value.when(
        data: (record) =>
            record == null ? '--' : _formatDuration(record.score as int),
        error: (_, _) => l10n.unavailable,
        loading: () => '..',
      );
    }

    return '${l10n.shortEasy} ${formatRecord(easy)} • ${l10n.shortMedium} ${formatRecord(medium)} • ${l10n.shortHard} ${formatRecord(hard)}';
  }

  String _formatMatch3Shelf({
    required AppLocalizations l10n,
    required AsyncValue<dynamic> level1,
    required AsyncValue<dynamic> level2,
    required AsyncValue<dynamic> level3,
  }) {
    String formatRecord(AsyncValue<dynamic> value) {
      return value.when(
        data: (record) => record == null ? '--' : '${record.score}',
        error: (_, _) => l10n.unavailable,
        loading: () => '..',
      );
    }

    return 'L1 ${formatRecord(level1)} • L2 ${formatRecord(level2)} • L3 ${formatRecord(level3)}';
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label, required this.color});

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
