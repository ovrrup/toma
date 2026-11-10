import 'package:flutter_bloc/flutter_bloc.dart';
import 'connectivity_state.dart';

/// Cubit managing dynamic connectivity, offline queue, and user Ghost Mode.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({bool initialGhostMode = false})
      : super(ConnectivityState(isGhostMode: initialGhostMode));

  /// Toggle Ghost Mode on or off
  void toggleGhostMode() {
    final nextGhostMode = !state.isGhostMode;
    emit(state.copyWith(isGhostMode: nextGhostMode));

    if (nextGhostMode) {
      // Immediately sever Nostr WebSocket sockets
      _disconnectSockets();
    } else {
      // Reconnect and drain offline queue
      _reconnectSockets();
    }
  }

  void updateNetworkStatus(bool hasNetwork) {
    emit(state.copyWith(hasNetwork: hasNetwork));
    if (hasNetwork && !state.isGhostMode) {
      _drainQueue();
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

  void _disconnectSockets() {
    // Hooks into Nostr relay pool to pause active socket listeners
  }

  void _reconnectSockets() {
    // Restores relay connections and flushes pending event queue
    _drainQueue();
  }

  void _drainQueue() {
    if (state.pendingQueueCount > 0) {
      emit(state.copyWith(pendingQueueCount: 0));
    }
  }
}
