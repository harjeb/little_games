import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/features/yahtzee/domain/score_calculator.dart';
import 'package:flutter_demo/features/yahtzee/domain/score_category.dart';

void main() {
  group('ScoreCalculator.scoreCategory', () {
    test('scores upper section categories correctly', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.aces, [1, 1, 3, 4, 6]),
        2,
      );
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.sixes, [6, 6, 6, 1, 2]),
        18,
      );
    });

    test('scores three of a kind with the full dice sum', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.threeOfAKind, [
          3,
          3,
          3,
          4,
          5,
        ]),
        18,
      );
    });

    test('returns zero for invalid three of a kind', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.threeOfAKind, [
          1,
          2,
          3,
          4,
          5,
        ]),
        0,
      );
    });

    test('scores four of a kind with the full dice sum', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.fourOfAKind, [
          2,
          2,
          2,
          2,
          5,
        ]),
        13,
      );
    });

    test('returns zero for invalid four of a kind', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.fourOfAKind, [
          2,
          2,
          2,
          5,
          6,
        ]),
        0,
      );
    });

    test('scores full house only for a 3 plus 2 pattern', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.fullHouse, [2, 2, 3, 3, 3]),
        ScoreCalculator.fullHouseScore,
      );
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.fullHouse, [4, 4, 4, 4, 4]),
        0,
      );
    });

    test('detects small straights with duplicate dice present', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.smallStraight, [
          1,
          2,
          3,
          3,
          4,
        ]),
        ScoreCalculator.smallStraightScore,
      );
    });

    test('detects large straights only for 5 unique consecutive values', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.largeStraight, [
          2,
          3,
          4,
          5,
          6,
        ]),
        ScoreCalculator.largeStraightScore,
      );
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.largeStraight, [
          1,
          2,
          3,
          4,
          4,
        ]),
        0,
      );
    });

    test('scores yahtzee and chance correctly', () {
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.yahtzee, [5, 5, 5, 5, 5]),
        ScoreCalculator.yahtzeeScore,
      );
      expect(
        ScoreCalculator.scoreCategory(ScoreCategory.chance, [2, 3, 4, 5, 6]),
        20,
      );
    });

    test('throws for invalid dice input', () {
      expect(
        () => ScoreCalculator.scoreCategory(ScoreCategory.chance, [1, 2, 3]),
        throwsArgumentError,
      );
      expect(
        () => ScoreCalculator.scoreCategory(ScoreCategory.chance, [
          1,
          2,
          3,
          4,
          7,
        ]),
        throwsArgumentError,
      );
    });
  });

  group('ScoreCalculator bonuses and totals', () {
    test('calculates upper section subtotal and bonus', () {
      final scoreCard = <ScoreCategory, int?>{
        ScoreCategory.aces: 3,
        ScoreCategory.twos: 6,
        ScoreCategory.threes: 9,
        ScoreCategory.fours: 12,
        ScoreCategory.fives: 15,
        ScoreCategory.sixes: 18,
      };

      final subtotal = ScoreCalculator.calculateUpperSectionSubtotal(scoreCard);
      final bonus = ScoreCalculator.calculateUpperSectionBonus(subtotal);

      expect(subtotal, 63);
      expect(bonus, ScoreCalculator.upperSectionBonusValue);
    });

    test('does not award extra yahtzee bonus when yahtzee score is zero', () {
      final bonus = ScoreCalculator.calculateExtraYahtzeeBonus(
        yahtzeeCategoryScore: 0,
        extraYahtzeeCount: 2,
      );

      expect(bonus, 0);
    });

    test('awards 100 points for each extra yahtzee after a valid yahtzee', () {
      final bonus = ScoreCalculator.calculateExtraYahtzeeBonus(
        yahtzeeCategoryScore: ScoreCalculator.yahtzeeScore,
        extraYahtzeeCount: 2,
      );

      expect(bonus, 200);
    });

    test('calculates total score with upper bonus and extra yahtzee bonus', () {
      final scoreCard = <ScoreCategory, int?>{
        ScoreCategory.aces: 3,
        ScoreCategory.twos: 6,
        ScoreCategory.threes: 9,
        ScoreCategory.fours: 12,
        ScoreCategory.fives: 15,
        ScoreCategory.sixes: 18,
        ScoreCategory.threeOfAKind: 24,
        ScoreCategory.fourOfAKind: 0,
        ScoreCategory.fullHouse: 25,
        ScoreCategory.smallStraight: 30,
        ScoreCategory.largeStraight: 40,
        ScoreCategory.yahtzee: 50,
        ScoreCategory.chance: 22,
      };

      final total = ScoreCalculator.calculateTotal(
        scoreCard: scoreCard,
        extraYahtzeeCount: 1,
      );

      expect(total, 389);
    });
  });
}
