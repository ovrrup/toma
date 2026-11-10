import 'package:drift/drift.dart';

/// Drift table definition for offline queued Nostr events.
class PendingEventsTable extends Table {
  TextColumn get id => text()(); // 32-byte event ID hex
  IntColumn get kind => integer()(); // Nostr kind (e.g. 30150, 0, 3)
  TextColumn get eventJson => text()(); // Signed Nostr event JSON payload
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
