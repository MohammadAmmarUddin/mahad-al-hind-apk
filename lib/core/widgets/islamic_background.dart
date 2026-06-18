import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium Islamic geometric pattern background with deep emerald gradient.
/// Used across the app for branded screens (splash, onboarding, etc.)
class IslamicBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final bool showGlow;

  const IslamicBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071F15),  // Deepest dark emerald
            Color(0xFF0A3D28),  // Dark emerald
            Color(0xFF0F6B4A),  // Primary green
            Color(0xFF0A4F38),  // Dark emerald
            Color(0xFF071F15),  // Deepest
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle radial glow behind logo area
          if (showGlow)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.8,
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.08),
                      const Color(0xFF0F6B4A).withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Islamic geometric pattern overlay
          if (showPattern)
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
              ),
            ),

          // Soft top vignette
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}

/// Custom painter that draws a subtle Islamic geometric pattern.
/// Uses overlapping circles and star patterns typical of Islamic art.
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final double spacing = 40.0;
    final double radius = 18.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw circle at each grid point
        canvas.drawCircle(Offset(x, y), radius, paint);

        // Draw 8-pointed star segments
        final starPaint = Paint()
          ..color = Colors.white.withOpacity(0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3;

        final path = Path();
        for (int i = 0; i < 8; i++) {
          final angle = (i * math.pi) / 4;
          final dx = x + radius * 0.6 * math.cos(angle);
          final dy = y + radius * 0.6 * math.sin(angle);
          if (i == 0) {
            path.moveTo(dx, dy);
          } else {
            path.lineTo(dx, dy);
          }
        }
        path.close();
        canvas.drawPath(path, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}