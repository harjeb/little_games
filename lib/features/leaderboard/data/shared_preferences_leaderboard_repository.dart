import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/best_score_record.dart';
import '../domain/leaderboard_repository.dart';

class SharedPreferencesLeaderboardRepository implements LeaderboardRepository {
  SharedPreferencesLeaderboardRepository(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<BestScoreRecord?> getBestScore(String gameId) async {
    final rawValue = _preferences.getString(_keyFor(gameId));
    if (rawValue == null) {
      return null;
    }

    final json = jsonDecode(rawValue) as Map<String, Object?>;
    return BestScoreRecord(
      score: json['score']! as int,
      achievedAt: DateTime.parse(json['achievedAt']! as String),
    );
  }

  @override
  Future<bool> submitScore(
    String gameId,
    int score,
    DateTime achievedAt, {
    bool higherIsBetter = true,
  }) async {
    final currentBest = await getBestScore(gameId);
    final shouldReplace = switch (currentBest) {
      null => true,
      final existing when higherIsBetter => score > existing.score,
      final existing => score < existing.score,
    };

    if (!shouldReplace) {
      return false;
    }

    final payload = jsonEncode({
      'score': score,
      'achievedAt': achievedAt.toIso8601String(),
    });

    await _preferences.setString(_keyFor(gameId), payload);
    return true;
  }

  String _keyFor(String gameId) => 'leaderboard.best_score.$gameId';
}
