import 'package:flutter/material.dart';

import '../core/animations/clay_page_route.dart';
import '../features/game_2048/presentation/game_2048_result_screen.dart';
import '../features/game_2048/presentation/game_2048_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/match3/domain/match3_level_config.dart';
import '../features/match3/presentation/match3_result_screen.dart';
import '../features/match3/presentation/match3_screen.dart';
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
  static const String match3Route = '/match3';
  static const String match3ResultRoute = '/match3/result';
  static const String sudokuRoute = '/sudoku';
  static const String sudokuResultRoute = '/sudoku/result';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      homeRoute => _route(
        settings: settings,
        builder: (_) => const HomeScreen(),
      ),
      yahtzeeRoute => _route(
        settings: settings,
        builder: (_) => const YahtzeeScreen(),
      ),
      yahtzeeResultRoute => _route(
        settings: settings,
        style: ClayRouteTransitionStyle.result,
        builder: (_) => YahtzeeResultScreen(
          result: settings.arguments is YahtzeeResultData
              ? settings.arguments! as YahtzeeResultData
              : const YahtzeeResultData(
                  finalScore: 0,
                  upperSectionBonus: 0,
                  extraYahtzeeBonus: 0,
                ),
        ),
      ),
      game2048Route => _route(
        settings: settings,
        builder: (_) => const Game2048Screen(),
      ),
      game2048ResultRoute => _route(
        settings: settings,
        style: ClayRouteTransitionStyle.result,
        builder: (_) => Game2048ResultScreen(
          result: settings.arguments is Game2048ResultData
              ? settings.arguments! as Game2048ResultData
              : const Game2048ResultData(
                  finalScore: 0,
                  maxTile: 0,
                  didReach2048: false,
                ),
        ),
      ),
      match3Route => _route(
        settings: settings,
        builder: (_) => const Match3Screen(),
      ),
      match3ResultRoute => _route(
        settings: settings,
        style: ClayRouteTransitionStyle.result,
        builder: (_) => Match3ResultScreen(
          result: settings.arguments is Match3ResultData
              ? settings.arguments! as Match3ResultData
              : Match3ResultData(
                  level: Match3LevelConfig.defaults.first,
                  score: 0,
                  didWin: false,
                ),
        ),
      ),
      sudokuRoute => _route(
        settings: settings,
        builder: (_) => const SudokuScreen(),
      ),
      sudokuResultRoute => _route(
        settings: settings,
        style: ClayRouteTransitionStyle.result,
        builder: (_) => SudokuResultScreen(
          result: settings.arguments is SudokuResultData
              ? settings.arguments! as SudokuResultData
              : const SudokuResultData(
                  difficulty: SudokuDifficulty.easy,
                  elapsedSeconds: 0,
                  mistakes: 0,
                ),
        ),
      ),
      _ => _route(settings: settings, builder: (_) => const HomeScreen()),
    };
  }

  static Route<T> _route<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
    ClayRouteTransitionStyle style = ClayRouteTransitionStyle.page,
  }) {
    return ClayPageRoute<T>(builder: builder, settings: settings, style: style);
  }
}
