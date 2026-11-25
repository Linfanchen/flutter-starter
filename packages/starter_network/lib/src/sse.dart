import 'dart:async';
import 'dart:convert';

/// A parsed event or server-provided retry hint.
sealed class SseFrame {
  const SseFrame();
}

/// An SSE event dispatched after a blank line.
final class SseEvent extends SseFrame {
  const SseEvent({required this.id, required this.event, required this.data});

  /// The current stream cursor. An empty value resets the cursor.
  final String id;

  /// Server event type, defaulting to `message`.
  final String event;

  /// Raw text with consecutive `data:` fields joined by newlines.
  final String data;
}

/// A server-suggested retry delay. The client does not reconnect automatically.
final class SseRetry extends SseFrame {
  const SseRetry(this.delay);

  final Duration delay;
}

final _digitsOnly = RegExp(r'^[0-9]+$');
// Bound both an unterminated line and the accumulated event payload.
const _maxFrameLength = 1024 * 1024;

/// Decodes one response body. Incomplete events at EOF are discarded.
Stream<SseFrame> parseSse(Stream<List<int>> bytes, String lastEventId) {
  var id = lastEventId;
  var event = '';
  final data = <String>[];
  var dataLength = 0;

  void handleLine(String line, EventSink<SseFrame> output) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        output.add(
          SseEvent(
            id: id,
            event: event.isEmpty ? 'message' : event,
            data: data.join('\n'),
          ),
        );
      }
      data.clear();
      dataLength = 0;
      // The ID persists across events, while event types and data do not.
      event = '';
      return;
    }
    final colon = line.indexOf(':');
    if (colon == 0) return;
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        dataLength += value.length + 1;
        if (dataLength > _maxFrameLength) {
          throw const FormatException('SSE event exceeds the size limit.');
        }
        data.add(value);
      case 'id':
        if (!value.contains('\u0000')) id = value;
      case 'retry':
        if (!_digitsOnly.hasMatch(value)) return;
        final milliseconds = int.tryParse(value);
        if (milliseconds != null && milliseconds <= 2147483647) {
          output.add(SseRetry(Duration(milliseconds: milliseconds)));
        }
    }
  }

  return _lines(utf8.decoder.bind(bytes)).transform(
    StreamTransformer<String, SseFrame>.fromHandlers(handleData: handleLine),
  );
}

Stream<String> _lines(Stream<String> chunks) {
  final line = StringBuffer();
  var afterCr = false;
  void handleChunk(String chunk, EventSink<String> output) {
    var start = 0;
    for (var index = 0; index < chunk.length; index++) {
      final char = chunk.codeUnitAt(index);
      if (afterCr) {
        afterCr = false;
        // A CRLF pair is one line terminator even across transport chunks.
        if (char == 10) {
          start = index + 1;
          continue;
        }
      }
      if (char != 13 && char != 10) continue;
      _append(line, chunk, start, index);
      output.add(line.toString());
      line.clear();
      afterCr = char == 13;
      start = index + 1;
    }
    _append(line, chunk, start, chunk.length);
  }

  return chunks.transform(
    StreamTransformer<String, String>.fromHandlers(handleData: handleChunk),
  );
}

void _append(StringBuffer line, String chunk, int start, int end) {
  if (line.length + end - start > _maxFrameLength) {
    throw const FormatException('SSE line exceeds the size limit.');
  }
  if (start != end) line.write(chunk.substring(start, end));
}
