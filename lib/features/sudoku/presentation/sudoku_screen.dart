import 'dart:ui' show lerpDouble;

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

class _SudokuScreenState extends ConsumerState<SudokuScreen>
    with SingleTickerProviderStateMixin {
  ProviderSubscription<SudokuState>? _stateSubscription;
  late final AnimationController _completionController;
  bool _navigatingAway = false;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    );
    _stateSubscription = ref.listenManual<SudokuState>(
      sudokuControllerProvider,
      (previous, next) {
        if (!_navigatingAway &&
            previous?.isComplete == false &&
            next.isComplete) {
          _navigatingAway = true;
          _completionController.forward(from: 0);
          Future<void>.delayed(const Duration(milliseconds: 860), () {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pushReplacementNamed(
              AppRouter.sudokuResultRoute,
              arguments: SudokuResultData(
                difficulty: next.difficulty,
                elapsedSeconds: next.elapsedSeconds,
                mistakes: next.mistakes,
              ),
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    _completionController.dispose();
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
                      completionProgress: _completionController.value,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _NumberPad(
                    state: state,
                    onDigitPressed: controller.placeDigit,
                    onErasePressed: controller.eraseSelected,
                    onHintPressed: controller.useHint,
                    onNotesTogglePressed: controller.toggleNoteMode,
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
  const _SudokuGrid({
    required this.state,
    required this.onCellTap,
    required this.completionProgress,
  });

  final SudokuState state;
  final ValueChanged<int> onCellTap;
  final double completionProgress;

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
          final isRelated = state.isRelatedToSelected(index);
          final sharesSelectedValue = state.sharesValueWithSelected(index);
          final celebration = _celebrationProgress(index);

          return GestureDetector(
            onTap: () => onCellTap(index),
            child: Transform.scale(
              scale: lerpDouble(1, 1.08, celebration)!,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isError
                      ? AppColors.coral.withValues(alpha: 0.22)
                      : celebration > 0
                      ? Color.lerp(
                          AppColors.white,
                          AppColors.butter.withValues(alpha: 0.84),
                          celebration,
                        )
                      : isSelected
                      ? AppColors.lagoon.withValues(alpha: 0.2)
                      : sharesSelectedValue
                      ? AppColors.butter.withValues(alpha: 0.3)
                      : isRelated
                      ? AppColors.sky.withValues(alpha: 0.72)
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
                  child: cell.value == null
                      ? _NoteMatrix(notes: cell.notes)
                      : Text(
                          '${cell.value}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: cell.isClue
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isError
                                    ? AppColors.coral
                                    : cell.isClue
                                    ? AppColors.ink
                                    : AppColors.blueberry,
                              ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _celebrationProgress(int index) {
    if (completionProgress <= 0) {
      return 0;
    }

    final row = index ~/ 9;
    final col = index % 9;
    final start = ((row + col) / 16) * 0.58;
    final normalized = ((completionProgress - start) / 0.28).clamp(0, 1);
    return Curves.easeOutBack.transform(normalized.toDouble());
  }
}

class _NoteMatrix extends StatelessWidget {
  const _NoteMatrix({required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        children: [
          for (var digit = 1; digit <= 9; digit++)
            Center(
              child: Text(
                notes.contains(digit) ? '$digit' : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.state,
    required this.onDigitPressed,
    required this.onErasePressed,
    required this.onHintPressed,
    required this.onNotesTogglePressed,
  });

  final SudokuState state;
  final ValueChanged<int> onDigitPressed;
  final VoidCallback onErasePressed;
  final VoidCallback onHintPressed;
  final VoidCallback onNotesTogglePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  onPressed:
                      !state.isNoteMode &&
                          state.remainingCountForDigit(digit) == 0
                      ? null
                      : () => onDigitPressed(digit),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    backgroundColor: state.remainingCountForDigit(digit) == 0
                        ? AppColors.white.withValues(alpha: 0.46)
                        : AppColors.white,
                    side: BorderSide(
                      color: state.isNoteMode
                          ? AppColors.lagoon.withValues(alpha: 0.32)
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$digit',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontSize: 16,
                              height: 1,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.digitRemainingShort(
                          state.remainingCountForDigit(digit),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 8.5,
                          height: 1,
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ClayButton(
              label: l10n.hint,
              icon: Icons.lightbulb_outline_rounded,
              onPressed: onHintPressed,
              backgroundColor: AppColors.butter,
              foregroundColor: AppColors.ink,
            ),
            ClayButton(
              label: state.isNoteMode ? l10n.noteModeOn : l10n.noteModeOff,
              icon: Icons.edit_note_rounded,
              onPressed: onNotesTogglePressed,
              backgroundColor: state.isNoteMode
                  ? AppColors.lagoon
                  : AppColors.white,
              foregroundColor: state.isNoteMode
                  ? AppColors.white
                  : AppColors.ink,
            ),
            ClayButton(
              label: l10n.erase,
              icon: Icons.backspace_outlined,
              onPressed: onErasePressed,
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.ink,
            ),
          ],
        ),
      ],
    );
  }
}
