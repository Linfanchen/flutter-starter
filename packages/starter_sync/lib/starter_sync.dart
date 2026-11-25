/// Transport-independent primitives for local-first synchronization.
library;

/// The lifecycle of the most recent synchronization attempt.
enum SyncStatus { idle, syncing, synced, stale, failed }

/// A page returned by a remote synchronization source.
final class SyncPage<T> {
  const SyncPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

/// A locally persisted snapshot and the cursor used to request its next page.
final class SyncSnapshot<T> {
  const SyncSnapshot({
    required this.items,
    this.cursor,
    required this.savedAt,
  });

  final List<T> items;
  final String? cursor;
  final DateTime savedAt;
}

/// The result returned to a repository after local or remote synchronization.
final class SyncResult<T> {
  const SyncResult({
    required this.items,
    required this.status,
    this.cursor,
    this.error,
    required this.savedAt,
  });

  final List<T> items;
  final SyncStatus status;
  final String? cursor;
  final Object? error;
  final DateTime savedAt;

  bool get isStale => status == SyncStatus.stale;
}

/// Persists feature-owned snapshots without knowing their serialization.
abstract interface class SyncCache<T> {
  Future<SyncSnapshot<T>?> read();

  Future<void> write(SyncSnapshot<T> snapshot);
}

/// Loads one page from the product's remote data source.
abstract interface class SyncRemote<T> {
  Future<SyncPage<T>> fetch({String? cursor});
}

/// Merges a freshly fetched page into the locally cached items.
typedef SyncMerge<T> = List<T> Function(List<T> local, List<T> remote);

/// Coordinates local-first reads, one remote refresh, and offline fallback.
///
/// The coordinator deliberately does not depend on Flutter, a database, or an
/// HTTP client. Features decide how entities are serialized and how remote
/// pages are fetched. A single active Future prevents duplicate refreshes.
final class SyncCoordinator<T> {
  SyncCoordinator({
    required this.cache,
    required this.remote,
    SyncMerge<T>? merge,
  }) : _merge = merge ?? ((_, remote) => remote);

  final SyncCache<T> cache;
  final SyncRemote<T> remote;
  final SyncMerge<T> _merge;
  Future<SyncResult<T>>? _active;

  /// Reads the snapshot first and refreshes it once when the remote is usable.
  ///
  /// If refreshing fails but a snapshot exists, stale data remains available
  /// and the error is returned for diagnostics. Without a snapshot, the error
  /// is rethrown so the UI can show its normal recoverable error state.
  Future<SyncResult<T>> synchronize() {
    return _active ??= _synchronize().whenComplete(() => _active = null);
  }

  Future<SyncResult<T>> _synchronize() async {
    final local = await cache.read();
    try {
      final page = await remote.fetch(cursor: local?.cursor);
      final savedAt = DateTime.now().toUtc();
      final snapshot = SyncSnapshot<T>(
        items: List.unmodifiable(_merge(local?.items ?? const [], page.items)),
        cursor: page.nextCursor,
        savedAt: savedAt,
      );
      await cache.write(snapshot);
      return SyncResult<T>(
        items: snapshot.items,
        status: SyncStatus.synced,
        cursor: snapshot.cursor,
        savedAt: savedAt,
      );
    } on Object catch (error) {
      if (local == null) rethrow;
      return SyncResult<T>(
        items: local.items,
        status: SyncStatus.stale,
        cursor: local.cursor,
        error: error,
        savedAt: local.savedAt,
      );
    }
  }
}

/// A durable local operation waiting to be sent to a remote service.
final class SyncMutation<T> {
  const SyncMutation({
    required this.id,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final T payload;
  final DateTime createdAt;
  final int attempts;
  final Object? lastError;

  SyncMutation<T> failed(Object error) => SyncMutation<T>(
        id: id,
        payload: payload,
        createdAt: createdAt,
        attempts: attempts + 1,
        lastError: error,
      );
}

/// Persists pending local operations in a feature-owned format.
abstract interface class SyncMutationStore<T> {
  Future<List<SyncMutation<T>>> pending();

  Future<void> put(SyncMutation<T> mutation);

  Future<void> remove(String id);
}

/// Sends one local operation to the server and owns retry bookkeeping.
abstract interface class SyncMutationUploader<T> {
  Future<void> upload(T payload);
}

/// Flushes mutations in creation order and prevents concurrent flushes.
final class SyncMutationQueue<T> {
  SyncMutationQueue({required this.store, required this.uploader});

  final SyncMutationStore<T> store;
  final SyncMutationUploader<T> uploader;
  Future<void>? _active;

  /// Adds a local operation without contacting the network.
  Future<void> enqueue(SyncMutation<T> mutation) => store.put(mutation);

  /// Uploads all pending operations. A failed item remains retryable.
  Future<void> flush() =>
      _active ??= _flush().whenComplete(() => _active = null);

  Future<void> _flush() async {
    for (final mutation in await store.pending()) {
      try {
        await uploader.upload(mutation.payload);
        await store.remove(mutation.id);
      } on Object catch (error) {
        await store.put(mutation.failed(error));
        rethrow;
      }
    }
  }
}
