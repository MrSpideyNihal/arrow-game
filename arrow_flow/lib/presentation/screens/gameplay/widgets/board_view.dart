import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/arrow_model.dart';
import '../../../../data/models/economy_model.dart';
import '../../../../data/models/level_model.dart';

/// Premium puzzle board with InteractiveViewer zoom/pan, smooth fly-off animations, and particle FX.
class BoardView extends StatefulWidget {
  final Level level;
  final List<Arrow> activeArrows;
  final List<Arrow> selectableArrows;
  final Arrow? hintedArrow;
  final void Function(Arrow) onArrowTap;
  final void Function(Arrow)? onArrowRemoved;
  final bool showGrid;
  final bool isBombMode;
  final bool isRadarActive;
  final TransformationController? transformationController;

  const BoardView({
    super.key,
    required this.level,
    required this.activeArrows,
    required this.selectableArrows,
    this.hintedArrow,
    required this.onArrowTap,
    this.onArrowRemoved,
    this.showGrid = false,
    this.isBombMode = false,
    this.isRadarActive = false,
    this.transformationController,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  final Map<int, AnimationController> _exitControllers = {};
  final Map<int, Arrow> _exitingArrows = {};
  final Map<int, AnimationController> _shakeControllers = {};
  final Map<int, AnimationController> _popControllers = {};

  late final TransformationController _transformController;
  double _currentScale = 1.0;

  /// Repaint notifier used by the CustomPainter to listen for animation changes.
  final _repaint = _RepaintNotifier();

  @override
  void initState() {
    super.initState();
    _transformController = widget.transformationController ?? TransformationController();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  void _handleDoubleTap(Offset position, double cellSize) {
    if (_currentScale > 1.1) {
      _resetZoom();
    } else {
      // Zoom in centered on tap position
      final matrix = Matrix4.identity()
        ..translate(-position.dx * 1.0, -position.dy * 1.0)
        ..scale(2.0);
      _transformController.value = matrix;
      setState(() => _currentScale = 2.0);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    if (widget.transformationController == null) {
      _transformController.dispose();
    }
    for (final c in _exitControllers.values) {
      c.dispose();
    }
    for (final c in _shakeControllers.values) {
      c.dispose();
    }
    for (final c in _popControllers.values) {
      c.dispose();
    }
    _repaint.dispose();
    super.dispose();
  }

  void _addExitAnimation(Arrow arrow) {
    if (_exitControllers.containsKey(arrow.id)) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _exitControllers[arrow.id] = controller;
    _exitingArrows[arrow.id] = arrow;

    controller.addListener(() => _repaint.notify());
    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _exitControllers.remove(arrow.id)?.dispose();
          _exitingArrows.remove(arrow.id);
        });
        widget.onArrowRemoved?.call(arrow);
      }
    });
    setState(() {});
  }

  void _addShakeAnimation(Arrow arrow) {
    if (_shakeControllers.containsKey(arrow.id)) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _shakeControllers[arrow.id] = controller;
    controller.addListener(() => _repaint.notify());
    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _shakeControllers.remove(arrow.id)?.dispose();
        });
      }
    });
    setState(() {});
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.activeArrows.map((a) => a.id).toSet();
    final newIds = widget.activeArrows.map((a) => a.id).toSet();
    final removedIds = oldIds.difference(newIds);

    for (final id in removedIds) {
      if (!_exitControllers.containsKey(id)) {
        final arrow = oldWidget.activeArrows.firstWhere((a) => a.id == id);
        _addExitAnimation(arrow);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final skinId = storage.getSetting<String>('active_skin', defaultValue: 'arrow_default')!;
    final themeId = storage.getSetting<String>('active_theme', defaultValue: 'theme_default')!;

    final skinItem = CosmeticItem.catalog.firstWhere(
      (item) => item.id == skinId,
      orElse: () => CosmeticItem.catalog.first,
    );
    final themeItem = CosmeticItem.catalog.firstWhere(
      (item) => item.id == themeId,
      orElse: () => CosmeticItem.catalog.firstWhere((i) => i.id == 'theme_default'),
    );

    final containerColor = _parseColor(themeItem.containerColorHex ?? '#0B1E30');
    final accentGlowColor = widget.isBombMode
        ? const Color(0xFFEF4444)
        : (widget.isRadarActive ? const Color(0xFF06B6D4) : _parseColor(themeItem.primaryColorHex));

    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / widget.level.gridWidth;
      final cellH = constraints.maxHeight / widget.level.gridHeight;
      final cellSize = cellW < cellH ? cellW : cellH;

      final boardWidth = cellSize * widget.level.gridWidth;
      final boardHeight = cellSize * widget.level.gridHeight;

      return Center(
        child: Container(
          width: boardWidth,
          height: boardHeight,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
            border: widget.isBombMode
                ? Border.all(color: const Color(0xFFEF4444), width: 2.5)
                : (widget.isRadarActive
                    ? Border.all(color: const Color(0xFF06B6D4), width: 2.5)
                    : null),
            boxShadow: [
              BoxShadow(
                color: accentGlowColor.withValues(alpha: widget.isBombMode || widget.isRadarActive ? 0.45 : 0.25),
                blurRadius: widget.isBombMode || widget.isRadarActive ? 36 : 28,
                spreadRadius: widget.isBombMode || widget.isRadarActive ? 5 : 3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTap(details.localPosition, cellSize),
              child: AnimatedBuilder(
                animation: _repaint,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BoardPainter(
                      gridWidth: widget.level.gridWidth,
                      gridHeight: widget.level.gridHeight,
                      cellSize: cellSize,
                      activeArrows: widget.activeArrows,
                      selectableArrows: widget.selectableArrows,
                      hintedArrow: widget.hintedArrow,
                      exitingArrows: _exitingArrows,
                      exitControllers: _exitControllers,
                      shakeControllers: _shakeControllers,
                      showGrid: widget.showGrid,
                      skinItem: skinItem,
                      themeItem: themeItem,
                      isBombMode: widget.isBombMode,
                      isRadarActive: widget.isRadarActive,
                    ),
                    size: Size(boardWidth, boardHeight),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  void _handleTap(Offset position, double cellSize) {
    final tappedX = (position.dx / cellSize).floor();
    final tappedY = (position.dy / cellSize).floor();

    // 1. Direct exact cell hit
    for (final arrow in widget.activeArrows) {
      for (final (cx, cy) in arrow.cells) {
        if (cx == tappedX && cy == tappedY) {
          if (!widget.isBombMode) {
            final isSelectable = widget.selectableArrows.contains(arrow);
            if (!isSelectable) {
              _addShakeAnimation(arrow);
            }
          }
          widget.onArrowTap(arrow);
          return;
        }
      }
    }

    // 2. Proximity search for compact mobile touch targets
    Arrow? closestArrow;
    double minDistanceSq = double.infinity;
    final maxTouchRadiusSq = (cellSize * 1.35) * (cellSize * 1.35);

    for (final arrow in widget.activeArrows) {
      for (final (cx, cy) in arrow.cells) {
        final cellCenterX = cx * cellSize + cellSize / 2;
        final cellCenterY = cy * cellSize + cellSize / 2;
        final dx = position.dx - cellCenterX;
        final dy = position.dy - cellCenterY;
        final distSq = dx * dx + dy * dy;

        if (distSq < maxTouchRadiusSq && distSq < minDistanceSq) {
          minDistanceSq = distSq;
          closestArrow = arrow;
        }
      }
    }

    if (closestArrow != null) {
      if (!widget.isBombMode) {
        final isSelectable = widget.selectableArrows.contains(closestArrow);
        if (!isSelectable) {
          _addShakeAnimation(closestArrow);
        }
      }
      widget.onArrowTap(closestArrow);
    }
  }
}

/// Custom ChangeNotifier to drive animation repaints without rebuilding the widget tree.
class _RepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// High-quality custom painter with grid, glow effects, and smooth fly-off animations.
class _BoardPainter extends CustomPainter {
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  final List<Arrow> activeArrows;
  final List<Arrow> selectableArrows;
  final Arrow? hintedArrow;
  final Map<int, Arrow> exitingArrows;
  final Map<int, AnimationController> exitControllers;
  final Map<int, AnimationController> shakeControllers;
  final bool showGrid;
  final CosmeticItem skinItem;
  final CosmeticItem themeItem;
  final bool isBombMode;
  final bool isRadarActive;

  _BoardPainter({
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
    required this.activeArrows,
    required this.selectableArrows,
    this.hintedArrow,
    required this.exitingArrows,
    required this.exitControllers,
    required this.shakeControllers,
    required this.showGrid,
    required this.skinItem,
    required this.themeItem,
    this.isBombMode = false,
    this.isRadarActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // Draw all active arrows
    for (final arrow in activeArrows) {
      if (exitingArrows.containsKey(arrow.id)) continue;

      final shakeCtrl = shakeControllers[arrow.id];
      Offset shakeOffset = Offset.zero;
      bool isShaking = false;

      if (shakeCtrl != null) {
        isShaking = true;
        final t = shakeCtrl.value;
        final dx = sin(t * pi * 8) * (cellSize * 0.18) * (1.0 - t);
        shakeOffset = Offset(dx, 0);
      }

      final isHinted = hintedArrow?.id == arrow.id;
      final isSelectable = selectableArrows.contains(arrow);

      // Draw radar scan highlight aura
      if (isRadarActive && isSelectable) {
        final radarGlow = Paint()
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        for (final (cx, cy) in arrow.cells) {
          canvas.drawCircle(
            Offset(cx * cellSize + cellSize / 2 + shakeOffset.dx,
                cy * cellSize + cellSize / 2 + shakeOffset.dy),
            cellSize * 0.55,
            radarGlow,
          );
        }
      }

      _paintArrow(
        canvas,
        arrow,
        isSelectable,
        isHinted,
        shakeOffset,
        1.0,
        isShaking: isShaking,
      );
    }

    // Draw fly-off animations with glittering star particles
    for (final entry in exitingArrows.entries) {
      final arrow = entry.value;
      final ctrl = exitControllers[entry.key];
      if (ctrl == null) continue;

      final t = ctrl.value;
      final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);

      _paintExitingArrow(canvas, arrow, t, opacity);
    }
  }

  void _paintExitingArrow(Canvas canvas, Arrow arrow, double t, double opacity) {
    if (arrow.cells.isEmpty) return;

    final half = cellSize / 2;
    final strokeW = cellSize * 0.22;

    // 1. Build track path starting from tail to head
    final trackPath = Path();
    final first = arrow.cells.first;
    trackPath.moveTo(
        first.$1 * cellSize + half,
        first.$2 * cellSize + half);

    for (int i = 1; i < arrow.cells.length; i++) {
      final cell = arrow.cells[i];
      trackPath.lineTo(
          cell.$1 * cellSize + half,
          cell.$2 * cellSize + half);
    }

    final (dx, dy) = arrow.direction.delta;
    final head = arrow.head;
    trackPath.lineTo(
        (head.$1 + dx * 20) * cellSize + half,
        (head.$2 + dy * 20) * cellSize + half);

    // 2. Extract metrics
    final pathMetrics = trackPath.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final totalLength = metric.length;
    final arrowLen = (arrow.cells.length - 1) * cellSize;

    // 3. Calculate segment to extract based on animation progress t
    final headStart = arrowLen;
    final headEnd = totalLength;
    final currentHeadDist = headStart + t * (headEnd - headStart);
    final currentTailDist = (currentHeadDist - arrowLen).clamp(0.0, totalLength);

    // Shorten the body line so it doesn't protrude into the arrowhead tip
    final lineEndDist = (currentHeadDist - cellSize * 0.18).clamp(currentTailDist, totalLength);
    final arrowPath = metric.extractPath(currentTailDist, lineEndDist);
    final skinPrimary = _parseColor(skinItem.primaryColorHex);
    final bodyColor = skinPrimary.withValues(alpha: opacity);

    // Glow under the sliding arrow
    if (opacity > 0.4) {
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = skinPrimary.withValues(alpha: 0.35 * opacity)
          ..strokeWidth = strokeW * 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Draw body stroke
    final bodyPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(arrowPath, bodyPaint);

    // Draw tail dot (only for multi-cell arrows)
    if (arrow.cells.length > 1) {
      final tailTangent = metric.getTangentForOffset(currentTailDist);
      if (tailTangent != null) {
        canvas.drawCircle(
          tailTangent.position,
          strokeW * 0.52,
          Paint()
            ..color = bodyColor
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Draw arrowhead pointing along tangent direction + sparkling particle trail
    final headTangent = metric.getTangentForOffset(currentHeadDist);
    if (headTangent != null) {
      final hPos = headTangent.position;
      final angle = headTangent.angle;
      final hs = cellSize * 0.36;

      // Draw sparkle particles around arrowhead
      if (opacity > 0.2) {
        final sparkPaint = Paint()..style = PaintingStyle.fill;
        for (int p = 0; p < 6; p++) {
          final sparkDist = (p * 8.0 + (t * 40)) % 30;
          final sparkAngle = angle + pi + (p - 2.5) * 0.4;
          final sparkX = hPos.dx + cos(sparkAngle) * sparkDist;
          final sparkY = hPos.dy + sin(sparkAngle) * sparkDist;
          final sparkColor = (p % 2 == 0 ? const Color(0xFFFDE047) : const Color(0xFF60A5FA))
              .withValues(alpha: (opacity * (1.0 - sparkDist / 30)).clamp(0.0, 1.0));
          sparkPaint.color = sparkColor;
          canvas.drawCircle(Offset(sparkX, sparkY), (2.5 - p * 0.25).clamp(1.0, 3.0), sparkPaint);
        }
      }

      canvas.save();
      canvas.translate(hPos.dx, hPos.dy);
      canvas.rotate(angle);

      final headPath = Path();
      headPath.moveTo(hs, 0);
      headPath.lineTo(-hs * 0.3, -hs * 0.68);
      headPath.lineTo(-hs * 0.3, hs * 0.68);
      headPath.close();

      canvas.drawPath(
        headPath,
        Paint()
          ..color = bodyColor
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (!showGrid) return;

    final isWhiteContainer = themeItem.containerColorHex?.toUpperCase() == '#FFFFFF' ||
        themeItem.id == 'theme_cute_pink';
    final lineBaseColor = isWhiteContainer ? const Color(0xFFF472B6) : Colors.white;

    final cellPaint = Paint()
      ..color = lineBaseColor.withValues(alpha: isWhiteContainer ? 0.22 : 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineBaseColor.withValues(alpha: isWhiteContainer ? 0.40 : 0.25)
      ..style = PaintingStyle.fill;

    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        final rect = Rect.fromLTWH(
          x * cellSize + 1,
          y * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          cellPaint,
        );

        // Center dot
        canvas.drawCircle(
          Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2),
          1.5,
          dotPaint,
        );
      }
    }
  }

  void _paintArrow(
    Canvas canvas,
    Arrow arrow,
    bool isSelectable,
    bool isHinted,
    Offset offset,
    double opacity, {
    bool isShaking = false,
  }) {
    if (arrow.cells.isEmpty) return;

    final half = cellSize / 2;
    final strokeW = cellSize * 0.22;

    // Color scheme from active Cosmetic Skin: ALL ARROWS SHARE UNIFORM COLOR
    final skinPrimary = _parseColor(skinItem.primaryColorHex);

    Color bodyColor;
    if (isShaking) {
      bodyColor = const Color(0xFFEF4444).withValues(alpha: opacity);
    } else if (isHinted) {
      bodyColor = const Color(0xFFF59E0B).withValues(alpha: opacity);
    } else if (isRadarActive && isSelectable) {
      bodyColor = const Color(0xFF06B6D4).withValues(alpha: opacity);
    } else {
      bodyColor = skinPrimary.withValues(alpha: opacity);
    }

    // Glow is ONLY shown when player activates Radar Booster or Hint (no default giveaways)
    if ((isRadarActive && isSelectable || isHinted) && !isShaking && opacity > 0.4) {
      final glowColor = isHinted ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      for (final (cx, cy) in arrow.cells) {
        canvas.drawCircle(
          Offset(cx * cellSize + half + offset.dx,
              cy * cellSize + half + offset.dy),
          cellSize * 0.46,
          glowPaint,
        );
      }
    }

    final isWhiteContainer = themeItem.containerColorHex?.toUpperCase() == '#FFFFFF' ||
        themeItem.id == 'theme_cute_pink';
    final outlineColor = isWhiteContainer
        ? const Color(0xFFF472B6).withValues(alpha: opacity * 0.25)
        : const Color(0xFF0F172A).withValues(alpha: opacity * 0.5);

    // Draw outline stroke under arrow body
    final outlinePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = strokeW + 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final first = arrow.cells.first;
    path.moveTo(
        first.$1 * cellSize + half + offset.dx,
        first.$2 * cellSize + half + offset.dy);

    for (int i = 1; i < arrow.cells.length; i++) {
      final cell = arrow.cells[i];
      if (i == arrow.cells.length - 1) {
        // Shorten the last segment slightly so the round cap does not overlap the arrowhead tip
        final (dx, dy) = arrow.direction.delta;
        final targetX = cell.$1 * cellSize + half + offset.dx - dx * cellSize * 0.18;
        final targetY = cell.$2 * cellSize + half + offset.dy - dy * cellSize * 0.18;
        path.lineTo(targetX, targetY);
      } else {
        path.lineTo(
            cell.$1 * cellSize + half + offset.dx,
            cell.$2 * cellSize + half + offset.dy);
      }
    }
    canvas.drawPath(path, outlinePaint);
    canvas.drawPath(path, bodyPaint);

    // Tail dot (round cap accent - only for multi-cell arrows)
    if (arrow.cells.length > 1) {
      final tail = arrow.cells.first;
      canvas.drawCircle(
        Offset(tail.$1 * cellSize + half + offset.dx,
            tail.$2 * cellSize + half + offset.dy),
        strokeW * 0.52,
        Paint()
          ..color = bodyColor
          ..style = PaintingStyle.fill,
      );
    }

    // Arrowhead at head cell
    _drawArrowhead(canvas, arrow, half, offset, bodyColor, outlineColor, strokeW);
  }

  void _drawArrowhead(Canvas canvas, Arrow arrow, double half, Offset offset,
      Color color, Color outlineColor, double strokeW) {
    final head = arrow.head;
    final hx = head.$1 * cellSize + half + offset.dx;
    final hy = head.$2 * cellSize + half + offset.dy;
    final hs = cellSize * 0.36;

    final headPath = Path();
    switch (arrow.direction) {
      case Direction.up:
        headPath.moveTo(hx, hy - hs);
        headPath.lineTo(hx - hs * 0.65, hy + hs * 0.30);
        headPath.lineTo(hx + hs * 0.65, hy + hs * 0.30);
      case Direction.down:
        headPath.moveTo(hx, hy + hs);
        headPath.lineTo(hx - hs * 0.65, hy - hs * 0.30);
        headPath.lineTo(hx + hs * 0.65, hy - hs * 0.30);
      case Direction.left:
        headPath.moveTo(hx - hs, hy);
        headPath.lineTo(hx + hs * 0.30, hy - hs * 0.65);
        headPath.lineTo(hx + hs * 0.30, hy + hs * 0.65);
      case Direction.right:
        headPath.moveTo(hx + hs, hy);
        headPath.lineTo(hx - hs * 0.30, hy - hs * 0.65);
        headPath.lineTo(hx - hs * 0.30, hy + hs * 0.65);
    }
    headPath.close();

    // Outline matching the body line stroke
    canvas.drawPath(
      headPath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Filled arrowhead
    canvas.drawPath(
      headPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}

Color _parseColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('FF');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
