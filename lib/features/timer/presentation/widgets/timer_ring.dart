import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/timer_state.dart';

/// Circular progress ring displaying the remaining countdown and reward previews.
class TimerRing extends StatelessWidget {
  final TimerState state;
  final VoidCallback? onModeTap;

  const TimerRing({
    super.key,
    required this.state,
    this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 280.0;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painter for circular track and animated progress arc
            CustomPaint(
              size: const Size(size, size),
              painter: _TimerRingPainter(
                progress: state.progress,
                isBreak: state.mode.isBreak,
              ),
            ),

            // Inner content: Time, Mode badge, and Reward preview
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode indicator badge
                GestureDetector(
                  onTap: onModeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.mode.label.toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: state.mode.isBreak
                                ? AppColors.darkSuccess
                                : AppColors.darkPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: AppColors.darkTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Large Tabular Time Display
                Text(
                  state.formattedTime,
                  style: AppTypography.timerDisplay.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Potential Reward preview (only shown during active focus sessions)
                if (!state.mode.isBreak) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${state.potentialExp} EXP',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.darkExpPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${state.potentialCoins} 🪙',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.darkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Rest & recharge ☕',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkSuccess,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final bool isBreak;

  _TimerRingPainter({
    required this.progress,
    required this.isBreak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24.0) / 2;
    const strokeWidth = 10.0;

    // 1. Background Inactive Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc with Gradient
    if (progress > 0.0) {
      final gradientColors = isBreak
          ? [const Color(0xFF4ADE80), const Color(0xFF00E5FF)]
          : [const Color(0xFFFF6B35), const Color(0xFFFFD700)];

      final sweepGradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: gradientColors,
      );

      final progressPaint = Paint()
        ..shader = sweepGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.isBreak != isBreak;
}
