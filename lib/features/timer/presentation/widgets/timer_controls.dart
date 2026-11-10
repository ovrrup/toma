import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';
import '../bloc/timer_state.dart';

/// Play, Pause, Resume, and Reset controls for the stopwatch session.
class TimerControls extends StatelessWidget {
  final TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  const TimerControls({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button (visible when running, paused, or completed)
        if (state.status != TimerStatus.idle) ...[
          AnimatedPressable(
            onTap: onReset,
            child: const FrostedGlassCard(
              borderRadius: AppSpacing.radiusFull,
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.refresh,
                color: AppColors.darkTextSecondary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],

        // Main CTA Button
        AnimatedPressable(
          onTap: () {
            switch (state.status) {
              case TimerStatus.idle:
                onStart();
                break;
              case TimerStatus.running:
                onPause();
                break;
              case TimerStatus.paused:
                onResume();
                break;
              case TimerStatus.completed:
                onReset();
                break;
            }
          },
          child: FrostedGlassCard(
            borderRadius: AppSpacing.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
            customFill: state.status == TimerStatus.running
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.darkPrimary.withValues(alpha: 0.85),
            customBorder: state.status == TimerStatus.running
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.darkPrimary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.status == TimerStatus.running
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _ctaLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _ctaLabel {
    switch (state.status) {
      case TimerStatus.idle:
        return 'START';
      case TimerStatus.running:
        return 'PAUSE';
      case TimerStatus.paused:
        return 'RESUME';
      case TimerStatus.completed:
        return 'NEW SESSION';
    }
  }
}
