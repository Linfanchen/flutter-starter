import 'dart:async';

import 'package:starter_sync/starter_sync.dart';
import 'package:test/test.dart';

void main() {
  test('returns fresh data and persists the next cursor', () async {
    final cache = _MemoryCache<int>();
    final result = await SyncCoordinator<int>(
      cache: cache,
      remote: _FakeRemote<int>(SyncPage(items: [1, 2], nextCursor: 'next')),
    ).synchronize();

    expect(result.items, [1, 2]);
    expect(result.status, SyncStatus.synced);
    expect((await cache.read())?.cursor, 'next');
  });

  test('falls back to a cached snapshot when refresh fails', () async {
    final cache = _MemoryCache<int>(
      SyncSnapshot(items: [1], cursor: 'cursor', savedAt: DateTime.utc(2026)),
    );
    final result = await SyncCoordinator<int>(
      cache: cache,
      remote: _FakeRemote<int>(StateError('offline')),
    ).synchronize();

    expect(result.items, [1]);
    expect(result.status, SyncStatus.stale);
    expect(result.error, isA<StateError>());
  });

  test('shares one active refresh between concurrent callers', () async {
    final gate = Completer<SyncPage<int>>();
    var calls = 0;
    final coordinator = SyncCoordinator<int>(
      cache: _MemoryCache<int>(),
      remote: _CallbackRemote<int>(() {
        calls++;
        return gate.future;
      }),
    );

    final first = coordinator.synchronize();
    final second = coordinator.synchronize();
    gate.complete(const SyncPage(items: [3]));

    expect((await Future.wait([first, second])).map((item) => item.items), [
      [3],
      [3],
    ]);
    expect(calls, 1);
  });

  test('merges a remote page with local items by feature-defined rules',
      () async {
    final result = await SyncCoordinator<int>(
      cache: _MemoryCache<int>(
        SyncSnapshot(items: [1, 2], savedAt: DateTime.utc(2026)),
      ),
      remote: _FakeRemote<int>(const SyncPage(items: [2, 3])),
      merge: (local, remote) => {...local, ...remote}.toList(),
    ).synchronize();

    expect(result.items, [1, 2, 3]);
  });

  test('keeps a failed local mutation retryable', () async {
    final store = _MemoryMutationStore<int>();
    var attempts = 0;
    final queue = SyncMutationQueue<int>(
      store: store,
      uploader: _CallbackUploader<int>((_) async {
        attempts++;
        if (attempts == 1) throw StateError('offline');
      }),
    );
    await queue.enqueue(
      SyncMutation(id: 'one', payload: 1, createdAt: DateTime.utc(2026)),
    );

    await expectLater(queue.flush(), throwsA(isA<StateError>()));
    expect((await store.pending()).single.attempts, 1);
    await queue.flush();
    expect(await store.pending(), isEmpty);
  });
}

final class _MemoryCache<T> implements SyncCache<T> {
  _MemoryCache([this.snapshot]);

  SyncSnapshot<T>? snapshot;

  @override
  Future<SyncSnapshot<T>?> read() async => snapshot;

  @override
  Future<void> write(SyncSnapshot<T> value) async => snapshot = value;
}

final class _FakeRemote<T> implements SyncRemote<T> {
  _FakeRemote(this.value);

  final Object value;

  @override
  Future<SyncPage<T>> fetch({String? cursor}) async {
    if (value case StateError error) throw error;
    return value as SyncPage<T>;
  }
}

final class _CallbackRemote<T> implements SyncRemote<T> {
  _CallbackRemote(this.callback);

  final Future<SyncPage<T>> Function() callback;

  @override
  Future<SyncPage<T>> fetch({String? cursor}) => callback();
}

final class _MemoryMutationStore<T> implements SyncMutationStore<T> {
  final values = <String, SyncMutation<T>>{};

  @override
  Future<List<SyncMutation<T>>> pending() async => values.values.toList();

  @override
  Future<void> put(SyncMutation<T> mutation) async =>
      values[mutation.id] = mutation;

  @override
  Future<void> remove(String id) async => values.remove(id);
}

final class _CallbackUploader<T> implements SyncMutationUploader<T> {
  _CallbackUploader(this.callback);

  final Future<void> Function(T payload) callback;

  @override
  Future<void> upload(T payload) => callback(payload);
}
