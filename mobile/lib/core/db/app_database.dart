import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Reports waiting to go to the server. A report is written here first,
/// always, even when online, so nothing is lost if the send fails.
class OutboxReports extends Table {
  TextColumn get clientUuid => text()();
  TextColumn get payload => text()(); // JSON body for POST /reports
  TextColumn get photoPath => text().nullable()();
  // pending -> sending -> sent, or failed (retried later)
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get deviceTriage => text().nullable()(); // JSON triage result shown to the user
  DateTimeColumn get createdAt => dateTime()();

  // Added in schema 2 (sync worker):
  /// Not before this time: exponential backoff after a failed send.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get serverReportId => text().nullable()();
  TextColumn get serverCaseId => text().nullable()();
  BoolColumn get photoUploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

/// Server data kept for offline viewing. Each row stores the server's JSON
/// as-is, so the cache never needs a migration when the API adds a field.
class CachedCases extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedAdvisories extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  DateTimeColumn get sentAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedAnimals extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedVaccinationsDue extends Table {
  TextColumn get id => text()(); // animal id + vaccine
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small settings: language, API URL, login token, demo switches.
class KvSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  OutboxReports,
  CachedCases,
  CachedAdvisories,
  CachedAnimals,
  CachedVaccinationsDue,
  KvSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.onDevice() : super(driftDatabase(name: 'pashusetu'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // Phones installed with Phase 3 have schema 1: add the sync columns.
          if (from < 2) {
            await m.addColumn(outboxReports, outboxReports.nextAttemptAt);
            await m.addColumn(outboxReports, outboxReports.serverReportId);
            await m.addColumn(outboxReports, outboxReports.serverCaseId);
            await m.addColumn(outboxReports, outboxReports.photoUploaded);
          }
        },
      );

  // ---------- settings ----------

  Future<Map<String, String>> readSettings() async {
    final rows = await select(kvSettings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> writeSetting(String key, String? value) async {
    if (value == null) {
      await (delete(kvSettings)..where((t) => t.key.equals(key))).go();
    } else {
      await into(kvSettings).insertOnConflictUpdate(KvSettingsCompanion.insert(key: key, value: value));
    }
  }

  // ---------- outbox ----------

  /// Reports not yet confirmed by the server, for the sync pill.
  Stream<int> watchUnsentCount() {
    final unsent = outboxReports.status.isNotValue('sent');
    final count = outboxReports.clientUuid.count();
    return (selectOnly(outboxReports)
          ..addColumns([count])
          ..where(unsent))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  Future<List<OutboxReport>> allOutbox() =>
      (select(outboxReports)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Stream<OutboxReport?> watchOutboxItem(String clientUuid) =>
      (select(outboxReports)..where((t) => t.clientUuid.equals(clientUuid))).watchSingleOrNull();

  Stream<List<OutboxReport>> watchOutbox() =>
      (select(outboxReports)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // ---------- caches ----------

  Future<void> replaceCache<T extends Table, R>(
      TableInfo<T, R> table, List<Insertable<R>> rows) async {
    await transaction(() async {
      await delete(table).go();
      await batch((b) => b.insertAll(table, rows));
    });
  }

  /// Wipes everything on the phone except the settings (developer menu).
  Future<void> clearLocalData() => transaction(() async {
        for (final TableInfo table in [outboxReports, cachedCases, cachedAdvisories, cachedAnimals, cachedVaccinationsDue]) {
          await delete(table).go();
        }
      });
}
