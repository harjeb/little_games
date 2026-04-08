import 'package:flutter/material.dart';

import '../features/game_2048/presentation/game_2048_result_screen.dart';
import '../features/game_2048/presentation/game_2048_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/sudoku/domain/sudoku_difficulty.dart';
import '../features/sudoku/presentation/sudoku_result_screen.dart';
import '../features/sudoku/presentation/sudoku_screen.dart';
import '../features/yahtzee/presentation/yahtzee_result_screen.dart';
import '../features/yahtzee/presentation/yahtzee_screen.dart';

final class AppRouter {
  static const String homeRoute = '/';
  static const String yahtzeeRoute = '/yahtzee';
  static const String yahtzeeResultRoute = '/yahtzee/result';
  static const String game2048Route = '/game-2048';
  static const String game2048ResultRoute = '/game-2048/result';
  static const String sudokuRoute = '/sudoku';
  static const String sudokuResultRoute = '/sudoku/result';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      homeRoute => MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
        settings: settings,
      ),
      yahtzeeRoute => MaterialPageRoute<void>(
        builder: (_) => const YahtzeeScreen(),
        settings: settings,
      ),
      yahtzeeResultRoute => MaterialPageRoute<void>(
        builder: (_) => YahtzeeResultScreen(
          result: settings.arguments is YahtzeeResultData
              ? settings.arguments! as YahtzeeResultData
              : const YahtzeeResultData(
                  finalScore: 0,
                  upperSectionBonus: 0,
                  extraYahtzeeBonus: 0,
                ),
        ),
        settings: settings,
      ),
      game2048Route => MaterialPageRoute<void>(
        builder: (_) => const Game2048Screen(),
        settings: settings,
      ),
      game2048ResultRoute => MaterialPageRoute<void>(
        builder: (_) => Game2048ResultScreen(
          result: settings.arguments is Game2048ResultData
              ? settings.arguments! as Game2048ResultData
              : const Game2048ResultData(
                  finalScore: 0,
                  maxTile: 0,
                  didReach2048: false,
                ),
        ),
        settings: settings,
      ),
      sudokuRoute => MaterialPageRoute<void>(
        builder: (_) => const SudokuScreen(),
        settings: settings,
      ),
      sudokuResultRoute => MaterialPageRoute<void>(
        builder: (_) => SudokuResultScreen(
          result: settings.arguments is SudokuResultData
              ? settings.arguments! as SudokuResultData
              : const SudokuResultData(
                  difficulty: SudokuDifficulty.easy,
                  elapsedSeconds: 0,
                  mistakes: 0,
                ),
        ),
        settings: settings,
      ),
      _ => MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
        settings: settings,
      ),
    };
  }
}
