import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

/// Minimalist glass card quietly displaying today's focus sessions and active streak.
class SessionSummaryCard extends StatelessWidget {
  final int todaySessionsCount;
  final int streakDays;

  const SessionSummaryCard({
    super.key,
    required this.todaySessionsCount,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 15,
                color: AppColors.darkSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Today: $todaySessionsCount ${todaySessionsCount == 1 ? "session" : "sessions"}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.darkTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 14,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 15,
                color: AppColors.darkAccent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$streakDays ${streakDays == 1 ? "day" : "days"} streak',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.darkAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
