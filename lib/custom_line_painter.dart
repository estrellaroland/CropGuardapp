import 'package:flutter/material.dart';

class CustomLinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  CustomLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double maxVal = points.reduce((a, b) => a > b ? a : b);
    double minVal = points.reduce((a, b) => a < b ? a : b);
    if (maxVal == minVal) maxVal += 1.0;

    final double widthStep = size.width / (points.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      double normalizedY = size.height - ((points[i] - minVal) / (maxVal - minVal) * (size.height - 20) + 10);
      double x = i * widthStep;

      if (i == 0) {
        path.moveTo(x, normalizedY);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, normalizedY);
      } else {
        path.lineTo(x, normalizedY);
        fillPath.lineTo(x, normalizedY);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final double lastX = (points.length - 1) * widthStep;
    final double lastY = size.height - ((points.last - minVal) / (maxVal - minVal) * (size.height - 20) + 10);
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = color);
    canvas.drawCircle(Offset(lastX, lastY), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomLinePainter oldDelegate) => true;
}
