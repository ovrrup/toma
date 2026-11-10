import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'frosted_glass_card.dart';

/// Pill badge displaying the user's spendable Coins balance.
class CoinPill extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const CoinPill({
    super.key,
    required this.coins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: AppSpacing.radiusFull,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.toll_outlined,
            size: 16,
            color: AppColors.darkSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$coins',
            style: AppTypography.statPill.copyWith(
              color: AppColors.darkSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
