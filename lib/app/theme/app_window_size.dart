import 'package:flutter/material.dart';

/// Compact desktop window targets — keep the main UI as small as practical.
abstract final class AppWindowSize {
  /// Default launch size.
  static const Size initial = Size(400, 560);

  /// Smallest allowed resize.
  static const Size minimum = Size(320, 400);

  /// Fallback when restoring a missing width/height.
  static const double fallbackWidth = 400;
  static const double fallbackHeight = 560;
}
