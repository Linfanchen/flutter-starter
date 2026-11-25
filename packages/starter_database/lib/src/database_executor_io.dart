import 'package:drift/native.dart';

/// Creates an isolated SQLite executor on native platforms.
NativeDatabase createMemoryExecutor() => NativeDatabase.memory();
