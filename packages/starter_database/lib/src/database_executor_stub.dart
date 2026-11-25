import 'package:drift/drift.dart';

/// Web does not open an in-memory native SQLite database in this package.
QueryExecutor createMemoryExecutor() =>
    throw UnsupportedError('Use a web Drift executor for browser tests.');
