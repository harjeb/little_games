import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/clay_button.dart';
import '../../../core/widgets/clay_panel.dart';
import '../../../core/widgets/clay_scaffold.dart';
import '../domain/sudoku_difficulty.dart';
import 'controllers/sudoku_controller.dart';
import 'controllers/sudoku_state.dart';
import 'sudoku_result_screen.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  ProviderSubscription<SudokuState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual<SudokuState>(
      sudokuControllerProvider,
      (previous, next) {
        if (previous?.isComplete == false && next.isComplete) {
          Navigator.of(context).pushReplacementNamed(
            AppRouter.sudokuResultRoute,
            arguments: SudokuResultData(
              difficulty: next.difficulty,
              elapsedSeconds: next.elapsedSeconds,
              mistakes: next.mistakes,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(sudokuControllerProvider);
    final controller = ref.read(sudokuControllerProvider.notifier);

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
                    l10n.sudokuTitle,
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
                    l10n.sudokuHint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final difficulty in SudokuDifficulty.values)
                        ChoiceChip(
                          label: Text(difficulty.label(l10n)),
                          selected: state.difficulty == difficulty,
                          onSelected: (_) =>
                              controller.startNewGame(difficulty),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: l10n.time,
                          value: _formatDuration(state.elapsedSeconds),
                          color: AppColors.butter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: l10n.mistakes,
                          value: '${state.mistakes}',
                          color: AppColors.mintCream,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _SudokuGrid(
                      state: state,
                      onCellTap: controller.selectCell,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _NumberPad(
                    onDigitPressed: controller.placeDigit,
                    onErasePressed: controller.eraseSelected,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ClayButton(
                        label: l10n.newPuzzle,
                        icon: Icons.refresh_rounded,
                        onPressed: controller.startNewGame,
                        backgroundColor: AppColors.lagoon,
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

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _SudokuGrid extends StatelessWidget {
  const _SudokuGrid({required this.state, required this.onCellTap});

  final SudokuState state;
  final ValueChanged<int> onCellTap;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      backgroundColor: AppColors.white.withValues(alpha: 0.96),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final cell = state.cellAt(row, col);
          final isSelected = state.selectedIndex == index;
          final isError = state.lastErrorIndex == index;

          return GestureDetector(
            onTap: () => onCellTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.coral.withValues(alpha: 0.22)
                    : isSelected
                    ? AppColors.lagoon.withValues(alpha: 0.2)
                    : cell.isClue
                    ? AppColors.sky
                    : AppColors.white,
                border: Border(
                  top: BorderSide(width: row % 3 == 0 ? 2.4 : 0.8),
                  left: BorderSide(width: col % 3 == 0 ? 2.4 : 0.8),
                  right: BorderSide(width: col == 8 ? 2.4 : 0.8),
                  bottom: BorderSide(width: row == 8 ? 2.4 : 0.8),
                ),
              ),
              child: Center(
                child: Text(
                  cell.value?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: cell.isClue ? FontWeight.w700 : FontWeight.w500,
                    color: isError
                        ? AppColors.coral
                        : cell.isClue
                        ? AppColors.ink
                        : AppColors.blueberry,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.onDigitPressed,
    required this.onErasePressed,
  });

  final ValueChanged<int> onDigitPressed;
  final VoidCallback onErasePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var digit = 1; digit <= 9; digit++)
              SizedBox(
                width: 66,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => onDigitPressed(digit),
                  child: Text('$digit'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClayButton(
          label: context.l10n.erase,
          icon: Icons.backspace_outlined,
          onPressed: onErasePressed,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
        ),
      ],
    );
  }
}
