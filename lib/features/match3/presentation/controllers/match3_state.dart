import '../../domain/match3_grid.dart';
import '../../domain/match3_level_config.dart';

enum Match3Status { playing, won, lost }

class Match3State {
  const Match3State({
    required this.level,
    required this.grid,
    required this.score,
    required this.nextPieceId,
    required this.status,
    required this.movesRemaining,
    required this.timeRemainingSeconds,
    required this.obstaclesRemaining,
    this.selectedCell,
    this.lastSwap,
    this.lastCascadeCount = 0,
    this.lastClearedCount = 0,
    this.showLevelPicker = true,
  });

  final Match3LevelConfig level;
  final Match3Grid grid;
  final int score;
  final int nextPieceId;
  final Match3Status status;
  final int? movesRemaining;
  final int? timeRemainingSeconds;
  final int obstaclesRemaining;
  final (int row, int col)? selectedCell;
  final ((int row, int col), (int row, int col))? lastSwap;
  final int lastCascadeCount;
  final int lastClearedCount;
  final bool showLevelPicker;

  bool get isPlayable => status == Match3Status.playing;

  Match3State copyWith({
    Match3LevelConfig? level,
    Match3Grid? grid,
    int? score,
    int? nextPieceId,
    Match3Status? status,
    int? movesRemaining,
    int? timeRemainingSeconds,
    int? obstaclesRemaining,
    (int row, int col)? selectedCell,
    bool clearSelectedCell = false,
    ((int row, int col), (int row, int col))? lastSwap,
    bool clearLastSwap = false,
    int? lastCascadeCount,
    int? lastClearedCount,
    bool? showLevelPicker,
  }) {
    return Match3State(
      level: level ?? this.level,
      grid: grid ?? this.grid,
      score: score ?? this.score,
      nextPieceId: nextPieceId ?? this.nextPieceId,
      status: status ?? this.status,
      movesRemaining: movesRemaining ?? this.movesRemaining,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      obstaclesRemaining: obstaclesRemaining ?? this.obstaclesRemaining,
      selectedCell: clearSelectedCell
          ? null
          : selectedCell ?? this.selectedCell,
      lastSwap: clearLastSwap ? null : lastSwap ?? this.lastSwap,
      lastCascadeCount: lastCascadeCount ?? this.lastCascadeCount,
      lastClearedCount: lastClearedCount ?? this.lastClearedCount,
      showLevelPicker: showLevelPicker ?? this.showLevelPicker,
    );
  }
}
