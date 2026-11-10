import 'package:flutter/material.dart';

/// Design tokens and semantic colors for Toma.
class AppColors {
  AppColors._();

  // --- Dark Mode Palette ---
  static const Color darkSurface = Color(0xFF0A0A14);
  static const Color darkSurfaceGlass = Color(0x1FFFFFFF); // 12% white
  static const Color darkBorderGlass = Color(0x3DFFFFFF); // 24% white
  static const Color darkPrimary = Color(0xFFFF6B35); // Warm Lava Orange
  static const Color darkSecondary = Color(0xFFFFD700); // Gold (Coins 🪙)
  static const Color darkExpPrimary = Color(0xFF8B5CF6); // Royal Violet (EXP ⚡)
  static const Color darkAccent = Color(0xFFFF3366); // Hot Pink (Streaks 🔥)
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA0A0B8);

  // --- Light Mode Palette ---
  static const Color lightSurface = Color(0xFFFFF8F0);
  static const Color lightSurfaceGlass = Color(0x14000000); // 8% black
  static const Color lightBorderGlass = Color(0x1A000000); // 10% black
  static const Color lightPrimary = Color(0xFFE85D2C);
  static const Color lightSecondary = Color(0xFFD4A800);
  static const Color lightExpPrimary = Color(0xFF7C3AED);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);

  // --- Monochrome Theme Palette (Unlockable 200 Coins) ---
  static const Color monoSurface = Color(0xFF080808); // Deep Obsidian
  static const Color monoSurfaceGlass = Color(0x12FFFFFF); // 7% white
  static const Color monoBorderGlass = Color(0x2EFFFFFF); // 18% silver hairline
  static const Color monoPrimary = Color(0xFFFFFFFF); // Crisp White
  static const Color monoSecondary = Color(0xFF9E9E9E); // Muted Silver
  static const Color monoExpPrimary = Color(0xFFD4D4D4); // Light Silver
  static const Color monoAccent = Color(0xFFCCCCCC);
  static const Color monoTextPrimary = Color(0xFFFFFFFF);
  static const Color monoTextSecondary = Color(0xFF757575);

  // --- Shader Preset Colors (R, G, B normalized 0.0 - 1.0) ---
  // Default Warm Fire
  static const List<double> shaderFireColorA = [1.0, 0.42, 0.21];
  static const List<double> shaderFireColorB = [1.0, 0.84, 0.0];
  static const List<double> shaderFireBg = [0.04, 0.04, 0.08];

  // Monochrome Liquid Ink
  static const List<double> shaderMonoColorA = [0.16, 0.16, 0.16];
  static const List<double> shaderMonoColorB = [0.38, 0.38, 0.38];
  static const List<double> shaderMonoBg = [0.03, 0.03, 0.03];

  // Ocean Blue
  static const List<double> shaderOceanColorA = [0.0, 0.47, 0.71];
  static const List<double> shaderOceanColorB = [0.0, 0.9, 1.0];
  static const List<double> shaderOceanBg = [0.01, 0.04, 0.1];
}
