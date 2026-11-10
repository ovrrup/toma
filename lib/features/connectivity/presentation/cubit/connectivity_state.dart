import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  final bool isGhostMode;
  final bool hasNetwork;
  final int pendingQueueCount;

  const ConnectivityState({
    this.isGhostMode = false,
    this.hasNetwork = true,
    this.pendingQueueCount = 0,
  });

  /// True ONLY when hardware network is connected AND Ghost Mode is disabled
  bool get isEffectiveOnline => hasNetwork && !isGhostMode;

  ConnectivityState copyWith({
    bool? isGhostMode,
    bool? hasNetwork,
    int? pendingQueueCount,
  }) {
    return ConnectivityState(
      isGhostMode: isGhostMode ?? this.isGhostMode,
      hasNetwork: hasNetwork ?? this.hasNetwork,
      pendingQueueCount: pendingQueueCount ?? this.pendingQueueCount,
    );
  }

  @override
  List<Object?> get props => [isGhostMode, hasNetwork, pendingQueueCount];
}
