import 'package:drift/drift.dart';

/// Drift table definition for the local user profile, stats, and unlocked aesthetics.
class UserProfilesTable extends Table {
  TextColumn get npub => text()(); // Bech32 Nostr public key
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get totalExp => integer().withDefault(const Constant(0))();
  IntColumn get coinsBalance => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get streakShields => integer().withDefault(const Constant(1))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get totalSessionsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get totalFocusMinutes => integer().withDefault(const Constant(0))();
  TextColumn get activeTheme => text().withDefault(const Constant('theme_default'))();
  TextColumn get unlockedAestheticsJson => text().withDefault(const Constant('["theme_default"]'))();

  @override
  Set<Column> get primaryKey => {npub};
}
