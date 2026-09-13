import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';

/// Type scale for Studee. Wired into [ThemeData.textTheme] via [AppTheme].
///
/// Sized for the phone-width canvas (~393pt); body text stays readable
/// without relying on system text scaling.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';
  static const String monoFamily = 'monospace';

  static const List<FontFeature> tabular = [
    FontFeature.tabularFigures(),
  ];

  static TextTheme textTheme() {
    const base = TextStyle(
      fontFamily: fontFamily,
      color: AppColors.primaryText,
      height: 1.4,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.12,
      ),
      displayMedium: base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      titleLarge: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      titleMedium: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleSmall: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      bodyLarge: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodySmall: base.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.secondaryText,
      ),
      labelLarge: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.secondaryText,
      ),
      labelSmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
        color: AppColors.secondaryText,
      ),
    );
  }

  /// Eyebrow / wordmark style (uppercase tracked caption).
  static TextStyle get eyebrow => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        height: 1.2,
        color: AppColors.secondaryText,
      );

  /// Tabular stats / counts.
  static TextStyle get tabularCaption => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.secondaryText,
        fontFeatures: tabular,
      );

  /// Shared mono token for code / paths.
  static TextStyle get mono => const TextStyle(
        fontFamily: monoFamily,
        fontSize: 13.5,
        height: 1.4,
        color: AppColors.secondaryText,
      );
}
