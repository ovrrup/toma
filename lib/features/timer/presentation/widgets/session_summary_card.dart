import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

/// Glass card displaying daily focus stats and active challenge progress.
class SessionSummaryCard extends StatelessWidget {
  final int todaySessionsCount;
  final int streakDays;
  final String challengeDescription;
  final int challengeCurrent;
  final int challengeTarget;
  final int challengeRewardCoins;
  final int challengeRewardExp;

  const SessionSummaryCard({
    super.key,
    required this.todaySessionsCount,
    required this.streakDays,
    required this.challengeDescription,
    required this.challengeCurrent,
    required this.challengeTarget,
    required this.challengeRewardCoins,
    required this.challengeRewardExp,
  });

  @override
  Widget build(BuildContext context) {
    final challengeProgress = challengeTarget > 0
        ? (challengeCurrent / challengeTarget).clamp(0.0, 1.0)
        : 0.0;

    return FrostedGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat row: Today's sessions & Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Today: $todaySessionsCount sessions',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$streakDays days streak',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Daily Challenge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY CHALLENGE',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: AppColors.darkTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+$challengeRewardCoins 🪙  +$challengeRewardExp ⚡',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.darkSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            challengeDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppSpacing.roundedFull,
                  child: LinearProgressIndicator(
                    value: challengeProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.darkPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$challengeCurrent/$challengeTarget',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
