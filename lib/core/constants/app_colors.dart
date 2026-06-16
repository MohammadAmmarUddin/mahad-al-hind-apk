import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF1B7A3D);
  static const Color primaryLight = Color(0xFF28A745);
  static const Color primaryDark = Color(0xFF0E5C28);
  static const Color primarySurface = Color(0xFFE8F5E9);

  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFF81C784);

  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFE8C84A);
  static const Color accentDark = Color(0xFFB8941F);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E5C28), Color(0xFF1B7A3D), Color(0xFF28A745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0E5C28), Color(0xFF1B7A3D), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color islamicGold = Color(0xFFD4AF37);
  static const Color islamicGreen = Color(0xFF1B7A3D);
  static const Color islamicTeal = Color(0xFF008080);
}
