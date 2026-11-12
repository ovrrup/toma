import 'dart:async';
import '../../features/timer/domain/entities/session.dart';

/// Data entity representing an offline queued Nostr event.
class PendingEvent {
  final String id;
  final int kind;
  final String eventJson;
  final DateTime createdAt;
  final int retryCount;

  const PendingEvent({
    required this.id,
    required this.kind,
    required this.eventJson,
    required this.createdAt,
    this.retryCount = 0,
  });
}

/// Persistent database for Toma.
class TomaDatabase {
  static TomaDatabase? _instance;
  static TomaDatabase get instance => _instance ??= TomaDatabase._();

  TomaDatabase._();

  final Map<String, Session> _sessions = {};
  final Map<String, PendingEvent> _pendingEvents = {};
  final Map<String, Map<String, dynamic>> _userProfiles = {};

  bool _initialized = false;

  /// Ensures database schema is initialized.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
  }

  // --- Sessions Operations ---

  Future<void> insertSession(Session session) async {
    await ensureInitialized();
    _sessions[session.id] = session;
  }

  Future<List<Session>> getAllSessions() async {
    await ensureInitialized();
    final list = _sessions.values.toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  // --- Offline Pending Events Queue (FIFO) ---

  Future<void> enqueuePendingEvent(PendingEvent event) async {
    await ensureInitialized();
    _pendingEvents[event.id] = event;
  }

  Future<List<PendingEvent>> getPendingEvents() async {
    await ensureInitialized();
    final list = _pendingEvents.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> deletePendingEvent(String id) async {
    await ensureInitialized();
    _pendingEvents.remove(id);
  }

  Future<void> incrementEventRetry(String id) async {
    await ensureInitialized();
    final existing = _pendingEvents[id];
    if (existing != null) {
      _pendingEvents[id] = PendingEvent(
        id: existing.id,
        kind: existing.kind,
        eventJson: existing.eventJson,
        createdAt: existing.createdAt,
        retryCount: existing.retryCount + 1,
      );
    }
  }

  // --- User Profile & Economy Operations ---

  Future<Map<String, dynamic>?> getUserProfile(String npub) async {
    await ensureInitialized();
    return _userProfiles[npub];
  }

  Future<void> upsertUserProfile({
    required String npub,
    required String displayName,
    int totalExp = 0,
    int coinsBalance = 0,
    int streakDays = 0,
    int longestStreak = 0,
    int level = 1,
    int totalSessions = 0,
    int totalMinutes = 0,
    String activeTheme = 'theme_default',
    String unlockedAesthetics = '["theme_default"]',
  }) async {
    await ensureInitialized();
    _userProfiles[npub] = {
      'npub': npub,
      'display_name': displayName,
      'total_exp': totalExp,
      'coins_balance': coinsBalance,
      'streak_days': streakDays,
      'longest_streak': longestStreak,
      'level': level,
      'total_sessions_completed': totalSessions,
      'total_focus_minutes': totalMinutes,
      'active_theme': activeTheme,
      'unlocked_aesthetics_json': unlockedAesthetics,
    };
  }

  Future<void> updateProfileExpAndCoins({
    required String npub,
    required int addExp,
    required int addCoins,
  }) async {
    await ensureInitialized();
    final profile = _userProfiles[npub];
    if (profile != null) {
      profile['total_exp'] = ((profile['total_exp'] as int?) ?? 0) + addExp;
      profile['coins_balance'] = ((profile['coins_balance'] as int?) ?? 0) + addCoins;
    }
  }

  Future<void> updateActiveTheme(String npub, String themeId) async {
    await ensureInitialized();
    final profile = _userProfiles[npub];
    if (profile != null) {
      profile['active_theme'] = themeId;
    }
  }

  Future<void> updateUnlockedThemes(String npub, String jsonList) async {
    await ensureInitialized();
    final profile = _userProfiles[npub];
    if (profile != null) {
      profile['unlocked_aesthetics_json'] = jsonList;
    }
  }
}
