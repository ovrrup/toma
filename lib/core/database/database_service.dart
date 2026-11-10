import 'dart:async';
import 'dart:convert';
import '../../features/gamification/data/repositories/gamification_repository.dart';
import '../../features/timer/domain/entities/session.dart';
import 'toma_database.dart';

export 'toma_database.dart' show PendingEvent;

/// Unified database service for Toma, backed by persistent SQLite via Drift.
/// Manages real session history, user progression, themes, and offline event queue.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  final TomaDatabase _db = TomaDatabase.instance;

  // Real cached progression values
  int _cachedExp = 0;
  int _cachedCoins = 0;
  int _cachedStreak = 0;
  int _cachedTotalMinutes = 0;
  int _cachedTodaySessionsCount = 0;
  String _cachedTheme = 'theme_default';
  final Set<String> _cachedUnlockedThemes = {'theme_default', 'default'};

  final StreamController<void> _updateStreamController =
      StreamController<void>.broadcast();

  Stream<void> get onDataUpdated => _updateStreamController.stream;

  Future<void> init([String? npub]) async {
    await _db.ensureInitialized();
    await _loadStatsAndProfile(npub);
  }

  Future<void> _loadStatsAndProfile(String? npub) async {
    final sessions = await _db.getAllSessions();

    int totalExp = 0;
    int totalCoins = 0;
    int totalMinutes = 0;
    int todayCount = 0;
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    final Set<String> activeDates = {};

    for (final s in sessions) {
      if (s.wasCompleted) {
        totalExp += s.expEarned;
        totalCoins += s.coinsEarned;
        totalMinutes += s.durationMinutes;

        final sessionKey = _dateKey(s.startedAt);
        activeDates.add(sessionKey);

        if (sessionKey == todayKey) {
          todayCount++;
        }
      }
    }

    _cachedExp = totalExp;
    _cachedCoins = totalCoins;
    _cachedTotalMinutes = totalMinutes;
    _cachedTodaySessionsCount = todayCount;
    _cachedStreak = _calculateStreak(activeDates, now);

    if (npub != null && npub.isNotEmpty) {
      final profile = await _db.getUserProfile(npub);
      if (profile != null) {
        _cachedTheme = (profile['active_theme'] as String?) ?? 'theme_default';
        try {
          final jsonStr = profile['unlocked_aesthetics_json'] as String? ?? '[]';
          final list = (jsonDecode(jsonStr) as List<dynamic>).map((e) => e.toString());
          _cachedUnlockedThemes.addAll(list);
        } catch (_) {}
      } else {
        await _db.upsertUserProfile(
          npub: npub,
          displayName: 'Focus Explorer',
          totalExp: _cachedExp,
          coinsBalance: _cachedCoins,
          streakDays: _cachedStreak,
          level: GamificationRepository.calculateLevel(_cachedExp),
          totalSessions: sessions.where((s) => s.wasCompleted).length,
          totalMinutes: _cachedTotalMinutes,
          activeTheme: _cachedTheme,
          unlockedAesthetics: jsonEncode(_cachedUnlockedThemes.toList()),
        );
      }
    }

    _updateStreamController.add(null);
  }

  // --- Sessions Management ---

  Future<void> saveSession(Session session, [String? npub]) async {
    await _db.insertSession(session);

    if (session.wasCompleted) {
      _cachedExp += session.expEarned;
      _cachedCoins += session.coinsEarned;
      _cachedTotalMinutes += session.durationMinutes;

      final now = DateTime.now();
      if (_dateKey(session.startedAt) == _dateKey(now)) {
        _cachedTodaySessionsCount++;
      }

      final allSessions = await _db.getAllSessions();
      final activeDates = allSessions
          .where((s) => s.wasCompleted)
          .map((s) => _dateKey(s.startedAt))
          .toSet();
      _cachedStreak = _calculateStreak(activeDates, now);

      if (npub != null && npub.isNotEmpty) {
        await _db.updateProfileExpAndCoins(
          npub: npub,
          addExp: session.expEarned,
          addCoins: session.coinsEarned,
        );
      }
    }

    _updateStreamController.add(null);
  }

  Future<List<Session>> getSessions() async {
    return _db.getAllSessions();
  }

  // --- Offline Nostr Event Queue Management ---

  Future<void> enqueueEvent(PendingEvent event) async {
    await _db.enqueuePendingEvent(event);
  }

  Future<List<PendingEvent>> getPendingEvents() async {
    return _db.getPendingEvents();
  }

  Future<void> removePendingEvent(String id) async {
    await _db.deletePendingEvent(id);
  }

  Future<void> recordEventFailure(String id) async {
    await _db.incrementEventRetry(id);
  }

  // --- User Profile & Economy Management ---

  int getTotalExp() => _cachedExp;
  int getCoinsBalance() => _cachedCoins;
  int getStreakDays() => _cachedStreak;
  int getTotalFocusMinutes() => _cachedTotalMinutes;
  int getTodaySessionsCount() => _cachedTodaySessionsCount;
  String getActiveTheme() => _cachedTheme;
  Set<String> getUnlockedThemes() => Set.unmodifiable(_cachedUnlockedThemes);

  Future<void> addRewards({required int exp, required int coins, String? npub}) async {
    _cachedExp += exp;
    _cachedCoins += coins;
    if (npub != null && npub.isNotEmpty) {
      await _db.updateProfileExpAndCoins(npub: npub, addExp: exp, addCoins: coins);
    }
    _updateStreamController.add(null);
  }

  Future<bool> spendCoins(int amount, [String? npub]) async {
    if (_cachedCoins >= amount) {
      _cachedCoins -= amount;
      if (npub != null && npub.isNotEmpty) {
        await _db.updateProfileExpAndCoins(npub: npub, addExp: 0, addCoins: -amount);
      }
      _updateStreamController.add(null);
      return true;
    }
    return false;
  }

  Future<void> setActiveTheme(String themeId, [String? npub]) async {
    _cachedTheme = themeId;
    if (npub != null && npub.isNotEmpty) {
      await _db.updateActiveTheme(npub, themeId);
    }
    _updateStreamController.add(null);
  }

  Future<void> unlockTheme(String themeId, [String? npub]) async {
    _cachedUnlockedThemes.add(themeId);
    if (npub != null && npub.isNotEmpty) {
      final jsonList = jsonEncode(_cachedUnlockedThemes.toList());
      await _db.updateUnlockedThemes(npub, jsonList);
    }
    _updateStreamController.add(null);
  }

  // --- Streak & Date Helpers ---

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateStreak(Set<String> activeDates, DateTime now) {
    if (activeDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    // If no session today yet, check if yesterday had a session to keep streak alive
    if (!activeDates.contains(_dateKey(checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!activeDates.contains(_dateKey(checkDate))) {
        return 0;
      }
    }

    while (activeDates.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
