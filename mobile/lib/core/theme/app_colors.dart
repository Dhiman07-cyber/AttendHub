import 'package:flutter/material.dart';

/// AttendHub Design System Color Palette (Light Theme)
class AppColors {
  // Page & Surface Colors
  static const Color background = Color(0xFFF7F1EC);
  static const Color surface = Color(0xFFFFFDFC);
  static const Color surfaceAlt = Color(0xFFF7F1EC);
  static const Color surfaceGlass = Color.fromRGBO(255, 255, 255, 0.72);
  static const Color surfaceGlassLight = Color.fromRGBO(255, 255, 255, 0.45);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.85);

  // Terracotta / Rose Brand Identity
  static const Color terracotta = Color(0xFFC96E5B);
  static const Color terracottaDark = Color(0xFFB55D4A);
  static const Color terracottaLight = Color(0xFFFDF0ED);
  static const Color rose = Color(0xFFD98786);
  static const Color roseLight = Color(0xFFF9EBEA);

  // Semantic Status Colors
  // Safe / Attended / On-Track
  static const Color sage = Color(0xFF72A68A);
  static const Color sageDark = Color(0xFF5B8E72);
  static const Color sageLight = Color(0xFFEBF4EF);

  // Caution / Warning / Approaching Minimum
  static const Color amber = Color(0xFFD9A35B);
  static const Color amberLight = Color(0xFFFAF3E8);
  static const Color amberDark = Color(0xFFC08A45);

  // Critical / Absent / Below Minimum
  static const Color coral = Color(0xFFD86A62);
  static const Color coralLight = Color(0xFFFAEBEA);

  // Academic / Secondary Events
  static const Color lavender = Color(0xFF8F7BAE);
  static const Color lavenderLight = Color(0xFFF1EDF7);

  // Informational / Tech Accent
  static const Color ocean = Color(0xFF5A93B5);
  static const Color oceanLight = Color(0xFFEBF3F8);

  // Neutrals & Typography
  static const Color ink = Color(0xFF202020);
  static const Color inkSecondary = Color(0xFF4A4644);
  static const Color inkMuted = Color(0xFF7A7572);
  static const Color inkLight = Color(0xFFA6A19E);
  static const Color sand = Color(0xFFE8DFD7);
  static const Color sandLight = Color(0xFFF4ECE4);
  static const Color divider = Color.fromRGBO(48, 38, 34, 0.08);

  // Shadow tint
  static const Color shadowWarm = Color.fromRGBO(58, 35, 25, 0.06);

  // Helper method for subject icon background
  static Color getSubjectColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return terracotta;
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return terracotta;
    }
  }
}
