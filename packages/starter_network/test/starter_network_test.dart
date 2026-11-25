import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starter_network/starter_network.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('https://example.test/api');

  test('JSON POST preserves the payload and emits safe diagnostics', () async {
    final diagnostics = <ApiDiagnostic>[];
    final client = ApiClient(
      baseUrl: baseUrl,
      onDiagnostic: (event) {
        diagnostics.add(event);
        throw StateError('A failing log sink should not fail the request.');
      },
      transport: MockClient((request) async {
        expect(request.url.path, '/api/articles');
        expect(request.headers['authorization'], 'Bearer test-secret');
        expect(
            request.headers['content-type'], 'application/json; charset=utf-8');
        expect(jsonDecode(request.body), {'title': '文章'});
        return http.Response.bytes(utf8.encode('{"title":"文章"}'), 201);
      }),
    );
    addTearDown(client.close);

    expect(
      await client.post(
        'articles?id=secret',
        body: {'title': '文章'},
        headers: {'Authorization': 'Bearer test-secret'},
      ),
      {'title': '文章'},
    );
    final event = diagnostics.single;
    expect(event.method, 'POST');
    expect(event.protocol, ApiProtocol.json);
    expect(event.statusCode, 201);
    expect(event.failure, isNull);
    expect(event.requestId, 1);
  });

  test('JSON classifies non-2xx, invalid JSON and transport failures',
      () async {
    final diagnostics = <ApiDiagnostic>[];
    final client = ApiClient(
      baseUrl: baseUrl,
      onDiagnostic: diagnostics.add,
      transport: MockClient((request) async => switch (request.url.path) {
            '/api/status' => http.Response('private body', 503),
            '/api/json' => http.Response('not JSON', 200),
            _ => throw http.ClientException('private transport detail'),
          }),
    );
    addTearDown(client.close);

    await expectLater(
        client.get('status'), throwsA(_failure(ApiFailure.httpStatus)));
    await expectLater(
        client.get('json'), throwsA(_failure(ApiFailure.invalidJson)));
    await expectLater(
        client.get('network'), throwsA(_failure(ApiFailure.transport)));
    expect(diagnostics.map((event) => event.statusCode), [503, 200, null]);
    expect(diagnostics.map((event) => event.requestId), [1, 2, 3]);
  });

  test('JSON timeout triggers cancellation of the request', () async {
    final aborted = Completer<void>();
    final client = ApiClient(
      baseUrl: baseUrl,
      timeout: const Duration(milliseconds: 10),
      transport: _Transport((request) async {
        await request.abortTrigger;
        aborted.complete();
        throw http.RequestAbortedException();
      }),
    );
    addTearDown(client.close);
    await expectLater(
        client.get('slow'), throwsA(_failure(ApiFailure.timeout)));
    await aborted.future;
  });

  test('SSE parses fragmented UTF-8 and preserves ID and retry hints',
      () async {
    final diagnostics = <ApiDiagnostic>[];
    final client = ApiClient(
      baseUrl: baseUrl,
      onDiagnostic: diagnostics.add,
      transport: _Transport((request) async {
        expect(request.headers['Accept'], 'text/event-stream');
        expect(request.headers['Last-Event-ID'], 'resume-1');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {'prompt': 'Hello'});
        final payload = utf8.encode(
          '\uFEFF: heartbeat\r\n'
          'retry: 1200\r\n\r\n'
          'event: delta\rid: 2\rdata: 你好\rdata:  world\r\r'
          'id: ignored\u0000value\nretry: +10\ndata: again\n\n'
          'id\ndata\n\n'
          'data: discard at EOF',
        );
        return _sse(Stream.fromIterable(payload.map((byte) => [byte])));
      }),
    );
    addTearDown(client.close);
    final frames = await client.openSse(
      'events',
      lastEventId: 'resume-1',
      method: SseMethod.post,
      body: {'prompt': 'Hello'},
    ).toList();
    expect(frames.whereType<SseRetry>().single.delay,
        const Duration(milliseconds: 1200));
    expect(
      frames
          .whereType<SseEvent>()
          .map((frame) => (frame.id, frame.event, frame.data)),
      [
        ('2', 'delta', '你好\n world'),
        ('2', 'message', 'again'),
        ('', 'message', '')
      ],
    );
    expect(diagnostics.single.protocol, ApiProtocol.sse);
    expect(diagnostics.single.failure, isNull);
  });

  test('SSE validates HTTP status and event-stream MIME type', () async {
    final client = ApiClient(
      baseUrl: baseUrl,
      transport: _Transport((request) async => switch (request.url.path) {
            '/api/stop' => http.StreamedResponse(const Stream.empty(), 204),
            '/api/html' => http.StreamedResponse(
                const Stream.empty(),
                200,
                headers: {'content-type': 'text/html'},
              ),
            _ => http.StreamedResponse(const Stream.empty(), 401),
          }),
    );
    addTearDown(client.close);
    expect(await client.openSse('stop').toList(), isEmpty);
    await expectLater(client.openSse('html').toList(),
        throwsA(_failure(ApiFailure.invalidSse)));
    await expectLater(client.openSse('auth').toList(),
        throwsA(_failure(ApiFailure.httpStatus)));
  });

  test('SSE idle timeout aborts the response', () async {
    final aborted = Completer<void>();
    final bytes = StreamController<List<int>>();
    addTearDown(() => unawaited(bytes.close()));
    final client = ApiClient(
      baseUrl: baseUrl,
      transport: _Transport((request) async {
        unawaited(request.abortTrigger!.then((_) => aborted.complete()));
        return _sse(bytes.stream);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client
          .openSse('events', idleTimeout: const Duration(milliseconds: 10))
          .toList(),
      throwsA(_failure(ApiFailure.timeout)),
    );
    await aborted.future;
  });

  test('SSE cancellation works even before response headers arrive', () async {
    final started = Completer<void>();
    final aborted = Completer<void>();
    final diagnostics = <ApiDiagnostic>[];
    final client = ApiClient(
      baseUrl: baseUrl,
      onDiagnostic: diagnostics.add,
      transport: _Transport((request) async {
        started.complete();
        await request.abortTrigger;
        aborted.complete();
        throw http.RequestAbortedException();
      }),
    );
    addTearDown(client.close);
    final subscription = client.openSse('events').listen((_) {});
    await started.future;
    await subscription.cancel();
    await aborted.future;
    expect(diagnostics.single.failure, ApiFailure.cancelled);
  });

  test('SSE rejects oversized input without dispatching an event', () async {
    final client = ApiClient(
      baseUrl: baseUrl,
      transport: _Transport((_) async => _sse(Stream.value(
            utf8.encode('data: ${'x' * (1024 * 1024)}'),
          ))),
    );
    addTearDown(client.close);
    await expectLater(
      client.openSse('events').toList(),
      throwsA(_failure(ApiFailure.invalidSse)),
    );
  });
}

Matcher _failure(ApiFailure failure) =>
    isA<ApiException>().having((error) => error.failure, 'failure', failure);

http.StreamedResponse _sse(Stream<List<int>> bytes) =>
    http.StreamedResponse(bytes, 200,
        headers: {'content-type': 'Text/Event-Stream; charset=utf-8'});

final class _Transport extends http.BaseClient {
  _Transport(this.handler);

  final Future<http.StreamedResponse> Function(http.AbortableRequest) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request as http.AbortableRequest);
}
