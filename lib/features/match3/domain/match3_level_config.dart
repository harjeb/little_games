import '../../../core/constants/game_ids.dart';

enum Match3LevelRuleType { moves, timer, obstacles }

class Match3LevelConfig {
  const Match3LevelConfig({
    required this.id,
    required this.name,
    required this.targetScore,
    required this.ruleType,
    required this.colorCount,
    this.movesLimit,
    this.timeLimitSeconds,
    this.obstacles = const <(int row, int col)>[],
    this.score1Star = 1200,
    this.score2Star = 2400,
    this.score3Star = 3600,
  });

  final int id;
  final String name;
  final int targetScore;
  final Match3LevelRuleType ruleType;
  final int colorCount;
  final int? movesLimit;
  final int? timeLimitSeconds;
  final List<(int row, int col)> obstacles;
  final int score1Star;
  final int score2Star;
  final int score3Star;

  String get gameId => GameIds.match3Level(id);

  static const List<Match3LevelConfig> defaults = <Match3LevelConfig>[
    Match3LevelConfig(
      id: 1,
      name: 'Candy Warmup',
      targetScore: 2400,
      ruleType: Match3LevelRuleType.moves,
      colorCount: 5,
      movesLimit: 14,
      score1Star: 2000,
      score2Star: 2800,
      score3Star: 3600,
    ),
    Match3LevelConfig(
      id: 2,
      name: 'Rush Hour',
      targetScore: 3000,
      ruleType: Match3LevelRuleType.timer,
      colorCount: 6,
      timeLimitSeconds: 70,
      score1Star: 2400,
      score2Star: 3400,
      score3Star: 4600,
    ),
    Match3LevelConfig(
      id: 3,
      name: 'Bubble Break',
      targetScore: 2600,
      ruleType: Match3LevelRuleType.obstacles,
      colorCount: 5,
      movesLimit: 18,
      obstacles: <(int row, int col)>[
        (1, 1),
        (1, 6),
        (3, 3),
        (4, 4),
        (6, 1),
        (6, 6),
      ],
      score1Star: 2200,
      score2Star: 3200,
      score3Star: 4200,
    ),
  ];
}
