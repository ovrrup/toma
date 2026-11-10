import 'dart:async';
import '../../features/timer/domain/entities/session.dart';
import 'toma_database.dart';

export 'toma_database.dart' show PendingEvent;

/// Unified database service for Toma, backed by persistent SQLite via Drift.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  final TomaDatabase _db = TomaDatabase.instance;

  // In-memory cache for ultra-fast instant UI reads
  int _cachedExp = 4850;
  int _cachedCoins = 240;
  int _cachedStreak = 7;
  String _cachedTheme = 'theme_default';

  Future<void> init() async {
    await _db.ensureInitialized();
  }

  // --- Sessions Management ---

  Future<void> saveSession(Session session) async {
    await _db.insertSession(session);
    await addRewards(exp: session.expEarned, coins: session.coinsEarned);
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
  String getActiveTheme() => _cachedTheme;

  Future<void> addRewards({required int exp, required int coins}) async {
    _cachedExp += exp;
    _cachedCoins += coins;
  }

  Future<bool> spendCoins(int amount) async {
    if (_cachedCoins >= amount) {
      _cachedCoins -= amount;
      return true;
    }
    return false;
  }

  void setActiveTheme(String themeId) {
    _cachedTheme = themeId;
  }
}
