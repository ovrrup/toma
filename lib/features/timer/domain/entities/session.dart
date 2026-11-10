import 'package:equatable/equatable.dart';
import 'session_type.dart';

/// Entity representing a completed or aborted focus session.
class Session extends Equatable {
  final String id;
  final SessionType type;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? tag;
  final int expEarned;
  final int coinsEarned;
  final bool wasCompleted;

  const Session({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.startedAt,
    this.completedAt,
    this.tag,
    required this.expEarned,
    required this.coinsEarned,
    required this.wasCompleted,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        durationMinutes,
        startedAt,
        completedAt,
        tag,
        expEarned,
        coinsEarned,
        wasCompleted,
      ];
}
