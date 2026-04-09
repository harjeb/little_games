import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/score_category.dart';
import '../../domain/yahtzee_session.dart';
import '../../domain/yahtzee_session_controller.dart';
import 'yahtzee_game_state.dart';

final yahtzeeSessionControllerProvider = Provider<YahtzeeSessionController>((
  ref,
) {
  final random = Random();
  return YahtzeeSessionController(
    rollDice: (count) =>
        List<int>.generate(count, (_) => random.nextInt(6) + 1),
  );
});

final yahtzeeGameProvider =
    NotifierProvider<YahtzeeGameNotifier, YahtzeeGameState>(
      YahtzeeGameNotifier.new,
    );

class YahtzeeGameNotifier extends Notifier<YahtzeeGameState> {
  static const Duration _animationDuration = Duration(milliseconds: 760);

  late final YahtzeeSessionController _sessionController;

  @override
  YahtzeeGameState build() {
    _sessionController = ref.watch(yahtzeeSessionControllerProvider);
    return YahtzeeGameState(
      session: _sessionController.startGame(),
      rollToken: 0,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void toggleHold(int dieIndex) {
    if (state.isRolling || state.session.isFinished) {
      return;
    }

    try {
      state = state.copyWith(
        session: _sessionController.toggleHold(state.session, dieIndex),
        clearError: true,
      );
    } on StateError catch (error) {
      _setError(error.message);
    } on RangeError catch (error) {
      _setError(error.message);
    }
  }

  Future<void> reroll() async {
    if (state.isRolling || state.session.isFinished) {
      return;
    }

    try {
      final currentSession = state.session;
      final nextSession = _sessionController.reroll(currentSession);
      final rollingIndices = <int>{
        for (var index = 0; index < currentSession.diceSet.held.length; index++)
          if (!currentSession.diceSet.held[index]) index,
      };

      await _animateTransition(
        nextSession: nextSession,
        previousValues: currentSession.diceSet.values,
        rollingIndices: rollingIndices,
      );
    } on StateError catch (error) {
      _setError(error.message);
    }
  }

  Future<void> assignCategory(ScoreCategory category) async {
    if (state.isRolling || state.session.isFinished) {
      return;
    }

    try {
      final currentSession = state.session;
      final nextSession = _sessionController.assignCategory(
        currentSession,
        category,
      );

      if (nextSession.isFinished) {
        state = state.copyWith(
          session: nextSession,
          clearError: true,
          rollingIndices: const <int>{},
          clearPreviousDiceValues: true,
        );
        return;
      }

      await _animateTransition(
        nextSession: nextSession,
        previousValues: currentSession.diceSet.values,
        rollingIndices: const <int>{0, 1, 2, 3, 4},
      );
    } on StateError catch (error) {
      _setError(error.message);
    }
  }

  void restart() {
    state = YahtzeeGameState(
      session: _sessionController.startGame(),
      rollToken: state.rollToken + 1,
    );
  }

  Future<void> _animateTransition({
    required YahtzeeSession nextSession,
    required List<int> previousValues,
    required Set<int> rollingIndices,
  }) async {
    state = state.copyWith(
      session: nextSession,
      previousDiceValues: List<int>.unmodifiable(previousValues),
      rollingIndices: rollingIndices,
      rollToken: state.rollToken + 1,
      clearError: true,
    );

    await Future<void>.delayed(_animationDuration);

    state = state.copyWith(
      rollingIndices: const <int>{},
      clearPreviousDiceValues: true,
      clearError: true,
    );
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
}
