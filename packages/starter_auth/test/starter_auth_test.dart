import 'package:starter_auth/starter_auth.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 24);
  AuthSession at(DateTime expiresAt) =>
      AuthSession(userId: 'user', accessToken: 'fixture', expiresAt: expiresAt);

  test('restores an active session and clears credentials on sign-out',
      () async {
    final store = MemoryCredentialStore();
    final active = at(now.add(const Duration(minutes: 5)));
    await SessionManager(store, now: () => now).signIn(active);
    final restarted = SessionManager(store, now: () => now);
    expect(await restarted.restore(), same(active));
    await restarted.signOut();
    expect(restarted.session, isNull);
    expect(await store.read(), isNull);
  });

  test('clears expired credentials and preserves operation order', () async {
    final store = MemoryCredentialStore();
    final manager = SessionManager(store, now: () => now);
    await store.write(at(now));
    expect(await manager.restore(), isNull);
    expect(await store.read(), isNull);
    final signIn = manager.signIn(at(now.add(const Duration(minutes: 5))));
    final signOut = manager.signOut();
    await Future.wait([signIn, signOut]);
    expect(manager.session, isNull);
    expect(await store.read(), isNull);
  });
}
