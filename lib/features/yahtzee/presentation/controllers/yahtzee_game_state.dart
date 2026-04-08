import '../../domain/yahtzee_session.dart';

class YahtzeeGameState {
  const YahtzeeGameState({
    required this.session,
    required this.rollToken,
    this.previousDiceValues,
    this.rollingIndices = const <int>{},
    this.errorMessage,
  });

  final YahtzeeSession session;
  final List<int>? previousDiceValues;
  final Set<int> rollingIndices;
  final int rollToken;
  final String? errorMessage;

  bool get isRolling => rollingIndices.isNotEmpty;

  YahtzeeGameState copyWith({
    YahtzeeSession? session,
    List<int>? previousDiceValues,
    Set<int>? rollingIndices,
    int? rollToken,
    String? errorMessage,
    bool clearPreviousDiceValues = false,
    bool clearError = false,
  }) {
    return YahtzeeGameState(
      session: session ?? this.session,
      previousDiceValues: clearPreviousDiceValues
          ? null
          : previousDiceValues ?? this.previousDiceValues,
      rollingIndices: rollingIndices ?? this.rollingIndices,
      rollToken: rollToken ?? this.rollToken,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
