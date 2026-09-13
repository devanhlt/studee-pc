import 'package:flutter/material.dart';

/// Material 3 design tokens for the Study Overlay dark theme.
///
/// Cool ink-navy base with a violet → indigo → cyan “intelligence”
/// gradient used sparingly for focus, primary actions, and AI cues.
abstract final class AppColors {
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF121827);
  static const Color elevated = Color(0xFF1A2234);
  static const Color overlay = Color(0xFF232D45);
  static const Color border = Color(0xFF2A3450);
  static const Color borderStrong = Color(0xFF3B4A6E);

  static const Color primaryText = Color(0xFFEDF1FA);
  static const Color secondaryText = Color(0xFF9BA7C4);
  static const Color mutedText = Color(0xFF6C7899);

  static const Color accent = Color(0xFF6E8BFF);
  static const Color accentHover = Color(0xFF8AA1FF);
  static const Color onAccent = Color(0xFF070B1A);

  static const Color cyan = Color(0xFF22D3EE);
  static const Color violet = Color(0xFFA78BFA);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);

  /// Signature violet → indigo → cyan gradient (use sparingly).
  static const LinearGradient intelligence = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, accent, cyan],
  );

  /// Curated subject hues so subject cards stay intentional.
  static const List<Color> subjectHues = [
    Color(0xFF6E8BFF), // indigo
    Color(0xFF22D3EE), // cyan
    Color(0xFFA78BFA), // violet
    Color(0xFF34D399), // emerald
    Color(0xFFF472B6), // pink
    Color(0xFFFBBF24), // amber
    Color(0xFFFB7185), // rose
    Color(0xFF38BDF8), // sky
  ];

  /// Default subject accent when none is stored.
  static const Color subjectDefault = accent;
}
