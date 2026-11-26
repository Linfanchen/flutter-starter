import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter_ai/starter_ai.dart';

void main() {
  test('collects streamed assistant deltas', () async {
    final controller = ChatController(provider: _ChunkedProvider());

    await controller.send('Hello');

    expect(controller.messages, hasLength(2));
    expect(controller.messages.last.text, 'Hi there');
    expect(controller.messages.last.status, ChatMessageStatus.complete);
    controller.dispose();
  });

  test('stop preserves the partial assistant response', () async {
    final provider = _BlockingProvider();
    final controller = ChatController(provider: provider);
    final sending = controller.send('Keep this');

    await provider.started.future;
    await controller.stop();
    await sending;

    expect(controller.messages.last.text, 'Partial');
    expect(controller.messages.last.status, ChatMessageStatus.complete);
    controller.dispose();
  });

  test('retry replaces the failed assistant response', () async {
    final provider = _RetryProvider();
    final controller = ChatController(provider: provider);

    await controller.send('Try again');
    expect(controller.messages.last.status, ChatMessageStatus.failed);

    await controller.retry();

    expect(controller.messages, hasLength(2));
    expect(controller.messages.last.text, 'Recovered');
    expect(controller.messages.last.status, ChatMessageStatus.complete);
    controller.dispose();
  });
}

final class _ChunkedProvider implements AiChatProvider {
  @override
  Stream<ChatStreamEvent> complete(ChatRequest request) async* {
    yield const ChatStreamEvent(textDelta: 'Hi ');
    yield const ChatStreamEvent(textDelta: 'there', done: true);
  }
}

final class _BlockingProvider implements AiChatProvider {
  final Completer<void> started = Completer<void>();

  @override
  Stream<ChatStreamEvent> complete(ChatRequest request) async* {
    started.complete();
    yield const ChatStreamEvent(textDelta: 'Partial');
    await Completer<void>().future;
  }
}

final class _RetryProvider implements AiChatProvider {
  int attempts = 0;

  @override
  Stream<ChatStreamEvent> complete(ChatRequest request) async* {
    attempts += 1;
    if (attempts == 1) {
      throw StateError('temporary failure');
    }
    yield const ChatStreamEvent(textDelta: 'Recovered');
  }
}
