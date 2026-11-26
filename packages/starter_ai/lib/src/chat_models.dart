/// Identifies the author of one chat message.
enum ChatRole { user, assistant, system }

/// Describes the lifecycle of an assistant response.
enum ChatMessageStatus { complete, streaming, failed }

/// A provider-independent chat message.
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.status = ChatMessageStatus.complete,
    this.error,
  });

  final String id;
  final ChatRole role;
  final String text;
  final ChatMessageStatus status;
  final Object? error;

  ChatMessage copyWith({
    String? text,
    ChatMessageStatus? status,
    Object? error,
    bool clearError = false,
  }) => ChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    status: status ?? this.status,
    error: clearError ? null : error ?? this.error,
  );
}

/// A provider request containing the current conversation context.
final class ChatRequest {
  const ChatRequest({required this.messages});

  final List<ChatMessage> messages;
}

/// One incremental provider response event.
final class ChatStreamEvent {
  const ChatStreamEvent({this.textDelta = '', this.done = false});

  final String textDelta;
  final bool done;
}
