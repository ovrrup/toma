import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/timer_state.dart';

/// Circular progress ring displaying the remaining countdown in a calm, uncluttered style.
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
    const size = 260.0;

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

            // Inner content: Mode badge and Time display
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
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceGlass,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.darkBorderGlass,
                      ),
                    ),
                    child: Text(
                      state.mode.label.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        color: state.mode.isBreak
                            ? AppColors.darkSuccess
                            : AppColors.darkPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Large Tabular Time Display
                Text(
                  state.formattedTime,
                  style: AppTypography.timerDisplay.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontSize: 56.0,
                  ),
                ),

                if (state.mode.isBreak) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rest & breathe',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkSuccess,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
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
    const strokeWidth = 5.0;

    // 1. Background Inactive Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc with Calm Red/Rose Gradient
    if (progress > 0.0) {
      final gradientColors = isBreak
          ? [const Color(0xFF8FA89B), const Color(0xFFE2A898)]
          : [const Color(0xFFD94D52), const Color(0xFFE2A898)];

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
