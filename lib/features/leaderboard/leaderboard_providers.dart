import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/shared_preferences_leaderboard_repository.dart';
import 'domain/best_score_record.dart';
import 'domain/leaderboard_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at app startup.',
  ),
);

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesLeaderboardRepository(preferences);
});

final bestScoreProvider = FutureProvider.family<BestScoreRecord?, String>((
  ref,
  gameId,
) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getBestScore(gameId);
});
