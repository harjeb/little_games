import 'dart:math';

import 'match3_grid.dart';
import 'match3_level_config.dart';
import 'match3_piece.dart';

typedef Match3Position = (int row, int col);

class Match3Engine {
  const Match3Engine();

  Match3SetupResult createBoard({
    required Match3LevelConfig level,
    required Random random,
    required int nextPieceId,
  }) {
    var cursor = nextPieceId;
    final cells = List<List<Match3Piece?>>.generate(
      8,
      (_) => List<Match3Piece?>.filled(8, null, growable: false),
      growable: false,
    );
    final obstacleSet = level.obstacles.toSet();

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        if (obstacleSet.contains((row, col))) {
          cells[row][col] = Match3Piece(
            id: cursor++,
            color: Match3PieceColor.any,
            type: Match3PieceType.obstacle,
          );
          continue;
        }
        cells[row][col] = _randomNormalPiece(
          row: row,
          col: col,
          cells: cells,
          colorCount: level.colorCount,
          random: random,
          nextPieceId: cursor++,
        );
      }
    }

    var grid = Match3Grid(cells: cells);
    while (findAllMatches(grid).isNotEmpty || !hasValidMoves(grid)) {
      final rebuilt = createBoard(
        level: level,
        random: random,
        nextPieceId: cursor,
      );
      grid = rebuilt.grid;
      cursor = rebuilt.nextPieceId;
    }

    return Match3SetupResult(grid: grid, nextPieceId: cursor);
  }

  Set<Match3Position> findAllMatches(Match3Grid grid) {
    final matches = <Match3Position>{};
    for (var row = 0; row < grid.height; row++) {
      var startCol = 0;
      while (startCol < grid.width) {
        final piece = grid.pieceAt(row, startCol);
        if (piece == null || !piece.isMatchable) {
          startCol++;
          continue;
        }
        var endCol = startCol + 1;
        while (endCol < grid.width) {
          final next = grid.pieceAt(row, endCol);
          if (next == null || !next.isMatchable || next.color != piece.color) {
            break;
          }
          endCol++;
        }
        if (endCol - startCol >= 3) {
          for (var col = startCol; col < endCol; col++) {
            matches.add((row, col));
          }
        }
        startCol = endCol;
      }
    }

    for (var col = 0; col < grid.width; col++) {
      var startRow = 0;
      while (startRow < grid.height) {
        final piece = grid.pieceAt(startRow, col);
        if (piece == null || !piece.isMatchable) {
          startRow++;
          continue;
        }
        var endRow = startRow + 1;
        while (endRow < grid.height) {
          final next = grid.pieceAt(endRow, col);
          if (next == null || !next.isMatchable || next.color != piece.color) {
            break;
          }
          endRow++;
        }
        if (endRow - startRow >= 3) {
          for (var row = startRow; row < endRow; row++) {
            matches.add((row, col));
          }
        }
        startRow = endRow;
      }
    }
    return matches;
  }

  bool hasValidMoves(Match3Grid grid) {
    for (var row = 0; row < grid.height; row++) {
      for (var col = 0; col < grid.width; col++) {
        for (final offset in const <Match3Position>[(0, 1), (1, 0)]) {
          final next = (row + offset.$1, col + offset.$2);
          if (!_isInside(grid, next.$1, next.$2)) {
            continue;
          }
          if (!_canSwap(grid, (row, col), next)) {
            continue;
          }
          final swapped = _swap(grid, (row, col), next);
          if (findAllMatches(swapped).isNotEmpty ||
              _isRainbowSwap(grid, (row, col), next)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Match3TurnResult trySwap({
    required Match3Grid grid,
    required Match3Position from,
    required Match3Position to,
    required Match3LevelConfig level,
    required Random random,
    required int nextPieceId,
  }) {
    if (!_canSwap(grid, from, to)) {
      return Match3TurnResult.invalid(grid: grid, nextPieceId: nextPieceId);
    }

    var working = _swap(grid, from, to);
    var cursor = nextPieceId;
    var totalScore = 0;
    var cascades = 0;
    var totalCleared = 0;
    var obstaclesCleared = 0;

    Set<Match3Position> matches = _isRainbowSwap(grid, from, to)
        ? _rainbowMatches(working, from, to)
        : findAllMatches(working);
    if (matches.isEmpty) {
      return Match3TurnResult.invalid(grid: grid, nextPieceId: nextPieceId);
    }

    final swapDirection = from.$1 == to.$1
        ? Match3PieceType.rowClear
        : Match3PieceType.columnClear;

    while (matches.isNotEmpty) {
      cascades++;
      final resolution = _resolveOneCascade(
        grid: working,
        matches: matches,
        swapDirection: cascades == 1 ? swapDirection : null,
        random: random,
        colorCount: level.colorCount,
        nextPieceId: cursor,
      );
      working = resolution.grid;
      cursor = resolution.nextPieceId;
      totalScore += resolution.clearedCount * 60 * cascades;
      totalScore += resolution.bonusScore;
      totalCleared += resolution.clearedCount;
      obstaclesCleared += resolution.obstaclesCleared;
      matches = findAllMatches(working);
    }

    if (!hasValidMoves(working)) {
      final rebuilt = createBoard(
        level: level,
        random: random,
        nextPieceId: cursor,
      );
      working = rebuilt.grid;
      cursor = rebuilt.nextPieceId;
    }

    return Match3TurnResult.valid(
      grid: working,
      nextPieceId: cursor,
      scoreGained: totalScore,
      cascades: cascades,
      clearedCount: totalCleared,
      obstaclesCleared: obstaclesCleared,
    );
  }

  Set<Match3Position> _rainbowMatches(
    Match3Grid grid,
    Match3Position from,
    Match3Position to,
  ) {
    final fromPiece = grid.pieceAt(from.$1, from.$2);
    final toPiece = grid.pieceAt(to.$1, to.$2);
    if (fromPiece == null || toPiece == null) {
      return <Match3Position>{};
    }

    if (fromPiece.type == Match3PieceType.rainbow &&
        toPiece.type == Match3PieceType.rainbow) {
      return {
        for (var row = 0; row < grid.height; row++)
          for (var col = 0; col < grid.width; col++)
            if (grid.pieceAt(row, col)?.type != Match3PieceType.obstacle)
              (row, col),
      };
    }

    final targetColor = fromPiece.type == Match3PieceType.rainbow
        ? toPiece.color
        : fromPiece.color;
    return {
      for (var row = 0; row < grid.height; row++)
        for (var col = 0; col < grid.width; col++)
          if (grid.pieceAt(row, col)?.color == targetColor ||
              (row, col) == from ||
              (row, col) == to)
            (row, col),
    };
  }

  _CascadeResolution _resolveOneCascade({
    required Match3Grid grid,
    required Set<Match3Position> matches,
    required Match3PieceType? swapDirection,
    required Random random,
    required int colorCount,
    required int nextPieceId,
  }) {
    final working = grid.clone().cells;
    var cursor = nextPieceId;
    final clearSet = <Match3Position>{...matches};
    final special = swapDirection == null
        ? null
        : _specialSpawn(grid, matches, swapDirection);
    var bonusScore = 0;

    final pending = <Match3Position>[...clearSet];
    while (pending.isNotEmpty) {
      final position = pending.removeLast();
      final piece = working[position.$1][position.$2];
      if (piece == null) {
        continue;
      }
      if (piece.type == Match3PieceType.rowClear) {
        for (var col = 0; col < grid.width; col++) {
          if (clearSet.add((position.$1, col))) {
            pending.add((position.$1, col));
          }
        }
        bonusScore += 180;
      } else if (piece.type == Match3PieceType.columnClear) {
        for (var row = 0; row < grid.height; row++) {
          if (clearSet.add((row, position.$2))) {
            pending.add((row, position.$2));
          }
        }
        bonusScore += 180;
      } else if (piece.type == Match3PieceType.rainbow) {
        final reference = matches
            .map((entry) => grid.pieceAt(entry.$1, entry.$2))
            .whereType<Match3Piece>()
            .firstWhere(
              (candidate) =>
                  candidate.type != Match3PieceType.rainbow &&
                  candidate.type != Match3PieceType.obstacle,
              orElse: () => piece,
            );
        for (var row = 0; row < grid.height; row++) {
          for (var col = 0; col < grid.width; col++) {
            final candidate = grid.pieceAt(row, col);
            if (candidate != null && candidate.color == reference.color) {
              if (clearSet.add((row, col))) {
                pending.add((row, col));
              }
            }
          }
        }
        bonusScore += 260;
      }
    }

    final obstacleClear = <Match3Position>{};
    for (final position in clearSet) {
      for (final offset in const <Match3Position>[
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
      ]) {
        final row = position.$1 + offset.$1;
        final col = position.$2 + offset.$2;
        if (!_isInside(grid, row, col)) {
          continue;
        }
        final neighbor = working[row][col];
        if (neighbor?.type == Match3PieceType.obstacle) {
          obstacleClear.add((row, col));
        }
      }
    }
    clearSet.addAll(obstacleClear);

    Match3Position? preservedPosition;
    Match3Piece? spawnedSpecial;
    if (special != null && clearSet.contains(special.position)) {
      preservedPosition = special.position;
      spawnedSpecial = Match3Piece(
        id: cursor++,
        color: special.type == Match3PieceType.rainbow
            ? Match3PieceColor.any
            : special.color,
        type: special.type,
      );
      clearSet.remove(special.position);
    }

    for (final position in clearSet) {
      working[position.$1][position.$2] = null;
    }
    if (preservedPosition != null) {
      working[preservedPosition.$1][preservedPosition.$2] = spawnedSpecial;
    }

    final collapsed = _collapseAndSpawn(
      working: working,
      colorCount: colorCount,
      random: random,
      nextPieceId: cursor,
    );

    return _CascadeResolution(
      grid: Match3Grid(cells: collapsed.cells),
      nextPieceId: collapsed.nextPieceId,
      clearedCount: clearSet.length + (spawnedSpecial != null ? 0 : 0),
      obstaclesCleared: obstacleClear.length,
      bonusScore: bonusScore,
    );
  }

  _SpecialSpawn? _specialSpawn(
    Match3Grid grid,
    Set<Match3Position> matches,
    Match3PieceType swapDirection,
  ) {
    final horizontal = _lineMatches(grid, horizontal: true);
    final vertical = _lineMatches(grid, horizontal: false);
    final candidateLines = <_LineMatch>[
      ...horizontal.where(
        (line) => line.positions.toSet().intersection(matches).isNotEmpty,
      ),
      ...vertical.where(
        (line) => line.positions.toSet().intersection(matches).isNotEmpty,
      ),
    ]..sort((a, b) => b.positions.length.compareTo(a.positions.length));

    if (candidateLines.isEmpty) {
      return null;
    }

    final best = candidateLines.first;
    final anchor = best.positions[best.positions.length ~/ 2];
    final color =
        grid.pieceAt(anchor.$1, anchor.$2)?.color ?? Match3PieceColor.coral;

    if (best.positions.length >= 5) {
      return _SpecialSpawn(
        position: anchor,
        color: Match3PieceColor.any,
        type: Match3PieceType.rainbow,
      );
    }
    if (best.positions.length == 4) {
      return _SpecialSpawn(position: anchor, color: color, type: swapDirection);
    }
    return null;
  }

  List<_LineMatch> _lineMatches(Match3Grid grid, {required bool horizontal}) {
    final lines = <_LineMatch>[];
    final outer = horizontal ? grid.height : grid.width;
    final inner = horizontal ? grid.width : grid.height;
    for (var outerIndex = 0; outerIndex < outer; outerIndex++) {
      var start = 0;
      while (start < inner) {
        final row = horizontal ? outerIndex : start;
        final col = horizontal ? start : outerIndex;
        final piece = grid.pieceAt(row, col);
        if (piece == null || !piece.isMatchable) {
          start++;
          continue;
        }
        var end = start + 1;
        while (end < inner) {
          final nextRow = horizontal ? outerIndex : end;
          final nextCol = horizontal ? end : outerIndex;
          final next = grid.pieceAt(nextRow, nextCol);
          if (next == null || !next.isMatchable || next.color != piece.color) {
            break;
          }
          end++;
        }
        if (end - start >= 3) {
          lines.add(
            _LineMatch(
              positions: <Match3Position>[
                for (var index = start; index < end; index++)
                  horizontal ? (outerIndex, index) : (index, outerIndex),
              ],
            ),
          );
        }
        start = end;
      }
    }
    return lines;
  }

  _CollapseResult _collapseAndSpawn({
    required List<List<Match3Piece?>> working,
    required int colorCount,
    required Random random,
    required int nextPieceId,
  }) {
    var cursor = nextPieceId;
    for (var col = 0; col < 8; col++) {
      final obstacleRows = <int>[
        for (var row = 0; row < 8; row++)
          if (working[row][col]?.type == Match3PieceType.obstacle) row,
      ];
      final boundaries = <int>[-1, ...obstacleRows, 8];
      for (
        var segmentIndex = 0;
        segmentIndex < boundaries.length - 1;
        segmentIndex++
      ) {
        final start = boundaries[segmentIndex] + 1;
        final end = boundaries[segmentIndex + 1] - 1;
        if (start > end) {
          continue;
        }
        final pieces = <Match3Piece>[
          for (var row = start; row <= end; row++)
            if (working[row][col] case final Match3Piece piece
                when piece.type != Match3PieceType.obstacle)
              piece,
        ];
        for (var row = start; row <= end; row++) {
          working[row][col] = null;
        }
        var writeRow = end;
        for (final piece in pieces.reversed) {
          working[writeRow][col] = piece;
          writeRow--;
        }
        while (writeRow >= start) {
          working[writeRow][col] = Match3Piece(
            id: cursor++,
            color: _randomColor(colorCount, random),
            type: Match3PieceType.normal,
          );
          writeRow--;
        }
      }
    }
    return _CollapseResult(cells: working, nextPieceId: cursor);
  }

  Match3Piece _randomNormalPiece({
    required int row,
    required int col,
    required List<List<Match3Piece?>> cells,
    required int colorCount,
    required Random random,
    required int nextPieceId,
  }) {
    var color = _randomColor(colorCount, random);
    while (_wouldCreateInitialMatch(cells, row, col, color)) {
      color = _randomColor(colorCount, random);
    }
    return Match3Piece(id: nextPieceId, color: color);
  }

  bool _wouldCreateInitialMatch(
    List<List<Match3Piece?>> cells,
    int row,
    int col,
    Match3PieceColor color,
  ) {
    if (col >= 2 &&
        cells[row][col - 1]?.color == color &&
        cells[row][col - 2]?.color == color) {
      return true;
    }
    if (row >= 2 &&
        cells[row - 1][col]?.color == color &&
        cells[row - 2][col]?.color == color) {
      return true;
    }
    return false;
  }

  bool _canSwap(Match3Grid grid, Match3Position from, Match3Position to) {
    if (!_isInside(grid, from.$1, from.$2) || !_isInside(grid, to.$1, to.$2)) {
      return false;
    }
    if ((from.$1 - to.$1).abs() + (from.$2 - to.$2).abs() != 1) {
      return false;
    }
    final fromPiece = grid.pieceAt(from.$1, from.$2);
    final toPiece = grid.pieceAt(to.$1, to.$2);
    return fromPiece != null &&
        toPiece != null &&
        fromPiece.isMovable &&
        toPiece.isMovable;
  }

  bool _isRainbowSwap(Match3Grid grid, Match3Position from, Match3Position to) {
    final fromPiece = grid.pieceAt(from.$1, from.$2);
    final toPiece = grid.pieceAt(to.$1, to.$2);
    return fromPiece?.type == Match3PieceType.rainbow ||
        toPiece?.type == Match3PieceType.rainbow;
  }

  Match3Grid _swap(Match3Grid grid, Match3Position from, Match3Position to) {
    final copy = grid.clone().cells;
    final left = copy[from.$1][from.$2];
    copy[from.$1][from.$2] = copy[to.$1][to.$2];
    copy[to.$1][to.$2] = left;
    return Match3Grid(cells: copy, width: grid.width, height: grid.height);
  }

  bool _isInside(Match3Grid grid, int row, int col) {
    return row >= 0 && row < grid.height && col >= 0 && col < grid.width;
  }

  Match3PieceColor _randomColor(int colorCount, Random random) {
    final palette = Match3PieceColor.values
        .where((color) => color != Match3PieceColor.any)
        .take(colorCount)
        .toList();
    return palette[random.nextInt(palette.length)];
  }
}

class Match3SetupResult {
  const Match3SetupResult({required this.grid, required this.nextPieceId});

  final Match3Grid grid;
  final int nextPieceId;
}

class Match3TurnResult {
  const Match3TurnResult._({
    required this.grid,
    required this.nextPieceId,
    required this.scoreGained,
    required this.cascades,
    required this.clearedCount,
    required this.obstaclesCleared,
    required this.boardChanged,
  });

  const Match3TurnResult.valid({
    required Match3Grid grid,
    required int nextPieceId,
    required int scoreGained,
    required int cascades,
    required int clearedCount,
    required int obstaclesCleared,
  }) : this._(
         grid: grid,
         nextPieceId: nextPieceId,
         scoreGained: scoreGained,
         cascades: cascades,
         clearedCount: clearedCount,
         obstaclesCleared: obstaclesCleared,
         boardChanged: true,
       );

  const Match3TurnResult.invalid({
    required Match3Grid grid,
    required int nextPieceId,
  }) : this._(
         grid: grid,
         nextPieceId: nextPieceId,
         scoreGained: 0,
         cascades: 0,
         clearedCount: 0,
         obstaclesCleared: 0,
         boardChanged: false,
       );

  final Match3Grid grid;
  final int nextPieceId;
  final int scoreGained;
  final int cascades;
  final int clearedCount;
  final int obstaclesCleared;
  final bool boardChanged;
}

class _CascadeResolution {
  const _CascadeResolution({
    required this.grid,
    required this.nextPieceId,
    required this.clearedCount,
    required this.obstaclesCleared,
    required this.bonusScore,
  });

  final Match3Grid grid;
  final int nextPieceId;
  final int clearedCount;
  final int obstaclesCleared;
  final int bonusScore;
}

class _CollapseResult {
  const _CollapseResult({required this.cells, required this.nextPieceId});

  final List<List<Match3Piece?>> cells;
  final int nextPieceId;
}

class _SpecialSpawn {
  const _SpecialSpawn({
    required this.position,
    required this.color,
    required this.type,
  });

  final Match3Position position;
  final Match3PieceColor color;
  final Match3PieceType type;
}

class _LineMatch {
  const _LineMatch({required this.positions});

  final List<Match3Position> positions;
}
