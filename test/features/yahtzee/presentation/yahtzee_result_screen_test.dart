import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/localization/app_localizations.dart';
import 'package:flutter_demo/core/constants/game_ids.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';
import 'package:flutter_demo/features/yahtzee/presentation/yahtzee_result_screen.dart';

void main() {
  testWidgets('result screen stores a new high score', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: YahtzeeResultScreen(
            result: YahtzeeResultData(
              finalScore: 244,
              upperSectionBonus: 35,
              extraYahtzeeBonus: 100,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Fresh High Score!'), findsOneWidget);
    expect(find.textContaining('Final score: 244'), findsOneWidget);
    expect(
      preferences.getString('leaderboard.best_score.${GameIds.yahtzee}'),
      isNotNull,
    );
  });
}
