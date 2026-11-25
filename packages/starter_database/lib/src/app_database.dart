import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database_executor.dart';

part 'app_database.g.dart';

/// Stores synchronization metadata independently from feature entities.
class SyncMetadata extends Table {
  TextColumn get scope => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {scope};
}

/// Stores one serialized feature snapshot with its synchronization checkpoint.
class SyncSnapshots extends Table {
  TextColumn get scope => text()();
  TextColumn get payload => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {scope};
}

/// Shared database shell for product-owned Drift tables and migrations.
///
/// The starter owns only synchronization metadata. Product packages should
/// add their own tables in a product-specific database subclass rather than
/// coupling every generated app to one universal schema.
@DriftDatabase(tables: [SyncMetadata, SyncSnapshots])
class StarterDatabase extends _$StarterDatabase {
  /// Opens the default platform database for a product.
  StarterDatabase({String name = 'starter_database'})
    : super(driftDatabase(name: name));

  /// Opens an isolated in-memory database for tests and previews.
  StarterDatabase.memory() : super(createMemoryExecutor());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // Add explicit, ordered migrations here when the starter schema changes.
    },
  );

  /// Reads the checkpoint for one feature-owned synchronization scope.
  Future<SyncMetadataData?> readSyncMetadata(String scope) => (select(
    syncMetadata,
  )..where((row) => row.scope.equals(scope))).getSingleOrNull();

  /// Replaces one synchronization checkpoint atomically.
  Future<void> writeSyncMetadata({
    required String scope,
    required String? cursor,
    required DateTime? syncedAt,
  }) => transaction(
    () => into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        scope: scope,
        cursor: Value(cursor),
        syncedAt: Value(syncedAt),
      ),
    ),
  );

  /// Reads a feature-owned serialized snapshot in one database operation.
  Future<SyncSnapshot?> readSyncSnapshot(String scope) => (select(
    syncSnapshots,
  )..where((row) => row.scope.equals(scope))).getSingleOrNull();

  /// Replaces a feature snapshot and its cursor atomically.
  Future<void> writeSyncSnapshot({
    required String scope,
    required String payload,
    required String? cursor,
    required DateTime savedAt,
  }) => transaction(
    () => into(syncSnapshots).insertOnConflictUpdate(
      SyncSnapshotsCompanion.insert(
        scope: scope,
        payload: payload,
        cursor: Value(cursor),
        savedAt: savedAt,
      ),
    ),
  );
}
