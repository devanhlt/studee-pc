import 'package:flutter/material.dart';

/// Spacing and shape tokens for the phone-width canvas (393pt).
abstract final class AppLayout {
  static const double pagePadding = 14;
  static const double sectionGap = 14;
  static const double cardPadding = 14;

  /// Gap scale.
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 12;
  static const double gapLg = 16;
  static const double gapXl = 24;

  /// Radius scale (Material tiers).
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusControl = 12;
  static const double radiusCard = 16;
  static const double radiusPanel = 24;
  static const double radiusPill = 999;

  static BorderRadius get xsBorder => BorderRadius.circular(radiusXs);
  static BorderRadius get smBorder => BorderRadius.circular(radiusSm);
  static BorderRadius get controlBorder =>
      BorderRadius.circular(radiusControl);
  static BorderRadius get cardBorder => BorderRadius.circular(radiusCard);
  static BorderRadius get panelBorder => BorderRadius.circular(radiusPanel);

  /// Atmosphere intensity for the home / hero surface.
  static const double atmosphereHero = 1.0;

  /// Atmosphere intensity for inner screens and the overlay.
  static const double atmospherePage = 0.85;

  static EdgeInsets pageInsets(BuildContext context) =>
      const EdgeInsets.all(pagePadding);

  /// Symmetric composer / footer insets (was asymmetric 10/8/6/8).
  static const EdgeInsets footerInsets =
      EdgeInsets.fromLTRB(gapSm, gapSm, gapSm, gapSm);
}
