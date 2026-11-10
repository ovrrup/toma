import 'package:drift/drift.dart';

/// Drift table definition for session history.
class SessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // pomodoro, deepWork, shortBreak, etc.
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get tag => text().nullable()();
  IntColumn get expEarned => integer()();
  IntColumn get coinsEarned => integer()();
  BoolColumn get wasCompleted => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
