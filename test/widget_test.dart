import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/app.dart';
import 'package:flutter_demo/app/localization/app_locale_controller.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';

void main() {
  testWidgets('home screen shows Yahtzee card and empty leaderboard state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({appLocalePreferenceKey: 'en'});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PocketPlayroomApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pocket Playroom'), findsOneWidget);
    expect(find.text('Yahtzee'), findsOneWidget);
    expect(find.text('No record yet'), findsOneWidget);
    expect(find.text('Play Yahtzee'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2048'), 250);
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('Play 2048'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Match-3'), 250);
    expect(find.text('Match-3'), findsOneWidget);
    expect(find.text('Play Match-3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sudoku'), 300);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Play Sudoku'), findsOneWidget);
  });

  testWidgets('home screen can switch to Chinese and persist locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({appLocalePreferenceKey: 'en'});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PocketPlayroomApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-zh')));
    await tester.pumpAndSettle();

    expect(find.text('掌上游乐屋'), findsOneWidget);
    expect(find.text('游戏列表'), findsOneWidget);
    expect(preferences.getString(appLocalePreferenceKey), 'zh');
  });
}
