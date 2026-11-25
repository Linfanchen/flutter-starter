/// Credentials and expiry returned by an application's sign-in provider.
final class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.expiresAt,
  });

  final String userId;
  final String accessToken;
  final DateTime expiresAt;

  /// Treats the exact expiry instant as expired.
  bool isValidAt(DateTime instant) =>
      userId.isNotEmpty && accessToken.isNotEmpty && expiresAt.isAfter(instant);
}

/// Owns the stored session for one app account slot.
///
/// Production implementations must protect credentials on the target platform.
abstract interface class CredentialStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// Volatile storage for tests and demos. Never writes credentials to disk.
final class MemoryCredentialStore implements CredentialStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

/// Coordinates local session state with an injected credential store.
///
/// The application supplies sessions from its identity provider. This manager
/// handles local lifecycle only, so server validation and refresh stay upstream.
final class SessionManager {
  SessionManager(CredentialStore store, {DateTime Function()? now})
      : _store = store,
        _now = now ?? DateTime.now;

  final CredentialStore _store;
  final DateTime Function() _now;
  AuthSession? _session;
  Future<void> _pending = Future<void>.value();

  /// The current session, if it is still valid locally.
  AuthSession? get session {
    final value = _session;
    return value != null && value.isValidAt(_now()) ? value : null;
  }

  /// Restores active credentials and removes expired stored credentials.
  Future<AuthSession?> restore() => _enqueue(() async {
        final saved = await _store.read();
        _session = saved != null && saved.isValidAt(_now()) ? saved : null;
        if (saved != null && _session == null) await _store.clear();
        return _session;
      });

  /// Adopts credentials returned by a successful sign-in.
  Future<void> signIn(AuthSession value) => _enqueue(() async {
        if (!value.isValidAt(_now())) {
          throw ArgumentError('Expected an active session.');
        }
        await _store.write(value);
        _session = value;
      });

  /// Clears the in-memory session and the corresponding stored credentials.
  Future<void> signOut() => _enqueue(() async {
        _session = null;
        await _store.clear();
      });

  Future<T> _enqueue<T>(Future<T> Function() action) {
    // Preserve caller order when a sign-out follows a pending sign-in.
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
}
