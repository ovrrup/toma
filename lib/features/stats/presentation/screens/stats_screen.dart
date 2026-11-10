import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';
import '../../../timer/domain/entities/session.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final list = await DatabaseService.instance.getSessions();
    if (mounted) {
      setState(() => _sessions = list);
    }
  }

  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final streak = db.getStreakDays();
    final totalMinutes = db.getTotalFocusMinutes();
    final completedCount = _sessions.where((s) => s.wasCompleted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Focus History',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quiet metrics of your daily practice and deliberate focus.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Core Focus Stats Card
          FrostedGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCol(
                  val: _formatFocusTime(totalMinutes),
                  label: 'TOTAL TIME',
                  color: Colors.white,
                  icon: Icons.schedule,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _buildStatCol(
                  val: '$completedCount',
                  label: 'SESSIONS',
                  color: AppColors.darkSecondary,
                  icon: Icons.check_circle_outline,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _buildStatCol(
                  val: '$streak ${streak == 1 ? "day" : "days"}',
                  label: 'STREAK',
                  color: AppColors.darkAccent,
                  icon: Icons.local_fire_department,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Real Monthly Consistency Heatmap
          FrostedGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildMonthlyHeatmap(),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCol({
    required String val,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyHeatmap() {
    final now = DateTime.now();
    final monthName = _monthName(now.month);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday; // 1 = Monday, 7 = Sunday

    // Map each day number of current month to number of completed sessions
    final Map<int, int> daySessionCount = {};
    for (final s in _sessions) {
      if (s.wasCompleted &&
          s.startedAt.year == now.year &&
          s.startedAt.month == now.month) {
        final day = s.startedAt.day;
        daySessionCount[day] = (daySessionCount[day] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$monthName ${now.year}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${daySessionCount.length} active ${daySessionCount.length == 1 ? "day" : "days"}',
              style: const TextStyle(
                color: AppColors.darkSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // Calendar Grid
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Empty slots before 1st day of month
            for (int p = 1; p < firstDayWeekday; p++)
              const SizedBox(width: 32, height: 32),

            // Actual days of month
            for (int day = 1; day <= daysInMonth; day++)
              _buildCalendarDayTile(day, daySessionCount[day] ?? 0, day == now.day),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarDayTile(int day, int count, bool isToday) {
    Color bg = Colors.white.withValues(alpha: 0.04);
    Color textColor = Colors.white30;

    if (count > 0) {
      final intensity = (count / 3.0).clamp(0.4, 0.9);
      bg = AppColors.darkPrimary.withValues(alpha: intensity);
      textColor = Colors.white;
    } else if (isToday) {
      bg = Colors.white.withValues(alpha: 0.1);
      textColor = Colors.white70;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppColors.darkSecondary.withValues(alpha: 0.6) : Colors.transparent,
          width: isToday ? 1.0 : 0,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: count > 0 || isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
