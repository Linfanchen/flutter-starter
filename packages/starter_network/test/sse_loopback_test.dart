@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:starter_network/starter_network.dart';
import 'package:test/test.dart';

void main() {
  test('cancelling SSE closes the real TCP connection', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final disconnected = Completer<void>();

    // Leave the response open so only the client's cancellation can end it.
    server.listen((socket) {
      addTearDown(socket.destroy);
      var responded = false;
      socket.listen(
        (_) {
          if (responded) return;
          responded = true;
          socket.write(
            'HTTP/1.1 200 OK\r\n'
            'Content-Type: text/event-stream\r\n'
            'Connection: close\r\n\r\n'
            'id: 7\ndata: online\n\n',
          );
          unawaited(socket.flush());
        },
        onDone: disconnected.complete,
        onError: (Object error, StackTrace stack) {
          if (!disconnected.isCompleted)
            disconnected.completeError(error, stack);
        },
      );
    });

    final client = ApiClient(baseUrl: Uri.http('127.0.0.1:${server.port}'));
    addTearDown(client.close);
    final first = Completer<SseEvent>();
    final subscription = client
        .openSse('events')
        .where((frame) => frame is SseEvent)
        .cast<SseEvent>()
        .listen(first.complete, onError: first.completeError);
    addTearDown(subscription.cancel);
    const deadline = Duration(seconds: 5);

    final event = await first.future.timeout(deadline);
    expect((event.id, event.data), ('7', 'online'));
    expect(disconnected.isCompleted, isFalse);
    await subscription.cancel().timeout(deadline);
    await disconnected.future.timeout(deadline);
  });
}
