import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/localization/app_localizations.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';
import 'package:flutter_demo/features/yahtzee/domain/score_category.dart';
import 'package:flutter_demo/features/yahtzee/domain/yahtzee_session_controller.dart';
import 'package:flutter_demo/features/yahtzee/presentation/controllers/yahtzee_game_controller.dart';
import 'package:flutter_demo/features/yahtzee/presentation/yahtzee_screen.dart';

void main() {
  testWidgets('yahtzee screen renders gameplay shell and categories', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        yahtzeeSessionControllerProvider.overrideWithValue(
          YahtzeeSessionController(
            rollDice: _queueRolls([
              [1, 1, 1, 1, 1],
              [2, 3, 4, 5, 6],
            ]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: YahtzeeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Yahtzee Run', skipOffstage: false), findsOneWidget);
    expect(find.text('Dice Tray'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Score Sheet'), 400);
    expect(find.text('Score Sheet'), findsOneWidget);
    expect(find.text('Aces'), findsOneWidget);
    expect(find.text('Reroll Dice'), findsOneWidget);
  });

  testWidgets('selecting a category advances the round and updates score', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        yahtzeeSessionControllerProvider.overrideWithValue(
          YahtzeeSessionController(
            rollDice: _queueRolls([
              [1, 1, 1, 1, 1],
              [2, 3, 4, 5, 6],
            ]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: YahtzeeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Aces'), 400);
    await tester.tap(find.text('Aces'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 820));

    final state = container.read(yahtzeeGameProvider);
    expect(state.session.roundIndex, 2);
    expect(state.session.scoreCard[ScoreCategory.aces], 5);
  });
}

DiceRoller _queueRolls(List<List<int>> queuedRolls) {
  final pendingRolls = List<List<int>>.of(queuedRolls);

  return (count) {
    final nextRoll = pendingRolls.removeAt(0);
    if (nextRoll.length != count) {
      throw StateError('Expected $count dice values, got ${nextRoll.length}.');
    }

    return nextRoll;
  };
}
