// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'chat_controller.dart';
import 'chat_models.dart';

/// A small Material chat surface that can be embedded in a product page.
final class AiChatView extends StatefulWidget {
  const AiChatView({required this.controller, super.key});

  final ChatController controller;

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

final class _AiChatViewState extends State<AiChatView> {
  late final TextEditingController _inputController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: widget.controller.messages.length,
          itemBuilder: (context, index) {
            final message = widget.controller.messages[index];
            return _MessageBubble(
              message: message,
              onRetry: message.status == ChatMessageStatus.failed
                  ? widget.controller.retry
                  : null,
            );
          },
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !widget.controller.isGenerating,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: widget.controller.isGenerating ? 'Stop' : 'Send',
                onPressed: widget.controller.isGenerating ? _stop : _send,
                icon: Icon(
                  widget.controller.isGenerating
                      ? Icons.stop_circle_outlined
                      : Icons.send,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _onChanged() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final prompt = _inputController.text;
    _inputController.clear();
    widget.controller.send(prompt);
  }

  void _stop() {
    widget.controller.stop();
  }
}

final class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(message.text.isEmpty ? '…' : message.text),
            if (message.status == ChatMessageStatus.failed && onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
