import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/localization/app_localizations.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';
import 'package:flutter_demo/features/match3/presentation/match3_screen.dart';

void main() {
  testWidgets('match3 screen renders level picker and board', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Match3Screen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Match-3 Theatre'), findsOneWidget);
    expect(find.text('Choose a Level'), findsOneWidget);
    expect(find.text('Level 1'), findsWidgets);
    expect(find.text('Level 10'), findsOneWidget);
  });
}
