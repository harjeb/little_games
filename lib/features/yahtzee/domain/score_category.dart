import '../../../app/localization/app_localizations.dart';

enum ScoreCategory {
  aces,
  twos,
  threes,
  fours,
  fives,
  sixes,
  threeOfAKind,
  fourOfAKind,
  fullHouse,
  smallStraight,
  largeStraight,
  yahtzee,
  chance,
}

extension ScoreCategoryX on ScoreCategory {
  String get label => switch (this) {
    ScoreCategory.aces => 'Aces',
    ScoreCategory.twos => 'Twos',
    ScoreCategory.threes => 'Threes',
    ScoreCategory.fours => 'Fours',
    ScoreCategory.fives => 'Fives',
    ScoreCategory.sixes => 'Sixes',
    ScoreCategory.threeOfAKind => 'Three of a Kind',
    ScoreCategory.fourOfAKind => 'Four of a Kind',
    ScoreCategory.fullHouse => 'Full House',
    ScoreCategory.smallStraight => 'Small Straight',
    ScoreCategory.largeStraight => 'Large Straight',
    ScoreCategory.yahtzee => 'Yahtzee',
    ScoreCategory.chance => 'Chance',
  };

  String localizedLabel(AppLocalizations l10n) => l10n.categoryLabel(label);

  bool get isUpperSection => index <= ScoreCategory.sixes.index;
}
