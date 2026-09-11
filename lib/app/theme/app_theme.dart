import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';

/// Dark Material 3 theme built from [AppColors] tokens.
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.elevated,
      surfaceContainerHigh: AppColors.elevated,
      surfaceContainer: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      primary: AppColors.accent,
      onPrimary: Color(0xFF1A1208),
      secondary: AppColors.secondaryText,
      onSecondary: AppColors.background,
      error: AppColors.error,
      onError: AppColors.primaryText,
      onSurface: AppColors.primaryText,
      onSurfaceVariant: AppColors.secondaryText,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      tertiary: AppColors.success,
      onTertiary: AppColors.background,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      fontFamily: 'SF Pro Text',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.primaryText,
        displayColor: AppColors.primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF1A1208),
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.secondaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF1A1208),
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.secondaryText,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.secondaryText,
        indicatorColor: AppColors.accent,
        dividerColor: AppColors.border,
        tabAlignment: TabAlignment.start,
        labelPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.secondaryText,
        textColor: AppColors.primaryText,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        contentTextStyle: const TextStyle(color: AppColors.primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.secondaryText),
      focusColor: AppColors.accent.withValues(alpha: 0.2),
      hoverColor: AppColors.accentHover.withValues(alpha: 0.08),
    );
  }
}
