import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Progress bar showing the user's level and progress towards the next rank.
class ExpBar extends StatelessWidget {
  final int currentExp;
  final int level;
  final String levelTitle;
  final int prevLevelExp;
  final int nextLevelExp;

  const ExpBar({
    super.key,
    required this.currentExp,
    required this.level,
    required this.levelTitle,
    required this.prevLevelExp,
    required this.nextLevelExp,
  });

  double get progress {
    if (nextLevelExp <= prevLevelExp) return 1.0;
    final clamped = currentExp.clamp(prevLevelExp, nextLevelExp);
    return (clamped - prevLevelExp) / (nextLevelExp - prevLevelExp);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 15,
                  color: AppColors.darkExpPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level $level · $levelTitle',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkExpPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '$currentExp / $nextLevelExp EXP',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppSpacing.roundedFull,
          child: Container(
            height: 6.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.darkExpPrimary,
                      AppColors.darkPrimary,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
