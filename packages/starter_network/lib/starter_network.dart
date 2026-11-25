import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'src/sse.dart';

export 'src/sse.dart' show SseEvent, SseFrame, SseRetry;

/// Failure categories shared by JSON requests and SSE connections.
enum ApiFailure {
  timeout,
  transport,
  httpStatus,
  invalidJson,
  invalidSse,
  cancelled,
}

/// Identifies the transport operation in request diagnostics.
enum ApiProtocol { json, sse }

/// HTTP methods supported by [ApiClient.openSse].
enum SseMethod { get, post }

/// A request summary without URLs, headers, payloads or raw exceptions.
final class ApiDiagnostic {
  const ApiDiagnostic({
    required this.requestId,
    required this.method,
    required this.protocol,
    required this.elapsed,
    this.statusCode,
    this.failure,
  });

  /// A monotonically increasing ID scoped to one client instance.
  final int requestId;
  final String method;
  final ApiProtocol protocol;
  final Duration elapsed;
  final int? statusCode;

  /// Null when the request or stream ended normally.
  final ApiFailure? failure;
}

/// A network failure described without exposing a URL or response body.
final class ApiException implements Exception {
  const ApiException(this.failure, {this.statusCode});

  final ApiFailure failure;
  final int? statusCode;

  @override
  String toString() => 'ApiException(${failure.name}, status: $statusCode)';
}

/// A same-origin HTTP client for JSON requests and SSE connections.
final class ApiClient {
  /// Uses the supplied transport or the platform default.
  ///
  /// Ownership of [transport] is transferred to this client. [onDiagnostic]
  /// receives one summary per completed, failed or cancelled network operation.
  ApiClient({
    required Uri baseUrl,
    this.timeout = const Duration(seconds: 15),
    http.Client? transport,
    void Function(ApiDiagnostic)? onDiagnostic,
  })  : _baseUrl = _normalize(baseUrl),
        _client = transport ?? http.Client(),
        _onDiagnostic = onDiagnostic;

  final Uri _baseUrl;
  final http.Client _client;
  final void Function(ApiDiagnostic)? _onDiagnostic;

  /// Timeout for a JSON request or for receiving SSE response headers.
  final Duration timeout;
  final _activeStreams = <void Function()>{};
  var _nextRequestId = 0;
  var _closed = false;

  /// Fetches decoded JSON from [path]. An empty response returns null.
  Future<Object?> get(String path, {Map<String, String>? headers}) =>
      _send('GET', path, headers);

  /// Sends a JSON-encoded [body] and returns the decoded response.
  Future<Object?> post(
    String path, {
    required Object? body,
    Map<String, String>? headers,
  }) =>
      _send('POST', path, headers, body: jsonEncode(body));

  /// Opens a single SSE connection when listened to.
  ///
  /// [idleTimeout] measures time between received byte chunks, so heartbeat
  /// comments keep the stream alive. Pass null to disable this timeout.
  /// Supply a previously received event ID to attempt resumption. Reconnection
  /// and server-side task cancellation are caller responsibilities. Cancelling
  /// the subscription aborts the request on transports that support abortion.
  Stream<SseFrame> openSse(
    String path, {
    Map<String, String>? headers,
    String lastEventId = '',
    Duration? idleTimeout = const Duration(seconds: 45),
    SseMethod method = SseMethod.get,
    Object? body,
  }) {
    if (method == SseMethod.get && body != null) {
      throw ArgumentError('An SSE GET request cannot carry a body.');
    }
    if (lastEventId.contains(RegExp(r'[\r\n\x00]'))) {
      throw ArgumentError('Last-Event-ID cannot contain CR, LF or NUL.');
    }
    final abort = Completer<void>();
    final request = _request(
      method == SseMethod.get ? 'GET' : 'POST',
      path,
      headers,
      abort,
      body: method == SseMethod.post ? jsonEncode(body) : null,
    );
    request.headers['accept'] = 'text/event-stream';
    request.headers.remove('last-event-id');
    if (lastEventId.isNotEmpty) {
      request.headers['last-event-id'] = lastEventId;
    }

    late final StreamController<SseFrame> controller;
    StreamSubscription<SseFrame>? subscription;
    var stopped = false;
    int? statusCode;
    late final int requestId;
    final elapsed = Stopwatch();

    void abortRequest() {
      if (!abort.isCompleted) abort.complete();
    }

    // Normal completion, transport failure, and cancellation share one terminal path.
    void finish([ApiFailure? failure]) {
      if (stopped) return;
      stopped = true;
      elapsed.stop();
      _emitDiagnostic(
        requestId,
        request.method,
        ApiProtocol.sse,
        elapsed.elapsed,
        statusCode,
        failure,
      );
      unawaited(controller.close());
    }

    Future<void> stop() async {
      if (!stopped) {
        abortRequest();
        finish(ApiFailure.cancelled);
      }
      await subscription?.cancel();
    }

    void stopFromClient() => unawaited(stop());

    void fail(ApiException error) {
      if (stopped) return;
      abortRequest();
      controller.addError(error);
      finish(error.failure);
    }

    Future<void> connect() async {
      try {
        if (_closed) {
          fail(const ApiException(ApiFailure.cancelled));
          return;
        }
        final response = await _client.send(request).timeout(timeout);
        if (stopped) {
          // A custom transport may still resolve after cancellation.
          await _discard(response);
          return;
        }
        statusCode = response.statusCode;
        if (response.statusCode == 204) {
          unawaited(_discard(response));
          finish();
          return;
        }
        if (response.statusCode != 200) {
          fail(ApiException(ApiFailure.httpStatus, statusCode: statusCode));
          unawaited(_discard(response));
          return;
        }
        if (!_isEventStream(response.headers)) {
          fail(ApiException(ApiFailure.invalidSse, statusCode: statusCode));
          unawaited(_discard(response));
          return;
        }
        final bytes = idleTimeout == null
            ? response.stream
            : response.stream.timeout(idleTimeout);
        subscription = parseSse(bytes, lastEventId).listen(
          controller.add,
          onError: (Object error) => fail(_sseFailure(error, statusCode)),
          onDone: finish,
          cancelOnError: true,
        );
        if (controller.isPaused) subscription?.pause();
      } catch (error) {
        fail(_sseFailure(error, statusCode));
      }
    }

    controller = StreamController<SseFrame>(
      onListen: () {
        requestId = ++_nextRequestId;
        elapsed.start();
        _activeStreams.add(stopFromClient);
        unawaited(connect());
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        _activeStreams.remove(stopFromClient);
        return stop();
      },
    );
    return controller.stream;
  }

