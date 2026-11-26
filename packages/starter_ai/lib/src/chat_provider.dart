import 'chat_models.dart';

/// Connects the chat feature to a product-owned AI backend.
abstract interface class AiChatProvider {
  /// Streams response text until [ChatStreamEvent.done] is true.
  Stream<ChatStreamEvent> complete(ChatRequest request);
}
