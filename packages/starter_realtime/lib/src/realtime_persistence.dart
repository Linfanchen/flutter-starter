import 'realtime_event.dart';
import 'realtime_ordering.dart';
import 'realtime_state.dart';

/// Persists feature-owned realtime events for replay after process restart.
abstract interface class RealtimeEventStore {
  Future<List<RealtimeEvent>> read();

  Future<void> append(RealtimeEvent event);

  Future<void> clear();
}

/// A deterministic event store for tests, previews and small local sessions.
final class MemoryRealtimeEventStore implements RealtimeEventStore {
  final _events = <RealtimeEvent>[];

  @override
  Future<List<RealtimeEvent>> read() async => List.unmodifiable(_events);

  @override
  Future<void> append(RealtimeEvent event) async => _events.add(event);

  @override
  Future<void> clear() async => _events.clear();
}

/// Owns business state independently from the transport connection.
///
/// A session can replay persisted events without opening a socket. The
/// reducer remains feature-owned, while ordering, persistence and replay are
/// shared infrastructure concerns.
final class RealtimeSession<S> {
  RealtimeSession({
    required S initialValue,
    required RealtimeReducer<S> reducer,
    required RealtimeEventStore store,
    int lastAppliedSequence = 0,
  })  : _value = initialValue,
        _reducer = reducer,
        _store = store,
        _orderer = RealtimeEventOrderer(
          lastAppliedSequence: lastAppliedSequence,
        );

  final RealtimeReducer<S> _reducer;
  final RealtimeEventStore _store;
  final RealtimeEventOrderer _orderer;
  S _value;
  String? _lastEventId;

  S get value => _value;
  String? get lastEventId => _lastEventId;
  int get lastAppliedSequence => _orderer.lastAppliedSequence;

  /// Rebuilds the session from persisted events before opening a transport.
  Future<void> restore() async {
    for (final event in await _store.read()) {
      for (final ready in _orderer.accept(event)) {
        _reduce(ready);
      }
    }
  }

  /// Persists and reduces every event made ready by the ordering policy.
  Future<void> apply(RealtimeEvent event) async {
    for (final ready in _orderer.accept(event)) {
      await _store.append(ready);
      _reduce(ready);
    }
  }

  void _reduce(RealtimeEvent event) {
    _value = _reducer(_value, event);
    _lastEventId = event.id ?? _lastEventId;
  }
}
