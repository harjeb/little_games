import 'dice_set.dart';
import 'score_calculator.dart';
import 'score_category.dart';
import 'yahtzee_session.dart';

typedef DiceRoller = List<int> Function(int count);

class YahtzeeSessionController {
  const YahtzeeSessionController({required DiceRoller rollDice})
    : _rollDice = rollDice;

  final DiceRoller _rollDice;

  YahtzeeSession startGame() {
    return YahtzeeSession.newGame(initialRoll: _rollDice(5));
  }

  YahtzeeSession toggleHold(YahtzeeSession session, int dieIndex) {
    _validateDieIndex(dieIndex);
    if (session.isFinished) {
      throw StateError('Cannot toggle hold state after the game is finished.');
    }

    final updatedHeld = List<bool>.of(session.diceSet.held);
    updatedHeld[dieIndex] = !updatedHeld[dieIndex];

    return session.copyWith(
      diceSet: session.diceSet.copyWith(
        held: List<bool>.unmodifiable(updatedHeld),
      ),
    );
  }

  YahtzeeSession reroll(YahtzeeSession session) {
    if (session.isFinished) {
      throw StateError('Cannot reroll after the game is finished.');
    }
    if (session.rerollsUsed >= 2) {
      throw StateError('No rerolls remain for the current round.');
    }

    final rerollCount = session.diceSet.held.where((isHeld) => !isHeld).length;
    final rerolledValues = _rollDice(rerollCount);
    final updatedValues = <int>[];
    var rerollIndex = 0;

    for (var index = 0; index < session.diceSet.values.length; index++) {
      if (session.diceSet.held[index]) {
        updatedValues.add(session.diceSet.values[index]);
      } else {
        updatedValues.add(rerolledValues[rerollIndex]);
        rerollIndex++;
      }
    }

    return session.copyWith(
      rerollsUsed: session.rerollsUsed + 1,
      diceSet: DiceSet(
        values: List<int>.unmodifiable(updatedValues),
        held: List<bool>.unmodifiable(session.diceSet.held),
      ),
    );
  }

  YahtzeeSession assignCategory(
    YahtzeeSession session,
    ScoreCategory category,
  ) {
    if (session.isFinished) {
      throw StateError('Cannot assign a category after the game is finished.');
    }
    if (session.scoreCard[category] != null) {
      throw StateError('Category ${category.label} has already been used.');
    }

    final scoredValue = ScoreCalculator.scoreCategory(
      category,
      session.diceSet.values,
    );
    final nextScoreCard = Map<ScoreCategory, int?>.of(session.scoreCard)
      ..[category] = scoredValue;
    final earnedExtraYahtzee = _shouldAwardExtraYahtzee(session);
    final nextExtraYahtzeeCount =
        session.extraYahtzeeCount + (earnedExtraYahtzee ? 1 : 0);
    final isGameFinished = nextScoreCard.values.every((score) => score != null);

    if (isGameFinished) {
      return session.copyWith(
        scoreCard: nextScoreCard,
        extraYahtzeeCount: nextExtraYahtzeeCount,
      );
    }

    return YahtzeeSession(
      roundIndex: session.roundIndex + 1,
      rerollsUsed: 0,
      diceSet: DiceSet(
        values: List<int>.unmodifiable(_rollDice(5)),
        held: List<bool>.filled(5, false),
      ),
      scoreCard: nextScoreCard,
      extraYahtzeeCount: nextExtraYahtzeeCount,
    );
  }

  bool _shouldAwardExtraYahtzee(YahtzeeSession session) {
    final hasValidYahtzeeAlready =
        (session.scoreCard[ScoreCategory.yahtzee] ?? 0) >=
        ScoreCalculator.yahtzeeScore;
    final rolledAnotherYahtzee =
        ScoreCalculator.scoreCategory(
          ScoreCategory.yahtzee,
          session.diceSet.values,
        ) ==
        ScoreCalculator.yahtzeeScore;

    return hasValidYahtzeeAlready && rolledAnotherYahtzee;
  }

  void _validateDieIndex(int dieIndex) {
    if (dieIndex < 0 || dieIndex >= 5) {
      throw RangeError.index(dieIndex, List<int>.filled(5, 0), 'dieIndex');
    }
  }
}
