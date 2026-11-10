import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/services/nostr_service.dart';
import 'connectivity_state.dart';

/// Cubit managing dynamic connectivity, offline queue, and user Ghost Mode.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({bool initialGhostMode = false})
      : super(ConnectivityState(isGhostMode: initialGhostMode));

  /// Toggle Ghost Mode on or off
  void toggleGhostMode() {
    final nextGhostMode = !state.isGhostMode;
    emit(state.copyWith(isGhostMode: nextGhostMode));
    NostrService.instance.setGhostMode(nextGhostMode);
  }

  void updateNetworkStatus(bool hasNetwork) {
    emit(state.copyWith(hasNetwork: hasNetwork));
    if (hasNetwork && !state.isGhostMode) {
      _drainQueue();
      NostrService.instance.setGhostMode(false);
    }
  }

  void incrementPendingQueue() {
    emit(state.copyWith(pendingQueueCount: state.pendingQueueCount + 1));
  }

  void decrementPendingQueue() {
    if (state.pendingQueueCount > 0) {
      emit(state.copyWith(pendingQueueCount: state.pendingQueueCount - 1));
    }
  }

  void _drainQueue() {
    if (state.pendingQueueCount > 0) {
      emit(state.copyWith(pendingQueueCount: 0));
    }
  }
}
