import 'package:flutter/material.dart';

/// Pixel-perfect vector brand icons for Google, GitHub, and Microsoft
class BrandIcons {
  BrandIcons._();

  static Widget google({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }

  static Widget github({double size = 20, Color color = const Color(0xFF181717)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GithubPainter(color: color),
      ),
    );
  }

  static Widget microsoft({double size = 18}) {
    final boxSize = (size - 2) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFFF25022), // Red
              ),
              const SizedBox(width: 2),
              Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFF7FBA00), // Green
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFF00A4EF), // Blue
              ),
              const SizedBox(width: 2),
              Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFFFFB900), // Yellow
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius - strokeWidth / 2);

    // Blue section (Right to bottom-right, + bar)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Green section (Bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Yellow section (Bottom-left to left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red section (Top to top-left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Arcs
    canvas.drawArc(rect, -0.4, 0.9, false, bluePaint);
    canvas.drawArc(rect, 0.5, 1.25, false, greenPaint);
    canvas.drawArc(rect, 1.75, 1.25, false, yellowPaint);
    canvas.drawArc(rect, 3.0, 1.88, false, redPaint);

    // Center horizontal bar for Google 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTRB(
      cx - strokeWidth * 0.2,
      cy - strokeWidth / 2,
      size.width,
      cy + strokeWidth / 2,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GithubPainter extends CustomPainter {
  final Color color;
  _GithubPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Scaled official GitHub mark path
    final path = Path();
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.224, 0, 0, h * 0.224, 0, h * 0.5);
    path.cubicTo(0, h * 0.721, w * 0.143, h * 0.908, w * 0.342, h * 0.974);
    path.cubicTo(w * 0.367, h * 0.979, w * 0.376, h * 0.963, w * 0.376, h * 0.95);
    path.cubicTo(w * 0.376, h * 0.938, w * 0.376, h * 0.898, w * 0.375, h * 0.854);
    path.cubicTo(w * 0.236, h * 0.884, w * 0.207, h * 0.796, w * 0.207, h * 0.796);
    path.cubicTo(w * 0.184, h * 0.738, w * 0.152, h * 0.722, w * 0.152, h * 0.722);
    path.cubicTo(w * 0.107, h * 0.691, w * 0.155, h * 0.692, w * 0.155, h * 0.692);
    path.cubicTo(w * 0.205, h * 0.696, w * 0.231, h * 0.744, w * 0.231, h * 0.744);
    path.cubicTo(w * 0.275, h * 0.819, w * 0.346, h * 0.797, w * 0.374, h * 0.785);
    path.cubicTo(w * 0.378, h * 0.753, w * 0.391, h * 0.731, w * 0.405, h * 0.718);
    path.cubicTo(w * 0.294, h * 0.706, w * 0.178, h * 0.663, w * 0.178, h * 0.471);
    path.cubicTo(w * 0.178, h * 0.417, w * 0.197, h * 0.372, w * 0.229, h * 0.337);
    path.cubicTo(w * 0.224, h * 0.324, w * 0.207, h * 0.273, w * 0.234, h * 0.206);
    path.cubicTo(w * 0.234, h * 0.206, w * 0.276, h * 0.193, w * 0.371, h * 0.257);
    path.cubicTo(w * 0.411, h * 0.246, w * 0.453, h * 0.241, w * 0.495, h * 0.241);
    path.cubicTo(w * 0.537, h * 0.241, w * 0.58, h * 0.246, w * 0.62, h * 0.257);
    path.cubicTo(w * 0.714, h * 0.193, w * 0.756, h * 0.206, w * 0.756, h * 0.206);
    path.cubicTo(w * 0.783, h * 0.273, w * 0.766, h * 0.324, w * 0.761, h * 0.337);
    path.cubicTo(w * 0.793, h * 0.372, w * 0.812, h * 0.417, w * 0.812, h * 0.471);
    path.cubicTo(w * 0.812, h * 0.664, w * 0.695, h * 0.705, w * 0.584, h * 0.717);
    path.cubicTo(w * 0.602, h * 0.733, w * 0.618, h * 0.763, w * 0.618, h * 0.811);
    path.cubicTo(w * 0.618, h * 0.88, w * 0.617, h * 0.935, w * 0.617, h * 0.95);
    path.cubicTo(w * 0.617, h * 0.964, w * 0.626, h * 0.98, w * 0.652, h * 0.974);
    path.cubicTo(w * 0.851, h * 0.908, w * 0.994, h * 0.721, w * 0.994, h * 0.5);
    path.cubicTo(w * 0.994, h * 0.224, w * 0.77, 0, w * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GithubPainter oldDelegate) => oldDelegate.color != color;
}
