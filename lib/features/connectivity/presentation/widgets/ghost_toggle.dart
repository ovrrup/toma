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
                ? Colors.purple.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            customBorder: isGhost
                ? Colors.purpleAccent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👻', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isGhost ? 'Ghost ON' : 'Online',
                  style: AppTypography.statPill.copyWith(
                    fontSize: 12,
                    color: isGhost
                        ? Colors.purpleAccent
                        : AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGhost ? Colors.purpleAccent : AppColors.darkSuccess,
                    boxShadow: [
                      BoxShadow(
                        color: isGhost
                            ? Colors.purpleAccent.withValues(alpha: 0.8)
                            : AppColors.darkSuccess.withValues(alpha: 0.8),
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
