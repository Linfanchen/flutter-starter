import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_provider.dart';

/// Coordinates chat history, streaming responses and request cancellation.
final class ChatController extends ChangeNotifier {
  ChatController({required AiChatProvider provider}) : _provider = provider;

  final AiChatProvider _provider;
  final List<ChatMessage> _messages = <ChatMessage>[];
  StreamSubscription<ChatStreamEvent>? _subscription;
  Completer<void>? _completion;
  String? _lastPrompt;
  bool _disposed = false;

  /// Returns an immutable view of the current conversation.
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  /// Whether an assistant response is currently being generated.
  bool get isGenerating => _subscription != null;

  /// Sends [prompt] and appends the streamed assistant response.
  Future<void> send(String prompt) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty || isGenerating) return;

    _lastPrompt = normalizedPrompt;
    _messages.add(
      ChatMessage(id: _newId(), role: ChatRole.user, text: normalizedPrompt),
    );
    final assistant = ChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      text: '',
      status: ChatMessageStatus.streaming,
    );
    _messages.add(assistant);
    _notify();
    await _complete(assistant.id);
  }

  /// Retries the most recent failed assistant response.
  Future<void> retry() async {
    if (isGenerating || _lastPrompt == null || _messages.length < 2) return;
    final last = _messages.last;
    final previous = _messages[_messages.length - 2];
    if (last.role != ChatRole.assistant ||
        last.status != ChatMessageStatus.failed ||
        previous.role != ChatRole.user) {
      return;
    }

    _messages.removeLast();
    final assistant = ChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      text: '',
      status: ChatMessageStatus.streaming,
    );
    _messages.add(assistant);
    _notify();
    await _complete(assistant.id);
  }

  /// Cancels the active stream and keeps the partial response as complete.
  Future<void> stop() async {
    final subscription = _subscription;
    if (subscription == null) return;
    _subscription = null;
    await subscription.cancel();
    _markLastStreamingAsComplete();
    _completion?.complete();
    _completion = null;
    _notify();
  }

  /// Removes all messages and resets the current prompt.
  void clear() {
    if (isGenerating) return;
    _messages.clear();
    _lastPrompt = null;
    _notify();
  }

  Future<void> _complete(String assistantId) async {
    final context = _messages
        .where((message) => message.id != assistantId)
        .toList(growable: false);
    final completion = Completer<void>();
    _completion = completion;
    var failed = false;
    try {
      final stream = _provider.complete(ChatRequest(messages: context));
      final subscription = stream.listen(
        (event) {
          _appendDelta(assistantId, event.textDelta);
        },
        onError: (Object error, StackTrace stackTrace) {
          failed = true;
          _subscription = null;
          _markFailed(assistantId, error);
          _notify();
          if (!completion.isCompleted) completion.complete();
        },
        onDone: () {
          _subscription = null;
          if (!failed) _markComplete(assistantId);
          _notify();
          if (!completion.isCompleted) completion.complete();
        },
        cancelOnError: false,
      );
      _subscription = subscription;
      await completion.future;
    } catch (error) {
      _subscription = null;
      _markFailed(assistantId, error);
      _notify();
      if (!completion.isCompleted) completion.complete();
    } finally {
      if (identical(_completion, completion)) _completion = null;
    }
  }

  void _appendDelta(String assistantId, String delta) {
    final index = _messages.indexWhere((message) => message.id == assistantId);
    if (index < 0) return;
    final message = _messages[index];
    _messages[index] = message.copyWith(text: message.text + delta);
    _notify();
  }

  void _markComplete(String assistantId) {
    final index = _messages.indexWhere((message) => message.id == assistantId);
    if (index < 0) return;
    _messages[index] = _messages[index].copyWith(
      status: ChatMessageStatus.complete,
      clearError: true,
    );
  }

  void _markFailed(String assistantId, Object error) {
    final index = _messages.indexWhere((message) => message.id == assistantId);
    if (index < 0) return;
    _messages[index] = _messages[index].copyWith(
      status: ChatMessageStatus.failed,
      error: error,
    );
  }

  void _markLastStreamingAsComplete() {
    if (_messages.isEmpty) return;
    final last = _messages.last;
    if (last.status == ChatMessageStatus.streaming) {
      _messages[_messages.length - 1] = last.copyWith(
        status: ChatMessageStatus.complete,
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
