import '../../../timer/domain/entities/session_type.dart';

/// Calculation engine for EXP progression, Coins rewards, levels, and streak logic.
class GamificationRepository {
  static const Map<int, int> levelThresholds = {
    1: 0,
    2: 500,
    3: 1500,
    4: 3500,
    5: 7000,
    6: 12000,
    7: 19000,
    8: 28000,
    9: 40000,
    10: 55000,
  };

  /// Calculates the earned EXP from a focus session.
  static int calculateExp({
    required int durationMinutes,
    required bool wasCompleted,
    required int streakDays,
    required int sessionsCompletedToday,
  }) {
    // 1. Base Time: 10 EXP per minute
    final baseExp = durationMinutes * 10;

    // 2. Completion Bonus (+20%)
    final completionBonus = wasCompleted ? (baseExp * 0.2).round() : 0;

    // 3. Streak Multiplier (+5% per day up to +50%)
    final streakMultiplier = 1.0 + (streakDays * 0.05).clamp(0.0, 0.5);

    // 4. Session Velocity / Chaining bonus
    int chainBonus = 0;
    if (sessionsCompletedToday == 1) {
      chainBonus = 50; // 2nd session of the day
    } else if (sessionsCompletedToday >= 2) {
      chainBonus = 100; // 3rd+ session of the day
    }

    return ((baseExp + completionBonus) * streakMultiplier).round() + chainBonus;
  }

  /// Calculates the Coins awarded for a session.
  static int calculateCoins({
    required SessionType type,
    required int durationMinutes,
    required bool wasCompleted,
  }) {
    if (type.isBreak || !wasCompleted) return 0;
    switch (type) {
      case SessionType.pomodoro:
        return 10;
      case SessionType.deepWork:
        return 25;
      case SessionType.custom:
      case SessionType.stopwatch:
        return (durationMinutes / 2.5).round();
      default:
        return 0;
    }
  }

  /// Calculates user level (1 to 10) based on cumulative EXP.
  static int calculateLevel(int totalExp) {
    int currentLevel = 1;
    for (final entry in levelThresholds.entries) {
      if (totalExp >= entry.value) {
        currentLevel = entry.key;
      } else {
        break;
      }
    }
    return currentLevel;
  }

  /// Returns the title corresponding to a given level.
  static String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Seedling';
      case 2:
        return 'Sprout';
      case 3:
        return 'Sapling';
      case 4:
        return 'Tree';
      case 5:
        return 'Master Grower';
      case 6:
        return 'Sunflower';
      case 7:
        return 'Blazing Focus';
      case 8:
        return 'Astral Sage';
      case 9:
        return 'Diamond Mind';
      case 10:
      default:
        return 'Harvest Sovereign';
    }
  }

  /// Returns the EXP required for the next rank.
  static int getNextLevelExp(int currentLevel) {
    if (currentLevel >= 10) return levelThresholds[10]!;
    return levelThresholds[currentLevel + 1] ?? 55000;
  }

  /// Returns the EXP baseline for the current level.
  static int getPrevLevelExp(int currentLevel) {
    return levelThresholds[currentLevel] ?? 0;
  }
}
