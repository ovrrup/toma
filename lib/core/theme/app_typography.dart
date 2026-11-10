import 'package:flutter/material.dart';

/// Typography hierarchy for Toma.
class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 48.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  static const TextStyle timerDisplay = TextStyle(
    fontSize: 64.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle statPill = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
