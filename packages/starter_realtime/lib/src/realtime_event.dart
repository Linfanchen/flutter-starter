/// A typed envelope delivered by a realtime transport.
final class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    this.data,
    this.id,
    this.sequence,
  });

  /// Stable event type used by a feature reducer.
  final String type;

  /// Feature-owned payload. The infrastructure never interprets this value.
  final Object? data;

  /// Server-provided ID used for deduplication and stream resumption.
  final String? id;

  /// Optional monotonic sequence supplied by the server.
  final int? sequence;
}

/// Opens a realtime event stream and owns its underlying transport.
abstract interface class RealtimeEventSource {
  /// Opens a stream after [lastEventId] when the server supports resumption.
  Stream<RealtimeEvent> open({String? lastEventId});

  /// Closes active transport resources and makes the current stream finish.
  Future<void> close();
}

/// A failure emitted when a realtime stream ends unexpectedly.
final class RealtimeDisconnected implements Exception {
  const RealtimeDisconnected();

  @override
  String toString() => 'RealtimeDisconnected()';
}
