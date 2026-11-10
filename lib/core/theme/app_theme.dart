import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

enum TomaThemeVariant { dark, light, monochrome }

/// Theme manager for Toma.
/// Configures unified Material 3 themes with a serene, calm red / obsidian burgundy ambiance.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: Color(0xFF1E1215),
        onPrimary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.darkAccent,
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodySmall: AppTypography.bodySmall,
      ).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: Color(0xFFF0E6E6),
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.lightPrimary,
      ),
      dividerColor: Colors.black.withValues(alpha: 0.08),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodySmall: AppTypography.bodySmall,
      ).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get monochromeTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.monoSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.monoPrimary,
        secondary: AppColors.monoSecondary,
        surface: AppColors.monoSurface,
        surfaceContainerHighest: Color(0xFF1A1A1C),
        onPrimary: Colors.black,
        onSurface: AppColors.monoTextPrimary,
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodySmall: AppTypography.bodySmall,
      ).apply(
        bodyColor: AppColors.monoTextPrimary,
        displayColor: AppColors.monoTextPrimary,
      ),
      useMaterial3: true,
    );
  }
}
