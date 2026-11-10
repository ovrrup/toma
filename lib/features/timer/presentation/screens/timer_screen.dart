import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/coin_pill.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';
import '../../../connectivity/presentation/widgets/ghost_toggle.dart';
import '../../domain/entities/session_type.dart';
import '../bloc/timer_bloc.dart';
import '../bloc/timer_event.dart';
import '../bloc/timer_state.dart';
import '../widgets/session_summary_card.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_ring.dart';

class TimerScreen extends StatelessWidget {
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSettings;

  const TimerScreen({
    super.key,
    this.onOpenProfile,
    this.onOpenSettings,
  });

  void _showModePicker(BuildContext context, TimerBloc bloc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassCard(
        borderRadius: AppSpacing.radiusLg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Timer Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...SessionType.values.where((m) => m != SessionType.stopwatch).map((mode) {
              final isCurrent = bloc.state.mode == mode;
              return ListTile(
                title: Text(
                  mode.label,
                  style: TextStyle(
                    color: isCurrent ? AppColors.darkPrimary : Colors.white,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  mode.isBreak
                      ? '${mode.defaultMinutes} min rest'
                      : '${mode.defaultMinutes} min · +${mode.baseExp} EXP · +${mode.baseCoins} 🪙',
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
                trailing: isCurrent
                    ? const Icon(Icons.check_circle, color: AppColors.darkPrimary)
                    : null,
                onTap: () {
                  bloc.add(TimerModeChanged(mode));
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        final bloc = context.read<TimerBloc>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Top Bar: Coins Pill, Ghost Mode Toggle, Profile, Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CoinPill(coins: 240),
                  const GhostToggle(),
                  Row(
                    children: [
                      AnimatedPressable(
                        onTap: onOpenProfile,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: const Center(
                            child: Text('🌱', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedPressable(
                        onTap: onOpenSettings,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: AppColors.darkTextSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Circular Countdown Timer
              TimerRing(
                state: state,
                onModeTap: () => _showModePicker(context, bloc),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Primary Action Buttons
              TimerControls(
                state: state,
                onStart: () => bloc.add(const TimerStarted()),
                onPause: () => bloc.add(const TimerPaused()),
                onResume: () => bloc.add(const TimerResumed()),
                onReset: () => bloc.add(const TimerReset()),
              ),

              const Spacer(flex: 2),

              // Daily Summary & Active Challenge Card
              const SessionSummaryCard(
                todaySessionsCount: 3,
                streakDays: 7,
                challengeDescription: 'Complete 3 Pomodoro sessions today',
                challengeCurrent: 2,
                challengeTarget: 3,
                challengeRewardCoins: 20,
                challengeRewardExp: 200,
              ),

              const SizedBox(height: 90), // Spacing for bottom navigation bar
            ],
          ),
        );
      },
    );
  }
}
