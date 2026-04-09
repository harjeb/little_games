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
    Match3LevelConfig(
      id: 4,
      name: 'Peach Parade',
      targetScore: 3600,
      ruleType: Match3LevelRuleType.moves,
      colorCount: 6,
      movesLimit: 16,
      score1Star: 2800,
      score2Star: 3800,
      score3Star: 5000,
    ),
    Match3LevelConfig(
      id: 5,
      name: 'Mint Minute',
      targetScore: 4200,
      ruleType: Match3LevelRuleType.timer,
      colorCount: 6,
      timeLimitSeconds: 65,
      score1Star: 3200,
      score2Star: 4400,
      score3Star: 5600,
    ),
    Match3LevelConfig(
      id: 6,
      name: 'Bubble Brigade',
      targetScore: 3800,
      ruleType: Match3LevelRuleType.obstacles,
      colorCount: 5,
      movesLimit: 20,
      obstacles: <(int row, int col)>[
        (0, 2),
        (1, 5),
        (2, 1),
        (2, 6),
        (4, 3),
        (5, 4),
        (6, 2),
        (7, 5),
      ],
      score1Star: 3000,
      score2Star: 4200,
      score3Star: 5400,
    ),
    Match3LevelConfig(
      id: 7,
      name: 'Lantern Lane',
      targetScore: 4600,
      ruleType: Match3LevelRuleType.moves,
      colorCount: 6,
      movesLimit: 15,
      score1Star: 3400,
      score2Star: 4800,
      score3Star: 6200,
    ),
    Match3LevelConfig(
      id: 8,
      name: 'Coral Countdown',
      targetScore: 5200,
      ruleType: Match3LevelRuleType.timer,
      colorCount: 6,
      timeLimitSeconds: 58,
      score1Star: 3800,
      score2Star: 5200,
      score3Star: 6800,
    ),
    Match3LevelConfig(
      id: 9,
      name: 'Lagoon Locks',
      targetScore: 4700,
      ruleType: Match3LevelRuleType.obstacles,
      colorCount: 6,
      movesLimit: 19,
      obstacles: <(int row, int col)>[
        (0, 0),
        (0, 7),
        (1, 3),
        (2, 2),
        (2, 5),
        (3, 6),
        (4, 1),
        (5, 4),
        (6, 3),
        (7, 0),
        (7, 7),
      ],
      score1Star: 3600,
      score2Star: 5000,
      score3Star: 6600,
    ),
    Match3LevelConfig(
      id: 10,
      name: 'Finale Fizz',
      targetScore: 6200,
      ruleType: Match3LevelRuleType.moves,
      colorCount: 6,
      movesLimit: 17,
      score1Star: 4400,
      score2Star: 6200,
      score3Star: 7800,
    ),
  ];
}
