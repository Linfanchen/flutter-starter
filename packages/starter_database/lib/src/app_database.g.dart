// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scope,
    cursor,
    syncedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final String scope;
  final String? cursor;
  final DateTime? syncedAt;
  final int schemaVersion;
  const SyncMetadataData({
    required this.scope,
    this.cursor,
    this.syncedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      scope: Value(scope),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      scope: serializer.fromJson<String>(json['scope']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'cursor': serializer.toJson<String?>(cursor),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  SyncMetadataData copyWith({
    String? scope,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? schemaVersion,
  }) => SyncMetadataData(
    scope: scope ?? this.scope,
    cursor: cursor.present ? cursor.value : this.cursor,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      scope: data.scope.present ? data.scope.value : this.scope,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, cursor, syncedAt, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.scope == this.scope &&
          other.cursor == this.cursor &&
          other.syncedAt == this.syncedAt &&
          other.schemaVersion == this.schemaVersion);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> scope;
  final Value<String?> cursor;
  final Value<DateTime?> syncedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.scope = const Value.absent(),
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String scope,
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scope = Value(scope);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? scope,
    Expression<String>? cursor,
    Expression<DateTime>? syncedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (cursor != null) 'cursor': cursor,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? scope,
    Value<String?>? cursor,
    Value<DateTime?>? syncedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      scope: scope ?? this.scope,
      cursor: cursor ?? this.cursor,
      syncedAt: syncedAt ?? this.syncedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncSnapshotsTable extends SyncSnapshots
    with TableInfo<$SyncSnapshotsTable, SyncSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [scope, payload, cursor, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope};
  @override
  SyncSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSnapshot(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SyncSnapshotsTable createAlias(String alias) {
    return $SyncSnapshotsTable(attachedDatabase, alias);
  }
}

class SyncSnapshot extends DataClass implements Insertable<SyncSnapshot> {
  final String scope;
  final String payload;
  final String? cursor;
  final DateTime savedAt;
  const SyncSnapshot({
    required this.scope,
    required this.payload,
    this.cursor,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SyncSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SyncSnapshotsCompanion(
      scope: Value(scope),
      payload: Value(payload),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      savedAt: Value(savedAt),
    );
  }

  factory SyncSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSnapshot(
      scope: serializer.fromJson<String>(json['scope']),
      payload: serializer.fromJson<String>(json['payload']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'payload': serializer.toJson<String>(payload),
      'cursor': serializer.toJson<String?>(cursor),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SyncSnapshot copyWith({
    String? scope,
    String? payload,
    Value<String?> cursor = const Value.absent(),
    DateTime? savedAt,
  }) => SyncSnapshot(
    scope: scope ?? this.scope,
    payload: payload ?? this.payload,
    cursor: cursor.present ? cursor.value : this.cursor,
    savedAt: savedAt ?? this.savedAt,
  );
  SyncSnapshot copyWithCompanion(SyncSnapshotsCompanion data) {
    return SyncSnapshot(
      scope: data.scope.present ? data.scope.value : this.scope,
      payload: data.payload.present ? data.payload.value : this.payload,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSnapshot(')
          ..write('scope: $scope, ')
          ..write('payload: $payload, ')
          ..write('cursor: $cursor, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, payload, cursor, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSnapshot &&
          other.scope == this.scope &&
          other.payload == this.payload &&
          other.cursor == this.cursor &&
          other.savedAt == this.savedAt);
}

class SyncSnapshotsCompanion extends UpdateCompanion<SyncSnapshot> {
  final Value<String> scope;
  final Value<String> payload;
  final Value<String?> cursor;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SyncSnapshotsCompanion({
    this.scope = const Value.absent(),
    this.payload = const Value.absent(),
    this.cursor = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncSnapshotsCompanion.insert({
    required String scope,
    required String payload,
    this.cursor = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : scope = Value(scope),
       payload = Value(payload),
       savedAt = Value(savedAt);
  static Insertable<SyncSnapshot> custom({
    Expression<String>? scope,
    Expression<String>? payload,
    Expression<String>? cursor,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (payload != null) 'payload': payload,
      if (cursor != null) 'cursor': cursor,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncSnapshotsCompanion copyWith({
    Value<String>? scope,
    Value<String>? payload,
    Value<String?>? cursor,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SyncSnapshotsCompanion(
      scope: scope ?? this.scope,
      payload: payload ?? this.payload,
      cursor: cursor ?? this.cursor,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSnapshotsCompanion(')
          ..write('scope: $scope, ')
          ..write('payload: $payload, ')
          ..write('cursor: $cursor, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StarterDatabase extends GeneratedDatabase {
  _$StarterDatabase(QueryExecutor e) : super(e);
  $StarterDatabaseManager get managers => $StarterDatabaseManager(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final $SyncSnapshotsTable syncSnapshots = $SyncSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncMetadata,
    syncSnapshots,
  ];
}

typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String scope,
      Value<String?> cursor,
      Value<DateTime?> syncedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> scope,
      Value<String?> cursor,
      Value<DateTime?> syncedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$StarterDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$StarterDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$StarterDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$StarterDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<
              _$StarterDatabase,
              $SyncMetadataTable,
              SyncMetadataData
            >,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(
    _$StarterDatabase db,
    $SyncMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(
                scope: scope,
                cursor: cursor,
                syncedAt: syncedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                scope: scope,
                cursor: cursor,
                syncedAt: syncedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetadataTable, SyncMetadataData>(table),
                  BaseReferences<
                    _$StarterDatabase,
                    $SyncMetadataTable,
                    SyncMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$StarterDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$StarterDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;
typedef $$SyncSnapshotsTableCreateCompanionBuilder =
    SyncSnapshotsCompanion Function({
      required String scope,
      required String payload,
      Value<String?> cursor,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$SyncSnapshotsTableUpdateCompanionBuilder =
    SyncSnapshotsCompanion Function({
      Value<String> scope,
      Value<String> payload,
      Value<String?> cursor,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$SyncSnapshotsTableFilterComposer
    extends Composer<_$StarterDatabase, $SyncSnapshotsTable> {
  $$SyncSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncSnapshotsTableOrderingComposer
    extends Composer<_$StarterDatabase, $SyncSnapshotsTable> {
  $$SyncSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncSnapshotsTableAnnotationComposer
    extends Composer<_$StarterDatabase, $SyncSnapshotsTable> {
  $$SyncSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SyncSnapshotsTableTableManager
    extends
        RootTableManager<
          _$StarterDatabase,
          $SyncSnapshotsTable,
          SyncSnapshot,
          $$SyncSnapshotsTableFilterComposer,
          $$SyncSnapshotsTableOrderingComposer,
          $$SyncSnapshotsTableAnnotationComposer,
          $$SyncSnapshotsTableCreateCompanionBuilder,
          $$SyncSnapshotsTableUpdateCompanionBuilder,
          (
            SyncSnapshot,
            BaseReferences<
              _$StarterDatabase,
              $SyncSnapshotsTable,
              SyncSnapshot
            >,
          ),
          SyncSnapshot,
          PrefetchHooks Function()
        > {
  $$SyncSnapshotsTableTableManager(
    _$StarterDatabase db,
    $SyncSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncSnapshotsCompanion(
                scope: scope,
                payload: payload,
                cursor: cursor,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                required String payload,
                Value<String?> cursor = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncSnapshotsCompanion.insert(
                scope: scope,
                payload: payload,
                cursor: cursor,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncSnapshotsTable, SyncSnapshot>(table),
                  BaseReferences<
                    _$StarterDatabase,
                    $SyncSnapshotsTable,
                    SyncSnapshot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarterDatabase,
      $SyncSnapshotsTable,
      SyncSnapshot,
      $$SyncSnapshotsTableFilterComposer,
      $$SyncSnapshotsTableOrderingComposer,
      $$SyncSnapshotsTableAnnotationComposer,
      $$SyncSnapshotsTableCreateCompanionBuilder,
      $$SyncSnapshotsTableUpdateCompanionBuilder,
      (
        SyncSnapshot,
        BaseReferences<_$StarterDatabase, $SyncSnapshotsTable, SyncSnapshot>,
      ),
      SyncSnapshot,
      PrefetchHooks Function()
    >;

class $StarterDatabaseManager {
  final _$StarterDatabase _db;
  $StarterDatabaseManager(this._db);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
  $$SyncSnapshotsTableTableManager get syncSnapshots =>
      $$SyncSnapshotsTableTableManager(_db, _db.syncSnapshots);
}
