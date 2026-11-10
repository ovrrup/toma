import 'package:flutter/material.dart';

/// Design tokens and semantic colors for Toma.
/// Calm, serene dark palette with warm crimson, wine, and terracotta red undertones.
class AppColors {
  AppColors._();

  // --- Dark Mode Palette (Calm Red Shade) ---
  static const Color darkSurface = Color(0xFF130B0D); // Deep Obsidian Burgundy
  static const Color darkSurfaceGlass = Color(0x1CE05353); // 11% warm crimson frosted glass
  static const Color darkBorderGlass = Color(0x33E05353); // 20% soft rose hairline
  static const Color darkPrimary = Color(0xFFD94D52); // Calm Warm Crimson
  static const Color darkSecondary = Color(0xFFE2A898); // Soft Rose Peach
  static const Color darkExpPrimary = Color(0xFFBF616A); // Serene Muted Wine
  static const Color darkAccent = Color(0xFFC83840); // Deep Wine Red
  static const Color darkSuccess = Color(0xFF8FA89B); // Soft Jade Sage
  static const Color darkTextPrimary = Color(0xFFF7F2F2); // Soft Warm Ivory
  static const Color darkTextSecondary = Color(0xFFA8989A); // Muted Ash Rose

  // --- Light Mode Palette (Calm Rose Cream) ---
  static const Color lightSurface = Color(0xFFFAF5F5);
  static const Color lightSurfaceGlass = Color(0x14BA3D42);
  static const Color lightBorderGlass = Color(0x1ABA3D42);
  static const Color lightPrimary = Color(0xFFBA3D42);
  static const Color lightSecondary = Color(0xFFB57065);
  static const Color lightExpPrimary = Color(0xFFA0525A);
  static const Color lightTextPrimary = Color(0xFF281C1D);
  static const Color lightTextSecondary = Color(0xFF756264);

  // --- Monochrome Theme Palette ---
  static const Color monoSurface = Color(0xFF0F0F10); // Deep Obsidian
  static const Color monoSurfaceGlass = Color(0x12FFFFFF); // 7% white
  static const Color monoBorderGlass = Color(0x2EFFFFFF); // 18% silver hairline
  static const Color monoPrimary = Color(0xFFEDEDED); // Crisp Silver White
  static const Color monoSecondary = Color(0xFF9E9E9E); // Muted Silver
  static const Color monoExpPrimary = Color(0xFFD4D4D4); // Light Silver
  static const Color monoAccent = Color(0xFFCCCCCC);
  static const Color monoTextPrimary = Color(0xFFFFFFFF);
  static const Color monoTextSecondary = Color(0xFF757575);

  // --- Shader Preset Colors (R, G, B normalized 0.0 - 1.0) ---
  // Calm Crimson Wine Fluid
  static const List<double> shaderFireColorA = [0.65, 0.18, 0.22];
  static const List<double> shaderFireColorB = [0.78, 0.35, 0.32];
  static const List<double> shaderFireBg = [0.07, 0.04, 0.05];

  // Monochrome Liquid Ink
  static const List<double> shaderMonoColorA = [0.16, 0.16, 0.16];
  static const List<double> shaderMonoColorB = [0.38, 0.38, 0.38];
  static const List<double> shaderMonoBg = [0.03, 0.03, 0.03];

  // Ocean Muted Rose Fluid
  static const List<double> shaderOceanColorA = [0.45, 0.15, 0.25];
  static const List<double> shaderOceanColorB = [0.75, 0.30, 0.38];
  static const List<double> shaderOceanBg = [0.05, 0.03, 0.04];
}
