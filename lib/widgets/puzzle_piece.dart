import 'package:flutter/material.dart';
import '../theme.dart';

enum PuzzleSide { flat, tab, socket }

/// Quanto il “maschio” sporge: serve anche per sovrapporre i pezzi in colonna.
const double kPuzzleKnob = 18.0;
const double kPuzzleThickness = 7.0;

class PuzzlePiece extends StatelessWidget {
  final Color color;
  final PuzzleSide top;
  final PuzzleSide bottom;
  final PuzzleSide left;
  final PuzzleSide right;
  final Widget? child;
  final bool outline;
  final EdgeInsetsGeometry? padding;

  const PuzzlePiece({
    super.key,
    required this.color,
    this.top = PuzzleSide.flat,
    this.bottom = PuzzleSide.tab,
    this.left = PuzzleSide.flat,
    this.right = PuzzleSide.tab,
    this.child,
    this.outline = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PuzzlePiecePainter(
        color: color,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        isOutline: outline,
      ),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              14 + (left == PuzzleSide.tab ? kPuzzleKnob : 0),
              12 + (top == PuzzleSide.tab ? kPuzzleKnob : 0),
              14 + (right == PuzzleSide.tab ? kPuzzleKnob : 0),
              12 +
                  (bottom == PuzzleSide.tab ? kPuzzleKnob : 0) +
                  kPuzzleThickness,
            ),
        child: child,
      ),
    );
  }
}

class PuzzlePiecePainter extends CustomPainter {
  final Color color;
  final PuzzleSide top, bottom, left, right;
  final bool isOutline;

  PuzzlePiecePainter({
    required this.color,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    this.isOutline = false,
  });

  Path _buildPath(Size size) {
    final knob = kPuzzleKnob;
    final leftInset = left == PuzzleSide.tab ? knob : 0.0;
    final rightInset = right == PuzzleSide.tab ? knob : 0.0;
    final topInset = top == PuzzleSide.tab ? knob : 0.0;
    final bottomInset = bottom == PuzzleSide.tab ? knob : kPuzzleThickness;

    final body = Rect.fromLTRB(
      leftInset,
      topInset,
      size.width - rightInset,
      size.height - bottomInset,
    );

    final radius = (body.shortestSide * 0.22).clamp(16.0, 28.0);
    Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));

    Path bump(Offset center) =>
        Path()..addOval(Rect.fromCircle(center: center, radius: knob));

    void unionEdge(PuzzleSide side, Offset center) {
      if (side == PuzzleSide.tab) {
        path = Path.combine(PathOperation.union, path, bump(center));
      } else if (side == PuzzleSide.socket) {
        path = Path.combine(PathOperation.difference, path, bump(center));
      }
    }

    unionEdge(top, Offset(body.center.dx, body.top));
    unionEdge(right, Offset(body.right, body.center.dy));
    unionEdge(bottom, Offset(body.center.dx, body.bottom));
    unionEdge(left, Offset(body.left, body.center.dy));
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    if (isOutline) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final dark = Color.lerp(color, const Color(0xFF3A2A20), 0.28)!;
    final light = Color.lerp(color, Colors.white, 0.42)!;

    canvas.drawShadow(
      path.shift(const Offset(0, 4)),
      Colors.black.withValues(alpha: 0.28),
      10,
      false,
    );

    // Spessore 3D sotto il pezzo
    canvas.drawPath(path.shift(const Offset(1.5, kPuzzleThickness)), Paint()..color = dark);

    canvas.drawPath(path, Paint()..color = color);

    canvas.save();
    canvas.clipPath(path);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.16),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    // Reflex lucido in alto
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.22),
        width: size.width * 0.7,
        height: size.height * 0.38,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = light.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant PuzzlePiecePainter old) {
    return old.color != color ||
        old.top != top ||
        old.bottom != bottom ||
        old.left != left ||
        old.right != right ||
        old.isOutline != isOutline;
  }
}

class MiniPuzzleChip extends StatelessWidget {
  final String titolo;
  final String? subtitle;
  final Color color;

  const MiniPuzzleChip({
    super.key,
    required this.titolo,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PuzzlePiece(
      color: color,
      top: PuzzleSide.flat,
      left: PuzzleSide.socket,
      right: PuzzleSide.tab,
      bottom: PuzzleSide.tab,
      padding: const EdgeInsets.fromLTRB(14, 10, 22, 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titolo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1.15,
                color: AppColors.onPuzzle(color),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPuzzle(color).withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
