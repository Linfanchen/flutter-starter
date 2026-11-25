import 'package:shared_preferences/shared_preferences.dart';

/// Stores non-sensitive strings. Callers own key names and payload formats.
abstract interface class StringStore {
  /// Reads a value, returning null for an absent key.
  Future<String?> read(String key);

  /// Replaces the value at [key].
  Future<void> write(String key, String value);

  /// Removes the value at [key], if present.
  Future<void> remove(String key);
}

/// In-memory implementation for tests and local previews.
final class MemoryStringStore implements StringStore {
  MemoryStringStore([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

/// Platform preferences for small, non-critical values.
///
/// Writes and removals are queued within one instance. Reads wait for earlier
/// writes. Share an instance when several pages use the same keys.
final class PreferencesStringStore implements StringStore {
  final _preferences = SharedPreferencesAsync();
  Future<void> _pending = Future<void>.value();

  @override
  Future<String?> read(String key) async {
    await _pending;
    try {
      return await _preferences.getString(key);
    } on TypeError {
      // Old app versions may have written a different preference type.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _enqueue(() => _preferences.setString(key, value));

  @override
  Future<void> remove(String key) => _enqueue(() => _preferences.remove(key));

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    // The caller sees its own failure. Later writes can still proceed.
    _pending = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
