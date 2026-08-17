import 'package:flutter/material.dart';
import '../../../../data/models/arrow_model.dart';

/// Renders a single arrow on the puzzle board.
///
/// Draws the arrow as a polyline path with an arrowhead indicator.
/// Selectable arrows get the accent glow; blocked arrows stay muted.
/// The exit animation slides the arrow off-screen along its exit direction.
class ArrowWidget extends StatelessWidget {
  final Arrow arrow;
  final bool isSelectable;
  final bool isHinted;
  final double cellSize;
  final VoidCallback onTap;

  const ArrowWidget({
    super.key,
    required this.arrow,
    required this.isSelectable,
    required this.isHinted,
    required this.cellSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Arrow colors from theme.
    final baseColor = theme.colorScheme.onSurface;
    final accentColor = theme.colorScheme.primary;

    // Selectable arrows get the accent glow.
    final arrowColor = isSelectable ? accentColor : baseColor.withValues(alpha: 0.5);
    final glowColor = isHinted
        ? accentColor.withValues(alpha: 0.6)
        : (isSelectable ? accentColor.withValues(alpha: 0.15) : Colors.transparent);

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _ArrowPainter(
          arrow: arrow,
          cellSize: cellSize,
          color: arrowColor,
          glowColor: glowColor,
          strokeWidth: isSelectable ? 3.5 : 2.5,
          isDark: isDark,
        ),
        size: Size(
          arrow.cells.map((c) => c.$1).reduce((a, b) => a > b ? a : b) * cellSize + cellSize,
          arrow.cells.map((c) => c.$2).reduce((a, b) => a > b ? a : b) * cellSize + cellSize,
        ),
      ),
    );
  }
}

/// Custom painter that draws an arrow as a path with an arrowhead.
class _ArrowPainter extends CustomPainter {
  final Arrow arrow;
  final double cellSize;
  final Color color;
  final Color glowColor;
  final double strokeWidth;
  final bool isDark;

  _ArrowPainter({
    required this.arrow,
    required this.cellSize,
    required this.color,
    required this.glowColor,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (arrow.cells.isEmpty) return;

    final half = cellSize / 2;

    // Draw glow behind the arrow if selectable/hinted.
    if (glowColor != Colors.transparent) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      for (final cell in arrow.cells) {
        canvas.drawCircle(
          Offset(cell.$1 * cellSize + half, cell.$2 * cellSize + half),
          cellSize * 0.35,
          glowPaint,
        );
      }
    }

    // Draw the arrow body as connected line segments.
    final bodyPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final firstCell = arrow.cells.first;
    path.moveTo(firstCell.$1 * cellSize + half, firstCell.$2 * cellSize + half);

    for (int i = 1; i < arrow.cells.length; i++) {
      final cell = arrow.cells[i];
      path.lineTo(cell.$1 * cellSize + half, cell.$2 * cellSize + half);
    }
    canvas.drawPath(path, bodyPaint);

    // Draw circle nodes at each cell.
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final cell in arrow.cells) {
      canvas.drawCircle(
        Offset(cell.$1 * cellSize + half, cell.$2 * cellSize + half),
        cellSize * 0.12,
        nodePaint,
      );
    }

    // Draw the arrowhead at the head cell.
    _drawArrowhead(canvas, arrow.head, arrow.direction, half);
  }

  void _drawArrowhead(
    Canvas canvas,
    (int, int) head,
    Direction direction,
    double half,
  ) {
    final hx = head.$1 * cellSize + half;
    final hy = head.$2 * cellSize + half;
    final headSize = cellSize * 0.3;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case Direction.up:
        path.moveTo(hx, hy - headSize);
        path.lineTo(hx - headSize * 0.6, hy + headSize * 0.3);
        path.lineTo(hx + headSize * 0.6, hy + headSize * 0.3);
      case Direction.down:
        path.moveTo(hx, hy + headSize);
        path.lineTo(hx - headSize * 0.6, hy - headSize * 0.3);
        path.lineTo(hx + headSize * 0.6, hy - headSize * 0.3);
      case Direction.left:
        path.moveTo(hx - headSize, hy);
        path.lineTo(hx + headSize * 0.3, hy - headSize * 0.6);
        path.lineTo(hx + headSize * 0.3, hy + headSize * 0.6);
      case Direction.right:
        path.moveTo(hx + headSize, hy);
        path.lineTo(hx - headSize * 0.3, hy - headSize * 0.6);
        path.lineTo(hx - headSize * 0.3, hy + headSize * 0.6);
    }

    path.close();
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
