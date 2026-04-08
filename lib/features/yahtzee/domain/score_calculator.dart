import 'score_category.dart';

final class ScoreCalculator {
  static const int upperSectionBonusThreshold = 63;
  static const int upperSectionBonusValue = 35;
  static const int fullHouseScore = 25;
  static const int smallStraightScore = 30;
  static const int largeStraightScore = 40;
  static const int yahtzeeScore = 50;
  static const int extraYahtzeeBonusValue = 100;

  static int scoreCategory(ScoreCategory category, List<int> diceValues) {
    _validateDiceValues(diceValues);

    final counts = _buildCounts(diceValues);
    final sum = diceValues.fold<int>(0, (total, value) => total + value);

    return switch (category) {
      ScoreCategory.aces => _scoreUpper(diceValues, target: 1),
      ScoreCategory.twos => _scoreUpper(diceValues, target: 2),
      ScoreCategory.threes => _scoreUpper(diceValues, target: 3),
      ScoreCategory.fours => _scoreUpper(diceValues, target: 4),
      ScoreCategory.fives => _scoreUpper(diceValues, target: 5),
      ScoreCategory.sixes => _scoreUpper(diceValues, target: 6),
      ScoreCategory.threeOfAKind => _hasCount(counts, 3) ? sum : 0,
      ScoreCategory.fourOfAKind => _hasCount(counts, 4) ? sum : 0,
      ScoreCategory.fullHouse => _isFullHouse(counts) ? fullHouseScore : 0,
      ScoreCategory.smallStraight =>
        _hasSmallStraight(diceValues) ? smallStraightScore : 0,
      ScoreCategory.largeStraight =>
        _hasLargeStraight(diceValues) ? largeStraightScore : 0,
      ScoreCategory.yahtzee => _hasCount(counts, 5) ? yahtzeeScore : 0,
      ScoreCategory.chance => sum,
    };
  }

  static int calculateUpperSectionSubtotal(Map<ScoreCategory, int?> scoreCard) {
    return scoreCard.entries
        .where((entry) => entry.key.isUpperSection)
        .fold<int>(0, (total, entry) => total + (entry.value ?? 0));
  }

  static int calculateUpperSectionBonus(int upperSectionSubtotal) {
    return upperSectionSubtotal >= upperSectionBonusThreshold
        ? upperSectionBonusValue
        : 0;
  }

  static int calculateExtraYahtzeeBonus({
    required int yahtzeeCategoryScore,
    required int extraYahtzeeCount,
  }) {
    if (yahtzeeCategoryScore < yahtzeeScore || extraYahtzeeCount <= 0) {
      return 0;
    }

    return extraYahtzeeCount * extraYahtzeeBonusValue;
  }

  static int calculateTotal({
    required Map<ScoreCategory, int?> scoreCard,
    required int extraYahtzeeCount,
  }) {
    final baseScore = scoreCard.values.fold<int>(
      0,
      (total, value) => total + (value ?? 0),
    );
    final upperSubtotal = calculateUpperSectionSubtotal(scoreCard);
    final upperBonus = calculateUpperSectionBonus(upperSubtotal);
    final extraYahtzeeBonus = calculateExtraYahtzeeBonus(
      yahtzeeCategoryScore: scoreCard[ScoreCategory.yahtzee] ?? 0,
      extraYahtzeeCount: extraYahtzeeCount,
    );

    return baseScore + upperBonus + extraYahtzeeBonus;
  }

  static int _scoreUpper(List<int> diceValues, {required int target}) {
    return diceValues
        .where((value) => value == target)
        .fold<int>(0, (total, value) => total + value);
  }

  static Map<int, int> _buildCounts(List<int> diceValues) {
    final counts = <int, int>{};
    for (final value in diceValues) {
      counts.update(value, (current) => current + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static bool _hasCount(Map<int, int> counts, int minimum) {
    return counts.values.any((count) => count >= minimum);
  }

  static bool _isFullHouse(Map<int, int> counts) {
    final groupedCounts = counts.values.toList()..sort();
    return groupedCounts.length == 2 &&
        groupedCounts[0] == 2 &&
        groupedCounts[1] == 3;
  }

  static bool _hasSmallStraight(List<int> diceValues) {
    final sortedUnique = diceValues.toSet().toList()..sort();
    const smallStraights = <List<int>>[
      [1, 2, 3, 4],
      [2, 3, 4, 5],
      [3, 4, 5, 6],
    ];

    for (final straight in smallStraights) {
      if (straight.every(sortedUnique.contains)) {
        return true;
      }
    }

    return false;
  }

  static bool _hasLargeStraight(List<int> diceValues) {
    final sortedUnique = diceValues.toSet().toList()..sort();
    if (sortedUnique.length != 5) {
      return false;
    }

    const largeStraights = <List<int>>[
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
    ];

    return largeStraights.any(
      (straight) => _listEquals(sortedUnique, straight),
    );
  }

  static bool _listEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  static void _validateDiceValues(List<int> diceValues) {
    if (diceValues.length != 5) {
      throw ArgumentError.value(
        diceValues,
        'diceValues',
        'Yahtzee scoring requires exactly 5 dice.',
      );
    }

    final hasInvalidValue = diceValues.any((value) => value < 1 || value > 6);
    if (hasInvalidValue) {
      throw ArgumentError.value(
        diceValues,
        'diceValues',
        'Each die must be between 1 and 6.',
      );
    }
  }
}
