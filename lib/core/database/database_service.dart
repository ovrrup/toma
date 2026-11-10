import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/timer/domain/entities/session.dart';
import '../../features/timer/domain/entities/session_type.dart';

/// Representation of an event waiting in the offline queue to be dispatched to Nostr relays.
class PendingEvent {
  final String id;
  final int kind;
  final String eventJson;
  final DateTime createdAt;
  final int retryCount;

  PendingEvent({
    required this.id,
    required this.kind,
    required this.eventJson,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'eventJson': eventJson,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        id: json['id'] as String,
        kind: json['kind'] as int,
        eventJson: json['eventJson'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: (json['retryCount'] as int?) ?? 0,
      );
}

/// Persistent local storage service for Sessions, Gamification stats, and Offline Nostr Queue.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  File? _dbFile;
  Map<String, dynamic> _memoryCache = {
    'sessions': <Map<String, dynamic>>[],
    'pending_events': <Map<String, dynamic>>[],
    'profile': <String, dynamic>{
      'totalExp': 4850,
      'coinsBalance': 240,
      'streakDays': 7,
      'streakShields': 1,
      'lastSessionDate': null,
      'unlockedAesthetics': ['theme_default'],
      'activeTheme': 'theme_default',
    },
  };

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _dbFile = File('${dir.path}/toma_local_db.json');
      if (await _dbFile!.exists()) {
        final content = await _dbFile!.readAsString();
        if (content.isNotEmpty) {
          _memoryCache = jsonDecode(content) as Map<String, dynamic>;
        }
      } else {
        await _flush();
      }
    } catch (_) {
      // In-memory fallback if file system access fails in test
    }
  }

  Future<void> _flush() async {
    try {
      if (_dbFile != null) {
        await _dbFile!.writeAsString(jsonEncode(_memoryCache), flush: true);
      }
    } catch (_) {}
  }

  // --- Sessions Management ---

  Future<void> saveSession(Session session) async {
    final list = (_memoryCache['sessions'] as List<dynamic>);
    list.add({
      'id': session.id,
      'type': session.type.name,
      'durationMinutes': session.durationMinutes,
      'startedAt': session.startedAt.toIso8601String(),
      'completedAt': session.completedAt?.toIso8601String(),
      'tag': session.tag,
      'expEarned': session.expEarned,
      'coinsEarned': session.coinsEarned,
      'wasCompleted': session.wasCompleted,
    });
    await _flush();
  }

  List<Session> getSessions() {
    final list = (_memoryCache['sessions'] as List<dynamic>?);
    if (list == null) return [];
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return Session(
        id: map['id'] as String,
        type: SessionType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => SessionType.pomodoro,
        ),
        durationMinutes: map['durationMinutes'] as int,
        startedAt: DateTime.parse(map['startedAt'] as String),
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'] as String)
            : null,
        tag: map['tag'] as String?,
        expEarned: map['expEarned'] as int,
        coinsEarned: map['coinsEarned'] as int,
        wasCompleted: map['wasCompleted'] as bool,
      );
    }).toList();
  }

  // --- Offline Nostr Event Queue Management ---

  Future<void> enqueueEvent(PendingEvent event) async {
    final list = (_memoryCache['pending_events'] as List<dynamic>);
    list.add(event.toJson());
    await _flush();
  }

  List<PendingEvent> getPendingEvents() {
    final list = (_memoryCache['pending_events'] as List<dynamic>?);
    if (list == null) return [];
    return list
        .map((e) => PendingEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removePendingEvent(String id) async {
    final list = (_memoryCache['pending_events'] as List<dynamic>);
    list.removeWhere((item) => (item as Map<String, dynamic>)['id'] == id);
    await _flush();
  }

  // --- User Profile & Economy Management ---

  int getTotalExp() => (_memoryCache['profile']['totalExp'] as int?) ?? 0;
  int getCoinsBalance() => (_memoryCache['profile']['coinsBalance'] as int?) ?? 0;
  int getStreakDays() => (_memoryCache['profile']['streakDays'] as int?) ?? 0;

  Future<void> addRewards({required int exp, required int coins}) async {
    final currentExp = getTotalExp();
    final currentCoins = getCoinsBalance();
    _memoryCache['profile']['totalExp'] = currentExp + exp;
    _memoryCache['profile']['coinsBalance'] = currentCoins + coins;
    await _flush();
  }

  Future<bool> spendCoins(int amount) async {
    final currentCoins = getCoinsBalance();
    if (currentCoins >= amount) {
      _memoryCache['profile']['coinsBalance'] = currentCoins - amount;
      await _flush();
      return true;
    }
    return false;
  }
}
