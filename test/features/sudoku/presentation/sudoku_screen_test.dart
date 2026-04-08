import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_demo/app/localization/app_localizations.dart';
import 'package:flutter_demo/features/leaderboard/leaderboard_providers.dart';
import 'package:flutter_demo/features/sudoku/presentation/sudoku_screen.dart';

void main() {
  testWidgets('sudoku screen renders board and controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SudokuScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sudoku Studio'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Mistakes'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
