import 'realtime_event.dart';

/// Lifecycle states exposed by a realtime controller.
enum RealtimeStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  stopped,
  failed,
}

/// Immutable feature state plus transport lifecycle metadata.
final class RealtimeState<S> {
  const RealtimeState({
    required this.status,
    required this.value,
    this.lastEventId,
    this.error,
    this.reconnectAttempt = 0,
  });

  final RealtimeStatus status;
  final S value;
  final String? lastEventId;
  final Object? error;
  final int reconnectAttempt;

  RealtimeState<S> copyWith({
    RealtimeStatus? status,
    S? value,
    String? lastEventId,
    Object? error,
    int? reconnectAttempt,
    bool clearError = false,
  }) =>
      RealtimeState<S>(
        status: status ?? this.status,
        value: value ?? this.value,
        lastEventId: lastEventId ?? this.lastEventId,
        error: clearError ? null : error ?? this.error,
        reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      );
}

/// Reduces one transport event into feature-owned immutable state.
typedef RealtimeReducer<S> = S Function(S current, RealtimeEvent event);

/// Provides bounded reconnect delays without coupling the controller to a
/// particular backend or timer implementation.
final class RealtimeReconnectPolicy {
  const RealtimeReconnectPolicy({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;

  /// Returns the delay before the one-based [attempt].
  Duration delayFor(int attempt) {
    if (attempt <= 0) return Duration.zero;
    var delay = initialDelay;
    for (var index = 1; index < attempt; index++) {
      final doubled = delay * 2;
      delay = doubled > maxDelay ? maxDelay : doubled;
    }
    return delay > maxDelay ? maxDelay : delay;
  }
}
