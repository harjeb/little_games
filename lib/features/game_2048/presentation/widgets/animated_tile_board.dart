import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/clay_panel.dart';
import '../../domain/board.dart';
import '../../domain/move_engine.dart';
import '../../domain/tile.dart';

class AnimatedTileBoard extends StatefulWidget {
  const AnimatedTileBoard({
    super.key,
    required this.board,
    required this.onSlide,
    this.enabled = true,
    this.gameOverProgress = 0,
  });

  final Board board;
  final ValueChanged<SlideDirection> onSlide;
  final bool enabled;
  final double gameOverProgress;

  @override
  State<AnimatedTileBoard> createState() => _AnimatedTileBoardState();
}

class _AnimatedTileBoardState extends State<AnimatedTileBoard>
    with SingleTickerProviderStateMixin {
  static const double _gap = 10;

  late final AnimationController _moveController;
  late List<_TileMotion> _motions;
  Axis? _dragAxis;
  Offset _dragDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    _motions = _buildMotions(null, widget.board);
    _moveController.value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedTileBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.board) == _signature(widget.board)) {
      return;
    }

    setState(() {
      _motions = _buildMotions(oldWidget.board, widget.board);
      _dragAxis = null;
      _dragDelta = Offset.zero;
    });
    _moveController.forward(from: 0);
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled ? (_) => _beginDrag() : null,
      onPanUpdate: widget.enabled ? _updateDrag : null,
      onPanEnd: widget.enabled ? _endDrag : null,
      onPanCancel: widget.enabled ? _cancelDrag : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClayPanel(
          backgroundColor: AppColors.haze.withValues(alpha: 0.96),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize =
                  (constraints.maxWidth - (_gap * (Board.size - 1))) /
                  Board.size;
              return Stack(
                children: <Widget>[
                  for (var row = 0; row < Board.size; row++)
                    for (var col = 0; col < Board.size; col++)
                      Positioned(
                        left: col * (cellSize + _gap),
                        top: row * (cellSize + _gap),
                        child: _BoardCell(size: cellSize),
                      ),
                  AnimatedSlide(
                    offset: _previewOffsetFraction(),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutBack,
                    child: AnimatedBuilder(
                      animation: _moveController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            for (final motion in _motions)
                              _AnimatedTile(
                                motion: motion,
                                progress: Curves.easeOutCubic.transform(
                                  _moveController.value,
                                ),
                                cellSize: cellSize,
                                gap: _gap,
                                gameOverProgress: widget.gameOverProgress,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _beginDrag() {
    if (_moveController.isAnimating) {
      return;
    }
    setState(() {
      _dragAxis = null;
      _dragDelta = Offset.zero;
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_moveController.isAnimating) {
      return;
    }

    final nextDelta = _dragDelta + details.delta;
    Axis? nextAxis = _dragAxis;
    if (nextAxis == null) {
      if (nextDelta.dx.abs() > 6 || nextDelta.dy.abs() > 6) {
        nextAxis = nextDelta.dx.abs() >= nextDelta.dy.abs()
            ? Axis.horizontal
            : Axis.vertical;
      }
    }

    setState(() {
      _dragAxis = nextAxis;
      _dragDelta = nextDelta;
    });
  }

  void _endDrag(DragEndDetails details) {
    final direction = _dragDirection(details.primaryVelocity ?? 0);
    setState(() {
      _dragAxis = null;
      _dragDelta = Offset.zero;
    });
    if (direction != null) {
      widget.onSlide(direction);
    }
  }

  void _cancelDrag() {
    setState(() {
      _dragAxis = null;
      _dragDelta = Offset.zero;
    });
  }

  SlideDirection? _dragDirection(double primaryVelocity) {
    final distance = _dragAxis == Axis.horizontal
        ? _dragDelta.dx
        : _dragDelta.dy;
    final commitByDistance = distance.abs() > 28;
    final commitByVelocity = primaryVelocity.abs() > 220;
    if (_dragAxis == null || (!commitByDistance && !commitByVelocity)) {
      return null;
    }

    return switch (_dragAxis!) {
      Axis.horizontal =>
        distance < 0 ? SlideDirection.left : SlideDirection.right,
      Axis.vertical => distance < 0 ? SlideDirection.up : SlideDirection.down,
    };
  }

  Offset _previewOffsetFraction() {
    if (_dragAxis == null || _moveController.isAnimating) {
      return Offset.zero;
    }

    return switch (_dragAxis!) {
      Axis.horizontal => Offset(
        (_dragDelta.dx / 280).clamp(-0.11, 0.11).toDouble(),
        0,
      ),
      Axis.vertical => Offset(
        0,
        (_dragDelta.dy / 280).clamp(-0.11, 0.11).toDouble(),
      ),
    };
  }

  List<_TileMotion> _buildMotions(Board? previousBoard, Board currentBoard) {
    final previousById = <int, Tile>{
      for (final tile in previousBoard?.tiles ?? const <Tile>[]) tile.id: tile,
    };
    return currentBoard.tiles.map((tile) {
      final previous = previousById[tile.id];
      return _TileMotion(
        tile: tile,
        fromRow: previous?.row ?? tile.row,
        fromCol: previous?.col ?? tile.col,
        isNew: previous == null,
        merged: previous != null && previous.value != tile.value,
      );
    }).toList();
  }

  String _signature(Board board) {
    final ordered = board.tiles.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return ordered
        .map((tile) => '${tile.id}:${tile.value}:${tile.row}:${tile.col}')
        .join('|');
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  const _AnimatedTile({
    required this.motion,
    required this.progress,
    required this.cellSize,
    required this.gap,
    required this.gameOverProgress,
  });

  final _TileMotion motion;
  final double progress;
  final double cellSize;
  final double gap;
  final double gameOverProgress;

  @override
  Widget build(BuildContext context) {
    final left = lerpDouble(
      motion.fromCol * (cellSize + gap),
      motion.tile.col * (cellSize + gap),
      progress,
    )!;
    final top = lerpDouble(
      motion.fromRow * (cellSize + gap),
      motion.tile.row * (cellSize + gap),
      progress,
    )!;

    final mergePulse = motion.merged
        ? _pulse(progress, start: 0.68, peak: 1.14)
        : 1.0;
    final spawnPulse = motion.isNew
        ? _pulse(progress, start: 0, peak: 1.08, beginScale: 0.2)
        : 1.0;
    final tileColor = _animatedTileColor(motion.tile.value);
    final textColor = _animatedTextColor(motion.tile.value);

    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: mergePulse * spawnPulse,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.lerp(tileColor, Colors.white, 0.18) ?? tileColor,
                tileColor,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: lerpDouble(0.12, 0.04, _waveProgress)!,
                ),
                blurRadius: 10,
                offset: const Offset(4, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: lerpDouble(0.22, 0.08, _waveProgress)!,
                ),
                blurRadius: 5,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: cellSize,
            child: Center(
              child: Opacity(
                opacity: lerpDouble(1, 0.38, _waveProgress)!,
                child: Text(
                  '${motion.tile.value}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: textColor,
                    fontSize: motion.tile.value >= 1024 ? 28 : 34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _pulse(
    double progress, {
    required double start,
    required double peak,
    double beginScale = 1,
  }) {
    if (progress <= start) {
      return beginScale;
    }
    final normalized = ((progress - start) / (1 - start))
        .clamp(0, 1)
        .toDouble();
    final rise = Curves.easeOutBack.transform(normalized);
    return lerpDouble(beginScale, peak, rise)!;
  }

  double get _waveProgress {
    if (gameOverProgress <= 0) {
      return 0;
    }

    final waveIndex = motion.tile.row + motion.tile.col;
    final start = (waveIndex / 6) * 0.42;
    final normalized = ((gameOverProgress - start) / 0.45).clamp(0, 1);
    return Curves.easeInOut.transform(normalized.toDouble());
  }

  Color _animatedTileColor(int value) {
    final base = _tileColor(value);
    final gray = Color.lerp(base, Colors.grey.shade500, 0.84) ?? base;
    return Color.lerp(base, gray, _waveProgress) ?? base;
  }

  Color _animatedTextColor(int value) {
    final base = value >= 8 ? AppColors.white : AppColors.ink;
    return Color.lerp(
          base,
          AppColors.white.withValues(alpha: 0.8),
          _waveProgress,
        ) ??
        base;
  }

  Color _tileColor(int value) {
    return switch (value) {
      2 => AppColors.sky,
      4 => AppColors.butter,
      8 => AppColors.melon,
      16 => AppColors.coral,
      32 => const Color(0xFFD98557),
      64 => const Color(0xFFCB6D4A),
      128 => const Color(0xFFE5C76B),
      256 => const Color(0xFFD7B95D),
      512 => const Color(0xFFC9AA4F),
      1024 => AppColors.blueberry,
      _ => AppColors.lagoon,
    };
  }
}

class _TileMotion {
  const _TileMotion({
    required this.tile,
    required this.fromRow,
    required this.fromCol,
    required this.isNew,
    required this.merged,
  });

  final Tile tile;
  final int fromRow;
  final int fromCol;
  final bool isNew;
  final bool merged;
}
