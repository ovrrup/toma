import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/sessions_table.dart';
import 'tables/pending_events_table.dart';
import 'tables/user_profiles_table.dart';
import '../../features/timer/domain/entities/session.dart';
import '../../features/timer/domain/entities/session_type.dart';
import 'database_service.dart';

/// Database connection opener targeting application documents folder.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'toma_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

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

/// Persistent Drift / SQLite database for Toma.
class TomaDatabase {
  static TomaDatabase? _instance;
  static TomaDatabase get instance => _instance ??= TomaDatabase._();

  final QueryExecutor _executor;

  TomaDatabase._() : _executor = _openConnection();

  /// Constructor for testing with an in-memory executor.
  TomaDatabase.forTesting(this._executor);

  bool _initialized = false;

  /// Ensures SQLite schema is initialized.
  Future<void> ensureInitialized() async {
    if (_initialized) return;

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY NOT NULL,
        type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        tag TEXT,
        exp_earned INTEGER NOT NULL,
        coins_earned INTEGER NOT NULL,
        was_completed INTEGER NOT NULL
      );
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS pending_events (
        id TEXT PRIMARY KEY NOT NULL,
        kind INTEGER NOT NULL,
        event_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt INTEGER
      );
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        npub TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        avatar_url TEXT,
        total_exp INTEGER NOT NULL DEFAULT 0,
        coins_balance INTEGER NOT NULL DEFAULT 0,
        streak_days INTEGER NOT NULL DEFAULT 0,
        streak_shields INTEGER NOT NULL DEFAULT 1,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        total_sessions_completed INTEGER NOT NULL DEFAULT 0,
        total_focus_minutes INTEGER NOT NULL DEFAULT 0,
        active_theme TEXT NOT NULL DEFAULT 'theme_default',
        unlocked_aesthetics_json TEXT NOT NULL DEFAULT '["theme_default"]'
      );
    ''');

    _initialized = true;
  }

  // --- Sessions Operations ---

  Future<void> insertSession(Session session) async {
    await ensureInitialized();
    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO sessions (
        id, type, duration_minutes, started_at, completed_at, tag, exp_earned, coins_earned, was_completed
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        session.id,
        session.type.name,
        session.durationMinutes,
        session.startedAt.millisecondsSinceEpoch,
        session.completedAt?.millisecondsSinceEpoch,
        session.tag,
        session.expEarned,
        session.coinsEarned,
        session.wasCompleted ? 1 : 0,
      ],
    );
  }

  Future<List<Session>> getAllSessions() async {
    await ensureInitialized();
    final results = await _executor.runSelect(
      'SELECT * FROM sessions ORDER BY started_at DESC;',
      [],
    );

    return results.map((row) {
      return Session(
        id: row['id'] as String,
        type: SessionType.values.firstWhere(
          (t) => t.name == row['type'],
          orElse: () => SessionType.pomodoro,
        ),
        durationMinutes: row['duration_minutes'] as int,
        startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
        completedAt: row['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int)
            : null,
        tag: row['tag'] as String?,
        expEarned: row['exp_earned'] as int,
        coinsEarned: row['coins_earned'] as int,
        wasCompleted: (row['was_completed'] as int) == 1,
      );
    }).toList();
  }

  // --- Offline Pending Events Queue (FIFO) ---

  Future<void> enqueuePendingEvent(PendingEvent event) async {
    await ensureInitialized();
    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO pending_events (
        id, kind, event_json, created_at, retry_count, last_attempt
      ) VALUES (?, ?, ?, ?, ?, ?);
      ''',
      [
        event.id,
        event.kind,
        event.eventJson,
        event.createdAt.millisecondsSinceEpoch,
        event.retryCount,
        null,
      ],
    );
  }

  Future<List<PendingEvent>> getPendingEvents() async {
    await ensureInitialized();
    final results = await _executor.runSelect(
      'SELECT * FROM pending_events ORDER BY created_at ASC;',
      [],
    );

    return results.map((row) {
      return PendingEvent(
        id: row['id'] as String,
        kind: row['kind'] as int,
        eventJson: row['event_json'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        retryCount: row['retry_count'] as int,
      );
    }).toList();
  }

  Future<void> deletePendingEvent(String id) async {
    await ensureInitialized();
    await _executor.runDelete(
      'DELETE FROM pending_events WHERE id = ?;',
      [id],
    );
  }

  Future<void> incrementEventRetry(String id) async {
    await ensureInitialized();
    await _executor.runUpdate(
      '''
      UPDATE pending_events
      SET retry_count = retry_count + 1, last_attempt = ?
      WHERE id = ?;
      ''',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  // --- User Profile & Economy Operations ---

  Future<Map<String, dynamic>?> getUserProfile(String npub) async {
    await ensureInitialized();
    final results = await _executor.runSelect(
      'SELECT * FROM user_profiles WHERE npub = ? LIMIT 1;',
      [npub],
    );
    if (results.isEmpty) return null;
    return results.first;
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
    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO user_profiles (
        npub, display_name, total_exp, coins_balance, streak_days,
        longest_streak, level, total_sessions_completed, total_focus_minutes,
        active_theme, unlocked_aesthetics_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        npub,
        displayName,
        totalExp,
        coinsBalance,
        streakDays,
        longestStreak,
        level,
        totalSessions,
        totalMinutes,
        activeTheme,
        unlockedAesthetics,
      ],
    );
  }

  Future<void> updateProfileExpAndCoins({
    required String npub,
    required int addExp,
    required int addCoins,
  }) async {
    await ensureInitialized();
    await _executor.runUpdate(
      '''
      UPDATE user_profiles
      SET total_exp = total_exp + ?, coins_balance = coins_balance + ?
      WHERE npub = ?;
      ''',
      [addExp, addCoins, npub],
    );
  }

  Future<void> updateActiveTheme(String npub, String themeId) async {
    await ensureInitialized();
    await _executor.runUpdate(
      'UPDATE user_profiles SET active_theme = ? WHERE npub = ?;',
      [themeId, npub],
    );
  }

  Future<void> updateUnlockedThemes(String npub, String jsonList) async {
    await ensureInitialized();
    await _executor.runUpdate(
      'UPDATE user_profiles SET unlocked_aesthetics_json = ? WHERE npub = ?;',
      [jsonList, npub],
    );
  }
}
