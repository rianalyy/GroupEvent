import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF4C0A7A);
  static const Color primaryLight = Color(0xFFA855F7);
  static const Color secondary = Color(0xFFA78BFA);
  static const Color secondaryLight = Color(0xFFD8B4FE);

  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color text = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color white = Colors.white;

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color glassWhite = Colors.white.withOpacity(0.12);
  static Color glassBorder = Colors.white.withOpacity(0.25);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFD8B4FE), Color(0xFFA78BFA)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4C0A7A), Color(0xFF2D0550)],
  );
}
