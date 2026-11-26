import 'dart:async';

import 'realtime_event.dart';
import 'realtime_state.dart';

/// Coordinates a realtime source, reducer, deduplication and reconnection.
///
/// The controller owns transport lifecycle but never interprets feature data.
/// A feature supplies a reducer that maps [RealtimeEvent] values to its own
/// immutable state. The returned state stream can be consumed by a ViewModel
/// or another explicit feature state owner.
final class RealtimeController<S> {
  RealtimeController({
    required S initialValue,
    required RealtimeEventSource source,
    required RealtimeReducer<S> reducer,
    this.reconnectPolicy = const RealtimeReconnectPolicy(),
    this.maxRememberedEventIds = 256,
  })  : _source = source,
        _reducer = reducer,
        _state = RealtimeState<S>(
          status: RealtimeStatus.idle,
          value: initialValue,
        ) {
    if (maxRememberedEventIds < 1) {
      throw ArgumentError.value(
        maxRememberedEventIds,
        'maxRememberedEventIds',
        'Must be positive.',
      );
    }
  }

  final RealtimeEventSource _source;
  final RealtimeReducer<S> _reducer;
  final RealtimeReconnectPolicy reconnectPolicy;
  final int maxRememberedEventIds;
  final _states = StreamController<RealtimeState<S>>.broadcast();
  final _rememberedEventIds = <String>{};
  final _eventIdOrder = <String>[];
  RealtimeState<S> _state;
  Future<void>? _run;
  var _running = false;
  var _disposed = false;

  /// Emits state changes, including connection lifecycle transitions.
  Stream<RealtimeState<S>> get states => _states.stream;

  /// Returns the latest immutable state synchronously.
  RealtimeState<S> get state => _state;

  /// Starts one controller loop. Repeated calls share the active Future.
  Future<void> start() {
    if (_disposed)
      return Future<void>.error(StateError('Controller disposed.'));
    if (_run != null) return _run!;
    _running = true;
    return _run = _runLoop().whenComplete(() => _run = null);
  }

  /// Stops the source and waits until the controller loop has finished.
  Future<void> stop() async {
    _running = false;
    await _source.close();
    final run = _run;
    if (run != null) await run;
    if (!_disposed) _emit(_state.copyWith(status: RealtimeStatus.stopped));
  }

  /// Releases the transport and closes the state stream permanently.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _running = false;
    await _source.close();
    final run = _run;
    if (run != null) await run;
    await _states.close();
  }

  Future<void> _runLoop() async {
    var attempt = 0;
    while (_running && !_disposed) {
      _emit(
        _state.copyWith(
          status: attempt == 0
              ? RealtimeStatus.connecting
              : RealtimeStatus.reconnecting,
          reconnectAttempt: attempt,
          clearError: true,
        ),
      );
      try {
        final stream = _source.open(lastEventId: _state.lastEventId);
        _emit(_state.copyWith(status: RealtimeStatus.connected));
        await for (final event in stream) {
          if (!_running || _disposed) break;
          if (_isDuplicate(event)) continue;
          final value = _reducer(_state.value, event);
          _emit(
            _state.copyWith(
              value: value,
              lastEventId: event.id,
              status: RealtimeStatus.connected,
              reconnectAttempt: 0,
              clearError: true,
            ),
          );
        }
        if (!_running || _disposed) break;
        throw const RealtimeDisconnected();
      } on Object catch (error) {
        if (!_running || _disposed) break;
        attempt++;
        if (attempt > reconnectPolicy.maxAttempts) {
          _emit(
            _state.copyWith(
              status: RealtimeStatus.failed,
              error: error,
              reconnectAttempt: attempt,
            ),
          );
          break;
        }
        _emit(
          _state.copyWith(
            status: RealtimeStatus.reconnecting,
            error: error,
            reconnectAttempt: attempt,
          ),
        );
        await Future<void>.delayed(reconnectPolicy.delayFor(attempt));
      }
    }
  }

  bool _isDuplicate(RealtimeEvent event) {
    final id = event.id;
    if (id == null || id.isEmpty) return false;
    if (!_rememberedEventIds.add(id)) return true;
    _eventIdOrder.add(id);
    if (_eventIdOrder.length > maxRememberedEventIds) {
      _rememberedEventIds.remove(_eventIdOrder.removeAt(0));
    }
    return false;
  }

  void _emit(RealtimeState<S> next) {
    if (_disposed) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
