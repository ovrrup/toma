import 'package:equatable/equatable.dart';
import '../../domain/entities/session_type.dart';

enum TimerStatus { idle, running, paused, completed }

class TimerState extends Equatable {
  final SessionType mode;
  final TimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;
  final int streakDays;

  const TimerState({
    this.mode = SessionType.pomodoro,
    this.status = TimerStatus.idle,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.streakDays = 0,
  });

  /// Fraction of session elapsed (0.0 at start, 1.0 when finished)
  double get progress {
    if (totalSeconds <= 0) return 0.0;
    return (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0);
  }

  /// Human-readable time representation (e.g. 25:00)
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Preview of EXP that will be awarded upon session completion
  int get potentialExp {
    if (mode.isBreak) return 0;
    final base = mode.baseExp;
    final streakMultiplier = 1.0 + (streakDays * 0.05).clamp(0.0, 0.5);
    return (base * streakMultiplier).round();
  }

  /// Preview of Coins that will be awarded upon session completion
  int get potentialCoins {
    if (mode.isBreak) return 0;
    return mode.baseCoins;
  }

  TimerState copyWith({
    SessionType? mode,
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    int? streakDays,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        status,
        totalSeconds,
        remainingSeconds,
        streakDays,
      ];
}
