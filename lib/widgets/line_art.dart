import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Hand-drawn style line illustrations for the Home shortcuts.
///
/// Each one is drawn on a 48×48 grid in a single ink colour (navy, or warm
/// light in dark mode) with one gold accent, on a soft organic wash.
enum LineArtKind { lamp, prayingHands, chapel, openBible }

class LineArt extends StatelessWidget {
  const LineArt(this.kind, {super.key, this.size = 64, required this.wash});
  final LineArtKind kind;
  final double size;

  /// Colour of the soft shape behind the drawing.
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _LineArtPainter(
        kind,
        ink: dark ? const Color(0xFFEDE3D2) : BethelColors.forest,
        wash: wash,
      ),
    );
  }
}

class _LineArtPainter extends CustomPainter {
  _LineArtPainter(this.kind, {required this.ink, required this.wash});
  final LineArtKind kind;
  final Color ink;
  final Color wash;

  static const gold = BethelColors.brass;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);

    // Soft, slightly irregular wash – like a brush dab rather than a perfect circle.
    final blob = Path()
      ..moveTo(26, 5)
      ..cubicTo(37, 4, 45, 13, 44, 25)
      ..cubicTo(43, 37, 34, 45, 23, 44)
      ..cubicTo(11, 43, 4, 34, 5, 23)
      ..cubicTo(6, 12, 15, 6, 26, 5)
      ..close();
    canvas.drawPath(blob, Paint()..color = wash);

    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fine = Paint()
      ..color = ink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final goldFill = Paint()..color = gold;
    final goldLine = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case LineArtKind.lamp:
        // Glow + flame sitting on the spout.
        canvas.drawCircle(const Offset(11, 17.5), 7, Paint()..color = gold.withValues(alpha: 0.2));
        canvas.drawPath(
          Path()
            ..moveTo(10.5, 24.5)
            ..cubicTo(6.5, 21, 8, 15.5, 11.5, 10)
            ..cubicTo(14.5, 15.5, 15.5, 21, 10.5, 24.5)
            ..close(),
          goldFill,
        );
        // Round clay oil lamp with a pointed spout.
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 26.5)
            ..cubicTo(12.5, 25.8, 16, 26.5, 19, 27.5)
            ..cubicTo(23.5, 24.2, 32.5, 23.8, 38, 27.5)
            ..cubicTo(43, 31, 41.5, 38, 33.5, 40)
            ..cubicTo(26.5, 41.5, 20, 40, 17, 36)
            ..cubicTo(15, 33, 12.5, 29.5, 9.5, 26.5)
            ..close(),
          line,
        );
        // Filling hole, a decorative band and the foot.
        canvas.drawOval(Rect.fromCenter(center: const Offset(29, 27.6), width: 6, height: 2.6), fine);
        canvas.drawPath(
          Path()
            ..moveTo(20, 32.5)
            ..cubicTo(25, 34.2, 32, 34.2, 39.5, 32),
          fine,
        );
        canvas.drawLine(const Offset(25, 43), const Offset(32.5, 43), line);
        break;

      case LineArtKind.prayingHands:
        // Gold halo behind the fingertips.
        canvas.drawArc(Rect.fromCircle(center: const Offset(24, 15), radius: 10.5), 3.5, 2.42, false, goldLine);
        canvas.drawCircle(const Offset(11.5, 12.5), 1.3, goldFill);
        canvas.drawCircle(const Offset(36.5, 12.5), 1.3, goldFill);
        // Two palms pressed together: a soft leaf shape.
        canvas.drawPath(
          Path()
            ..moveTo(15.5, 39.5)
            ..cubicTo(14.8, 31, 17, 20.5, 24, 8.5)
            ..cubicTo(31, 20.5, 33.2, 31, 32.5, 39.5),
          line,
        );
        canvas.drawLine(const Offset(24, 10.5), const Offset(24, 38), fine);
        // Gaps between the fingers.
        // (distance of the outline from the centre at height y)
        for (final (y, half) in [(18.5, 4.4), (23.5, 6.0)]) {
          canvas.drawLine(Offset(24 - half, y), Offset(24 - half + 2.8, y + 1.2), fine);
          canvas.drawLine(Offset(24 + half, y), Offset(24 + half - 2.8, y + 1.2), fine);
        }
        // Thumbs resting along the middle.
        canvas.drawPath(
          Path()
            ..moveTo(17.2, 36)
            ..cubicTo(18, 31.5, 20.5, 28.8, 23.2, 29.4),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(30.8, 36)
            ..cubicTo(30, 31.5, 27.5, 28.8, 24.8, 29.4),
          line,
        );
        // Sleeve cuffs.
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTRB(14, 39, 34, 43.5), const Radius.circular(2)),
          line,
        );
        break;

      case LineArtKind.chapel:
        // Gold cross on the steeple.
        canvas.drawLine(const Offset(24, 3.5), const Offset(24, 12), goldLine);
        canvas.drawLine(const Offset(20.8, 6.6), const Offset(27.2, 6.6), goldLine);
        // Roof and walls.
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 24.5)
            ..lineTo(24, 12.5)
            ..lineTo(38.5, 24.5),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13, 22)
            ..lineTo(13, 41)
            ..moveTo(35, 22)
            ..lineTo(35, 41),
          line,
        );
        // Arched door and round window.
        canvas.drawPath(
          Path()
            ..moveTo(20, 41)
            ..lineTo(20, 34)
            ..arcToPoint(const Offset(28, 34), radius: const Radius.circular(4))
            ..lineTo(28, 41),
          line,
        );
        canvas.drawCircle(const Offset(24, 25), 2.6, goldLine..strokeWidth = 1.8);
        // Ground.
        canvas.drawLine(const Offset(6, 41), const Offset(42, 41), line);
        canvas.drawLine(const Offset(38.5, 41), const Offset(43, 41), fine);
        break;

      case LineArtKind.openBible:
        // Gold ribbon marker hanging from the spine.
        canvas.drawPath(
          Path()
            ..moveTo(25.6, 35)
            ..lineTo(25.6, 45)
            ..lineTo(27.6, 43.2)
            ..lineTo(29.6, 45)
            ..lineTo(29.6, 35.6)
            ..close(),
          goldFill,
        );
        // Two gently curved pages.
        canvas.drawPath(
          Path()
            ..moveTo(24, 15)
            ..cubicTo(19, 11.8, 11.5, 11.8, 6, 13.8)
            ..lineTo(6, 36)
            ..cubicTo(11.5, 34, 19, 34, 24, 37.2)
            ..cubicTo(29, 34, 36.5, 34, 42, 36)
            ..lineTo(42, 13.8)
            ..cubicTo(36.5, 11.8, 29, 11.8, 24, 15)
            ..lineTo(24, 37.2),
          line,
        );
        // Lines of text.
        for (final y in [19.0, 23.5, 28.0]) {
          canvas.drawLine(Offset(10, y), Offset(20, y + 0.8), fine);
          canvas.drawLine(Offset(28, y + 0.8), Offset(38, y), fine);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_LineArtPainter old) => old.kind != kind || old.ink != ink || old.wash != wash;
}
