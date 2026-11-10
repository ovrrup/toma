import 'package:equatable/equatable.dart';
import '../../domain/entities/session_type.dart';

sealed class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

final class TimerStarted extends TimerEvent {
  final int? durationSeconds;
  const TimerStarted({this.durationSeconds});

  @override
  List<Object?> get props => [durationSeconds];
}

final class TimerPaused extends TimerEvent {
  const TimerPaused();
}

final class TimerResumed extends TimerEvent {
  const TimerResumed();
}

final class TimerReset extends TimerEvent {
  const TimerReset();
}

final class TimerTicked extends TimerEvent {
  final int remainingSeconds;
  const TimerTicked(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

final class TimerModeChanged extends TimerEvent {
  final SessionType newMode;
  const TimerModeChanged(this.newMode);

  @override
  List<Object?> get props => [newMode];
}
