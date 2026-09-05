import 'package:flutter/material.dart';

/// Material 3 design tokens for the Study Overlay dark theme.
///
/// Orange ([accent]) is reserved for focus, primary actions, selection, and
/// progress — never for decorative chrome.
abstract final class AppColors {
  static const Color background = Color(0xFF111214);
  static const Color surface = Color(0xFF191B1F);
  static const Color elevated = Color(0xFF22252A);
  static const Color border = Color(0xFF32363D);

  static const Color primaryText = Color(0xFFF2F3F5);
  static const Color secondaryText = Color(0xFFA7ADB7);

  static const Color accent = Color(0xFFF28C28);
  static const Color accentHover = Color(0xFFFF9F3D);

  static const Color success = Color(0xFF42B883);
  static const Color warning = Color(0xFFF2B84B);
  static const Color error = Color(0xFFE56565);
}
