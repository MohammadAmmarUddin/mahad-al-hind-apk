import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class IslamicPattern extends CustomPainter {
  final Color color;

  IslamicPattern({this.color = AppColors.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final x = center.dx + radius * 0.5 * cos(angle);
      final y = center.dy + radius * 0.5 * sin(angle);

      final innerRadius = radius * 0.3;
      path.moveTo(
        x + innerRadius * cos(angle),
        y + innerRadius * sin(angle),
      );
      path.lineTo(
        x - innerRadius * cos(angle),
        y - innerRadius * sin(angle),
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IslamicPatternWidget extends StatelessWidget {
  final double size;
  final Color color;

  const IslamicPatternWidget({
    super.key,
    this.size = 100,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: IslamicPattern(color: color),
    );
  }
}
