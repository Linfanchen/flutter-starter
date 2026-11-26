import 'realtime_event.dart';

/// Reorders sequenced events and ignores already applied sequence numbers.
///
/// Servers should start sequence numbers at one. Events without a sequence
/// are passed through immediately because the infrastructure cannot infer
/// their ordering semantics.
final class RealtimeEventOrderer {
  RealtimeEventOrderer({int lastAppliedSequence = 0})
      : _lastAppliedSequence = lastAppliedSequence;

  int _lastAppliedSequence;
  final _pending = <int, RealtimeEvent>{};

  /// Accepts one event and returns all events that are now safe to reduce.
  List<RealtimeEvent> accept(RealtimeEvent event) {
    final sequence = event.sequence;
    if (sequence == null) return [event];
    if (sequence <= _lastAppliedSequence) return const [];
    _pending[sequence] = event;
    final ready = <RealtimeEvent>[];
    while (_pending.containsKey(_lastAppliedSequence + 1)) {
      final next = ++_lastAppliedSequence;
      ready.add(_pending.remove(next)!);
    }
    return ready;
  }

  int get lastAppliedSequence => _lastAppliedSequence;
}
