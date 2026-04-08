import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/yahtzee/domain/score_calculator.dart';
import 'package:flutter_demo/features/yahtzee/domain/score_category.dart';
import 'package:flutter_demo/features/yahtzee/domain/yahtzee_session_controller.dart';

void main() {
  group('YahtzeeSessionController', () {
    test('starts a new game with the first rolled hand', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 2, 3, 4, 5],
        ]),
      );

      final session = controller.startGame();

      expect(session.roundIndex, 1);
      expect(session.rerollsUsed, 0);
      expect(session.diceSet.values, [1, 2, 3, 4, 5]);
      expect(session.diceSet.held, [false, false, false, false, false]);
      expect(session.remainingCategories.length, 13);
    });

    test('toggles a die hold state', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 2, 3, 4, 5],
        ]),
      );
      final session = controller.startGame();

      final updatedSession = controller.toggleHold(session, 2);

      expect(updatedSession.diceSet.held, [false, false, true, false, false]);
    });

    test('rerolls only dice that are not held', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 2, 3, 4, 5],
          [6, 6, 6],
        ]),
      );
      final session = controller.startGame();
      final heldSession = controller
          .toggleHold(session, 0)
          .let((value) => controller.toggleHold(value, 2));

      final rerolled = controller.reroll(heldSession);

      expect(rerolled.rerollsUsed, 1);
      expect(rerolled.diceSet.values, [1, 6, 3, 6, 6]);
      expect(rerolled.diceSet.held, [true, false, true, false, false]);
    });

    test('prevents a third reroll in the same round', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 2, 3, 4, 5],
          [6, 6, 6, 6, 6],
          [5, 5, 5, 5, 5],
        ]),
      );
      final session = controller.startGame();
      final afterFirst = controller.reroll(session);
      final afterSecond = controller.reroll(afterFirst);

      expect(() => controller.reroll(afterSecond), throwsStateError);
    });

    test('assigns a category, scores it, and advances to the next round', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 1, 1, 4, 6],
          [2, 3, 4, 5, 6],
        ]),
      );
      final session = controller.startGame();

      final updated = controller.assignCategory(session, ScoreCategory.aces);

      expect(updated.scoreCard[ScoreCategory.aces], 3);
      expect(updated.roundIndex, 2);
      expect(updated.rerollsUsed, 0);
      expect(updated.diceSet.values, [2, 3, 4, 5, 6]);
      expect(updated.diceSet.held, [false, false, false, false, false]);
    });

    test('prevents reusing a category', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls([
          [1, 1, 1, 4, 6],
          [2, 3, 4, 5, 6],
        ]),
      );
      final session = controller.startGame();
      final updated = controller.assignCategory(session, ScoreCategory.aces);

      expect(
        () => controller.assignCategory(updated, ScoreCategory.aces),
        throwsStateError,
      );
    });

    test('finishes the game after the thirteenth category is assigned', () {
      final controller = YahtzeeSessionController(
        rollDice: _queueRolls(
          List<List<int>>.generate(
            ScoreCategory.values.length,
            (_) => [1, 1, 1, 1, 1],
          ),
        ),
      );
      var session = controller.startGame();

      for (final category in ScoreCategory.values) {
        session = controller.assignCategory(session, category);
      }

      expect(session.isFinished, isTrue);
      expect(session.remainingCategories, isEmpty);
    });

    test(
      'tracks extra yahtzee bonus after a valid yahtzee is already scored',
      () {
        final controller = YahtzeeSessionController(
          rollDice: _queueRolls([
            [6, 6, 6, 6, 6],
            [5, 5, 5, 5, 5],
            [1, 2, 3, 4, 5],
          ]),
        );
        final started = controller.startGame();
        final afterYahtzee = controller.assignCategory(
          started,
          ScoreCategory.yahtzee,
        );

        final afterExtraYahtzee = controller.assignCategory(
          afterYahtzee,
          ScoreCategory.chance,
        );

        expect(afterExtraYahtzee.extraYahtzeeCount, 1);
        expect(
          afterExtraYahtzee.totalScore,
          ScoreCalculator.yahtzeeScore +
              25 +
              ScoreCalculator.extraYahtzeeBonusValue,
        );
      },
    );
  });
}

extension<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}

DiceRoller _queueRolls(List<List<int>> queuedRolls) {
  final pendingRolls = List<List<int>>.of(queuedRolls);

  return (count) {
    if (pendingRolls.isEmpty) {
      throw StateError('No queued roll values remain.');
    }

    final nextRoll = pendingRolls.removeAt(0);
    if (nextRoll.length != count) {
      throw StateError(
        'Expected a queued roll with $count values, got ${nextRoll.length}.',
      );
    }

    return nextRoll;
  };
}
