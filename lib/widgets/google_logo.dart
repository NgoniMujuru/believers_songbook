import 'package:flutter/material.dart';

/// Draws a more accurate Google "G" logo.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double cx = s / 2;
    final double cy = s / 2;
    final double r = s * 0.45; // outer radius
    final double strokeW = s * 0.18; // arc stroke width

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, _deg(-45), _deg(135), false, paint);

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, _deg(90), _deg(90), false, paint);

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, _deg(180), _deg(45), false, paint);

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, _deg(225), _deg(90), false, paint);

    // Horizontal "G" bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barLength = r * 1.2;
    final double barHeight = strokeW * 0.9;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx + r * 0.2, cy),
        width: barLength,
        height: barHeight,
      ),
      barPaint,
    );
  }

  static double _deg(double degrees) => degrees * 3.1415926535897932 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}