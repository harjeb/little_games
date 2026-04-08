import '../../domain/board.dart';

class Game2048State {
  const Game2048State({required this.board, this.allowPlayBeyondWin = false});

  final Board board;
  final bool allowPlayBeyondWin;

  bool get showWinOverlay => board.won && !allowPlayBeyondWin;
  bool get showLossOverlay => board.lost;

  Game2048State copyWith({Board? board, bool? allowPlayBeyondWin}) {
    return Game2048State(
      board: board ?? this.board,
      allowPlayBeyondWin: allowPlayBeyondWin ?? this.allowPlayBeyondWin,
    );
  }
}
