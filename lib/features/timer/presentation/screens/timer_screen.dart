import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/services/nostr_service.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';
import '../../../connectivity/presentation/widgets/ghost_toggle.dart';
import '../../../gamification/data/repositories/gamification_repository.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_type.dart';
import '../bloc/timer_bloc.dart';
import '../bloc/timer_event.dart';
import '../bloc/timer_state.dart';
import '../widgets/session_summary_card.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_ring.dart';

class TimerScreen extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSettings;

  const TimerScreen({
    super.key,
    this.onOpenProfile,
    this.onOpenSettings,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  StreamSubscription<void>? _dbSubscription;
  bool _hasSavedCurrentSession = false;

  @override
  void initState() {
    super.initState();
    _dbSubscription = DatabaseService.instance.onDataUpdated.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  void _onSessionCompleted(TimerState state) async {
    if (_hasSavedCurrentSession || state.mode.isBreak) return;
    _hasSavedCurrentSession = true;

    final session = Session(
      id: const Uuid().v4(),
      type: state.mode,
      durationMinutes: state.totalSeconds ~/ 60,
      startedAt: DateTime.now().subtract(Duration(seconds: state.totalSeconds)),
      completedAt: DateTime.now(),
      expEarned: state.potentialExp,
      coinsEarned: state.potentialCoins,
      wasCompleted: true,
    );

    await DatabaseService.instance.saveSession(session);

    final totalExp = DatabaseService.instance.getTotalExp();
    final streak = DatabaseService.instance.getStreakDays();
    final minutes = DatabaseService.instance.getTotalFocusMinutes();

    await NostrService.instance.broadcastProgress(
      exp: totalExp,
      level: GamificationRepository.calculateLevel(totalExp),
      streakDays: streak,
      totalMinutes: minutes,
    );
  }

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
              'Timer Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
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
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  mode.isBreak
                      ? '${mode.defaultMinutes} minutes rest'
                      : '${mode.defaultMinutes} minutes focus',
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: AppColors.darkPrimary, size: 20)
                    : null,
                onTap: () {
                  _hasSavedCurrentSession = false;
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
    final db = DatabaseService.instance;
    final streak = db.getStreakDays();
    final todayCount = db.getTodaySessionsCount();

    return BlocConsumer<TimerBloc, TimerState>(
      listener: (context, state) {
        if (state.status == TimerStatus.completed) {
          _onSessionCompleted(state);
        } else if (state.status == TimerStatus.running) {
          _hasSavedCurrentSession = false;
        }
      },
      builder: (context, state) {
        final bloc = context.read<TimerBloc>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Calm Top Bar: Ghost Mode indicator on left, Profile on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GhostToggle(),
                  AnimatedPressable(
                    onTap: widget.onOpenProfile,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkBorderGlass,
                          width: 1.2,
                        ),
                        color: AppColors.darkSurfaceGlass,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ),
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

              // Primary Action Controls
              TimerControls(
                state: state,
                onStart: () => bloc.add(const TimerStarted()),
                onPause: () => bloc.add(const TimerPaused()),
                onResume: () => bloc.add(const TimerResumed()),
                onReset: () => bloc.add(const TimerReset()),
              ),

              const Spacer(flex: 2),

              // Quiet Daily Summary Card
              SessionSummaryCard(
                todaySessionsCount: todayCount,
                streakDays: streak,
              ),

              const SizedBox(height: 90), // Bottom nav bar clearance
            ],
          ),
        );
      },
    );
  }
}
