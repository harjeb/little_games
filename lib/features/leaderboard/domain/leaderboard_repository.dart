import 'best_score_record.dart';

abstract class LeaderboardRepository {
  Future<BestScoreRecord?> getBestScore(String gameId);

  Future<bool> submitScore(
    String gameId,
    int score,
    DateTime achievedAt, {
    bool higherIsBetter = true,
  });
}
