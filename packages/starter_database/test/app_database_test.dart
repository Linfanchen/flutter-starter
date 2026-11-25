import 'package:starter_database/starter_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StarterDatabase database;

  setUp(() => database = StarterDatabase.memory());
  tearDown(() => database.close());

  test('writes and reads one synchronization checkpoint', () async {
    final syncedAt = DateTime.utc(2026, 11, 24);
    await database.writeSyncMetadata(
      scope: 'course.catalog',
      cursor: 'next-page',
      syncedAt: syncedAt,
    );

    final metadata = await database.readSyncMetadata('course.catalog');
    expect(metadata?.scope, 'course.catalog');
    expect(metadata?.cursor, 'next-page');
    expect(metadata?.syncedAt?.toUtc(), syncedAt);
  });

  test('upserts a checkpoint without creating duplicate scopes', () async {
    await database.writeSyncMetadata(
      scope: 'course.catalog',
      cursor: 'first',
      syncedAt: DateTime.utc(2026, 11, 24),
    );
    await database.writeSyncMetadata(
      scope: 'course.catalog',
      cursor: 'second',
      syncedAt: DateTime.utc(2026, 11, 25),
    );

    final rows = await database.select(database.syncMetadata).get();
    expect(rows, hasLength(1));
    expect(rows.single.cursor, 'second');
  });

  test('stores a serialized feature snapshot transactionally', () async {
    final savedAt = DateTime.utc(2026, 11, 24);
    await database.writeSyncSnapshot(
      scope: 'course.catalog',
      payload: '[{"id":"flutter-ui"}]',
      cursor: 'page-2',
      savedAt: savedAt,
    );

    final snapshot = await database.readSyncSnapshot('course.catalog');
    expect(snapshot?.payload, '[{"id":"flutter-ui"}]');
    expect(snapshot?.cursor, 'page-2');
    expect(snapshot?.savedAt.toUtc(), savedAt);
  });
}
