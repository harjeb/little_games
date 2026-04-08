import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/features/leaderboard/data/shared_preferences_leaderboard_repository.dart';

void main() {
  group('SharedPreferencesLeaderboardRepository', () {
    test('returns null when no best score exists', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesLeaderboardRepository(preferences);

      final result = await repository.getBestScore('yahtzee');

      expect(result, isNull);
    });

    test('stores a new best score', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesLeaderboardRepository(preferences);
      final timestamp = DateTime.utc(2026, 4, 7, 8, 30);

      final isRecord = await repository.submitScore('yahtzee', 212, timestamp);
      final result = await repository.getBestScore('yahtzee');

      expect(isRecord, isTrue);
      expect(result?.score, 212);
      expect(result?.achievedAt, timestamp);
    });

    test('does not replace an existing record with a lower score', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesLeaderboardRepository(preferences);

      await repository.submitScore('yahtzee', 240, DateTime.utc(2026, 4, 7));
      final isRecord = await repository.submitScore(
        'yahtzee',
        180,
        DateTime.utc(2026, 4, 8),
      );
      final result = await repository.getBestScore('yahtzee');

      expect(isRecord, isFalse);
      expect(result?.score, 240);
      expect(result?.achievedAt, DateTime.utc(2026, 4, 7));
    });

    test('supports lower score as better when requested', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesLeaderboardRepository(preferences);

      await repository.submitScore(
        'sudoku_easy',
        260,
        DateTime.utc(2026, 4, 7),
        higherIsBetter: false,
      );
      final isRecord = await repository.submitScore(
        'sudoku_easy',
        215,
        DateTime.utc(2026, 4, 8),
        higherIsBetter: false,
      );
      final result = await repository.getBestScore('sudoku_easy');

      expect(isRecord, isTrue);
      expect(result?.score, 215);
      expect(result?.achievedAt, DateTime.utc(2026, 4, 8));
    });
  });
}
