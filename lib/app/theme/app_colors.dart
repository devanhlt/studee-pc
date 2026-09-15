import 'package:flutter/material.dart';

/// Material 3 design tokens for the Study Overlay dark theme.
///
/// Charcoal base with amber/orange accents matching the Studee logo.
abstract final class AppColors {
  static const Color background = Color(0xFF0E0E10);
  static const Color surface = Color(0xFF161618);
  static const Color elevated = Color(0xFF1E1E22);
  static const Color overlay = Color(0xFF28282E);
  static const Color border = Color(0xFF34343A);
  static const Color borderStrong = Color(0xFF4A4A52);

  static const Color primaryText = Color(0xFFF4F0E8);
  static const Color secondaryText = Color(0xFFA8A29A);
  static const Color mutedText = Color(0xFF6E6A64);

  static const Color accent = Color(0xFFFF7A00);
  static const Color accentHover = Color(0xFFFFB326);
  static const Color onAccent = Color(0xFF120C06);

  static const Color cyan = Color(0xFFFFC857);
  static const Color violet = Color(0xFFFF8F2A);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);

  /// Signature amber → orange → gold gradient (use sparingly).
  static const LinearGradient intelligence = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, accent, cyan],
  );

  /// Curved subject hues so subject cards stay intentional.
  static const List<Color> subjectHues = [
    Color(0xFFFF7A00), // orange
    Color(0xFFFFB326), // gold
    Color(0xFFFF8F2A), // amber
    Color(0xFF34D399), // emerald
    Color(0xFFF472B6), // pink
    Color(0xFFFBBF24), // yellow
    Color(0xFFFB7185), // rose
    Color(0xFFE8A87C), // warm sand
  ];

  /// Default subject accent when none is stored.
  static const Color subjectDefault = accent;
}
