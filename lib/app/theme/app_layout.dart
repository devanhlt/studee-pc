import 'package:flutter/material.dart';

/// Spacing and breakpoints for the compact desktop window (~400×560).
abstract final class AppLayout {
  static const double pagePadding = 12;
  static const double sectionGap = 12;
  static const double cardPadding = 12;
  static const double narrowBreakpoint = 420;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrowBreakpoint;

  static EdgeInsets pageInsets(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = w < 360 ? 10.0 : pagePadding;
    return EdgeInsets.all(pad);
  }
}
