import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'timer_event.dart';
import 'timer_state.dart';

/// BLoC managing countdown timers, session state, and elapsed intervals.
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  StreamSubscription<int>? _tickerSubscription;

  TimerBloc({int streakDays = 0})
      : super(TimerState(streakDays: streakDays)) {
    on<TimerStarted>(_onStarted);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<TimerTicked>(_onTicked);
    on<TimerModeChanged>(_onModeChanged);
  }

  void _onStarted(TimerStarted event, Emitter<TimerState> emit) {
    final duration = event.durationSeconds ?? state.mode.defaultMinutes * 60;
    emit(state.copyWith(
      status: TimerStatus.running,
      totalSeconds: duration,
      remainingSeconds: duration,
    ));

    _tickerSubscription?.cancel();
    _tickerSubscription = _createTicker(duration).listen((ticks) {
      add(TimerTicked(ticks));
    });
  }

  void _onPaused(TimerPaused event, Emitter<TimerState> emit) {
    if (state.status == TimerStatus.running) {
      _tickerSubscription?.pause();
      emit(state.copyWith(status: TimerStatus.paused));
    }
  }

  void _onResumed(TimerResumed event, Emitter<TimerState> emit) {
    if (state.status == TimerStatus.paused) {
      _tickerSubscription?.resume();
      emit(state.copyWith(status: TimerStatus.running));
    }
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _tickerSubscription?.cancel();
    final defaultSec = state.mode.defaultMinutes * 60;
    emit(state.copyWith(
      status: TimerStatus.idle,
      totalSeconds: defaultSec,
      remainingSeconds: defaultSec,
    ));
  }

  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    if (event.remainingSeconds > 0) {
      emit(state.copyWith(remainingSeconds: event.remainingSeconds));
    } else {
      _tickerSubscription?.cancel();
      emit(state.copyWith(
        status: TimerStatus.completed,
        remainingSeconds: 0,
      ));
    }
  }

  void _onModeChanged(TimerModeChanged event, Emitter<TimerState> emit) {
    _tickerSubscription?.cancel();
    final sec = event.newMode.defaultMinutes * 60;
    emit(state.copyWith(
      mode: event.newMode,
      status: TimerStatus.idle,
      totalSeconds: sec,
      remainingSeconds: sec,
    ));
  }

  Stream<int> _createTicker(int totalSeconds) {
    return Stream.periodic(
      const Duration(seconds: 1),
      (x) => totalSeconds - x - 1,
    ).take(totalSeconds);
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
