import 'dice_set.dart';
import 'score_calculator.dart';
import 'score_category.dart';

class YahtzeeSession {
  YahtzeeSession({
    required this.roundIndex,
    required this.rerollsUsed,
    required this.diceSet,
    required Map<ScoreCategory, int?> scoreCard,
    required this.extraYahtzeeCount,
  }) : scoreCard = Map<ScoreCategory, int?>.unmodifiable(scoreCard);

  factory YahtzeeSession.newGame({required List<int> initialRoll}) {
    return YahtzeeSession(
      roundIndex: 1,
      rerollsUsed: 0,
      diceSet: DiceSet(
        values: List<int>.unmodifiable(initialRoll),
        held: List<bool>.filled(5, false),
      ),
      scoreCard: {for (final category in ScoreCategory.values) category: null},
      extraYahtzeeCount: 0,
    );
  }

  final int roundIndex;
  final int rerollsUsed;
  final DiceSet diceSet;
  final Map<ScoreCategory, int?> scoreCard;
  final int extraYahtzeeCount;

  bool get isFinished => scoreCard.values.every((score) => score != null);

  int get upperSectionSubtotal =>
      ScoreCalculator.calculateUpperSectionSubtotal(scoreCard);

  int get upperSectionBonus =>
      ScoreCalculator.calculateUpperSectionBonus(upperSectionSubtotal);

  int get totalScore => ScoreCalculator.calculateTotal(
    scoreCard: scoreCard,
    extraYahtzeeCount: extraYahtzeeCount,
  );

  Iterable<ScoreCategory> get remainingCategories => scoreCard.entries
      .where((entry) => entry.value == null)
      .map((entry) => entry.key);

  int previewScoreFor(ScoreCategory category) {
    return ScoreCalculator.scoreCategory(category, diceSet.values);
  }

  YahtzeeSession copyWith({
    int? roundIndex,
    int? rerollsUsed,
    DiceSet? diceSet,
    Map<ScoreCategory, int?>? scoreCard,
    int? extraYahtzeeCount,
  }) {
    return YahtzeeSession(
      roundIndex: roundIndex ?? this.roundIndex,
      rerollsUsed: rerollsUsed ?? this.rerollsUsed,
      diceSet: diceSet ?? this.diceSet,
      scoreCard: scoreCard ?? this.scoreCard,
      extraYahtzeeCount: extraYahtzeeCount ?? this.extraYahtzeeCount,
    );
  }
}
