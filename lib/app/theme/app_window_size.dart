import 'package:flutter/material.dart';

/// Desktop window mirrors the phone canvas so macOS/Windows match mobile UI.
abstract final class AppWindowSize {
  /// Phone canvas the desktop window mirrors (iPhone 14/15/16 logical width).
  static const double phoneWidth = 393;

  /// Full phone height; clamped to the display at launch.
  static const double preferredHeight = 852;
  static const double minHeight = 620;

  /// Default launch size (height may be clamped to the display).
  static const Size initial = Size(phoneWidth, preferredHeight);

  /// Width locked; height may grow or shrink.
  static const Size minimum = Size(phoneWidth, minHeight);

  /// Same width as [minimum] so horizontal resize is refused.
  static const Size maximum = Size(phoneWidth, 4000);

  /// Fallback when restoring a missing height.
  static const double fallbackHeight = preferredHeight;
}