  /// Stops active SSE subscriptions and releases the owned HTTP transport.
  void close() {
    if (_closed) return;
    _closed = true;
    for (final stop in _activeStreams.toList()) {
      stop();
    }
    _client.close();
  }

  Future<Object?> _send(
    String method,
    String path,
    Map<String, String>? headers, {
    String? body,
  }) async {
    final abort = Completer<void>();
    final request = _request(method, path, headers, abort, body: body)
      ..headers.putIfAbsent('accept', () => 'application/json');
    final elapsed = Stopwatch()..start();
    final requestId = ++_nextRequestId;
    int? statusCode;
    ApiFailure? failure;
    try {
      try {
        final response = await _client.send(request).then((streamed) {
          if (abort.isCompleted) {
            unawaited(_discard(streamed));
            throw const ApiException(ApiFailure.cancelled);
          }
          statusCode = streamed.statusCode;
          if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
            unawaited(_discard(streamed));
            throw ApiException(ApiFailure.httpStatus, statusCode: statusCode);
          }
          return http.Response.fromStream(streamed);
        }).timeout(timeout);
        if (response.bodyBytes.isEmpty) return null;
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on TimeoutException {
        throw const ApiException(ApiFailure.timeout);
      } on http.ClientException {
        throw const ApiException(ApiFailure.transport);
      } on FormatException {
        throw const ApiException(ApiFailure.invalidJson);
      }
    } on ApiException catch (error) {
      failure = error.failure;
      if (!abort.isCompleted) abort.complete();
      rethrow;
    } finally {
      _emitDiagnostic(
        requestId,
        method,
        ApiProtocol.json,
        elapsed.elapsed,
        statusCode,
        failure,
      );
    }
  }

  http.AbortableRequest _request(
    String method,
    String path,
    Map<String, String>? headers,
    Completer<void> abort, {
    String? body,
  }) {
    if (_closed) throw StateError('The API client is closed.');
    // Keep caller-supplied headers on the configured API origin.
    final target = _baseUrl.resolve(path);
    if (target.scheme != _baseUrl.scheme ||
        target.host != _baseUrl.host ||
        target.port != _baseUrl.port ||
        target.userInfo.isNotEmpty) {
      throw ArgumentError.value(
          path, 'path', 'Expected a URL on the API origin');
    }
    // Disable redirects so the origin check also covers the final request.
    final request = http.AbortableRequest(
      method,
      target,
      abortTrigger: abort.future,
    )..followRedirects = false;
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      request.headers['content-type'] = 'application/json; charset=utf-8';
      request.body = body;
    }
    return request;
  }

  void _emitDiagnostic(
    int requestId,
    String method,
    ApiProtocol protocol,
    Duration elapsed,
    int? statusCode,
    ApiFailure? failure,
  ) {
    try {
      _onDiagnostic?.call(
        ApiDiagnostic(
          requestId: requestId,
          method: method,
          protocol: protocol,
          elapsed: elapsed,
          statusCode: statusCode,
          failure: failure,
        ),
      );
    } catch (_) {
      // A diagnostic sink must not change network behavior.
    }
  }
}

bool _isEventStream(Map<String, String> headers) {
  for (final header in headers.entries) {
    if (header.key.toLowerCase() == 'content-type') {
      return header.value.split(';').first.trim().toLowerCase() ==
          'text/event-stream';
    }
  }
  return false;
}

Future<void> _discard(http.StreamedResponse response) async {
  try {
    await response.stream.listen(null, onError: (Object _) {}).cancel();
  } catch (_) {
    // Cleanup cannot replace the original request outcome.
  }
}

ApiException _sseFailure(Object error, int? statusCode) => ApiException(
      switch (error) {
        TimeoutException() => ApiFailure.timeout,
        FormatException() => ApiFailure.invalidSse,
        http.RequestAbortedException() => ApiFailure.cancelled,
        _ => ApiFailure.transport,
      },
      statusCode: statusCode,
    );

Uri _normalize(Uri url) {
  if (!{'http', 'https'}.contains(url.scheme) ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty ||
      url.hasQuery ||
      url.hasFragment) {
    throw ArgumentError(
        'baseUrl must be an HTTP(S) URL without credentials, query, or fragment');
  }
  return url.path.endsWith('/') ? url : url.replace(path: '${url.path}/');
}
