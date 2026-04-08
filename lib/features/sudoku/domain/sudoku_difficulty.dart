import '../../../core/constants/game_ids.dart';
import '../../../app/localization/app_localizations.dart';

enum SudokuDifficulty {
  easy(GameIds.sudokuEasy),
  medium(GameIds.sudokuMedium),
  hard(GameIds.sudokuHard);

  const SudokuDifficulty(this.gameId);

  final String gameId;

  String label(AppLocalizations l10n) => switch (this) {
    SudokuDifficulty.easy => l10n.easy,
    SudokuDifficulty.medium => l10n.medium,
    SudokuDifficulty.hard => l10n.hard,
  };
}
