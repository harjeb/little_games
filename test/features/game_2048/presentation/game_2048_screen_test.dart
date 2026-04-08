import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/localization/app_localizations.dart';
import 'package:flutter_demo/features/game_2048/presentation/game_2048_screen.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';

void main() {
  testWidgets('2048 screen renders board and score cards', (tester) async {
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
          home: Game2048Screen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2048 Glow Grid'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Best'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });
}
