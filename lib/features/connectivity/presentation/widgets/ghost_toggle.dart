import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';

/// Top bar pill button allowing instant disconnection from Nostr relays.
class GhostToggle extends StatelessWidget {
  const GhostToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final isGhost = state.isGhostMode;

        return AnimatedPressable(
          onTap: () {
            context.read<ConnectivityCubit>().toggleGhostMode();
          },
          child: FrostedGlassCard(
            borderRadius: AppSpacing.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            customFill: isGhost
                ? AppColors.darkPrimary.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            customBorder: isGhost
                ? AppColors.darkPrimary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGhost ? Icons.visibility_off_outlined : Icons.wifi,
                  size: 14,
                  color: isGhost
                      ? AppColors.darkPrimary
                      : AppColors.darkTextSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isGhost ? 'Ghost Mode' : 'Online',
                  style: AppTypography.statPill.copyWith(
                    fontSize: 12,
                    color: isGhost
                        ? AppColors.darkPrimary
                        : AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGhost ? AppColors.darkPrimary : AppColors.darkSuccess,
                    boxShadow: [
                      BoxShadow(
                        color: isGhost
                            ? AppColors.darkPrimary.withValues(alpha: 0.6)
                            : AppColors.darkSuccess.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
