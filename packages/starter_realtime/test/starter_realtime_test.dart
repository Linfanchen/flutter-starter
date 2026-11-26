import 'dart:async';

import 'package:starter_realtime/starter_realtime.dart';
import 'package:test/test.dart';

void main() {
  test('reduces typed events and remembers the last event ID', () async {
    final source = _FakeSource([
      _events([const RealtimeEvent(type: 'increment', id: '1', data: 2)]),
    ]);
    final controller = RealtimeController<int>(
      initialValue: 0,
      source: source,
      reducer: (value, event) => value + ((event.data as int?) ?? 0),
      reconnectPolicy: _instantPolicy,
    );

    final done = controller.start();
    await source.waitForOpen(1);
    await Future<void>.delayed(Duration.zero);
    await controller.stop();
    await done;

    expect(controller.state.value, 2);
    expect(controller.state.lastEventId, '1');
    expect(source.lastEventId, isNull);
    await controller.dispose();
  });

  test('ignores duplicate event IDs', () async {
    final source = _FakeSource([
      _events([
        const RealtimeEvent(type: 'increment', id: 'same', data: 1),
        const RealtimeEvent(type: 'increment', id: 'same', data: 1),
      ]),
    ]);
    final controller = RealtimeController<int>(
      initialValue: 0,
      source: source,
      reducer: (value, event) => value + ((event.data as int?) ?? 0),
    );

    final done = controller.start();
    await source.waitForOpen(1);
    await Future<void>.delayed(Duration.zero);
    await controller.stop();
    await done;

    expect(controller.state.value, 1);
    await controller.dispose();
  });

  test('reconnects with the last event ID after a disconnect', () async {
    final source = _FakeSource([
      _events([const RealtimeEvent(type: 'increment', id: '1', data: 1)]),
      _events([const RealtimeEvent(type: 'increment', id: '2', data: 2)]),
    ]);
    final controller = RealtimeController<int>(
      initialValue: 0,
      source: source,
      reducer: (value, event) => value + ((event.data as int?) ?? 0),
      reconnectPolicy: _instantPolicy,
    );

    final done = controller.start();
    await source.waitForOpen(2);
    await controller.stop();
    await done;

    expect(controller.state.value, 3);
    expect(source.requestedEventIds, [null, '1']);
    await controller.dispose();
  });

  test('fails after the configured reconnect attempts', () async {
    final source = _FakeSource([_errorStream(StateError('offline'))]);
    final controller = RealtimeController<int>(
      initialValue: 0,
      source: source,
      reducer: (value, event) => value,
      reconnectPolicy: const RealtimeReconnectPolicy(
        maxAttempts: 1,
        initialDelay: Duration.zero,
        maxDelay: Duration.zero,
      ),
    );

    await controller.start();
    expect(controller.state.status, RealtimeStatus.failed);
    expect(controller.state.error, isA<StateError>());
    await controller.dispose();
  });

  test('reorders sequenced events and ignores late duplicates', () {
    final orderer = RealtimeEventOrderer();

    expect(
      orderer.accept(const RealtimeEvent(type: 'two', sequence: 2)),
      isEmpty,
    );
    expect(
      orderer.accept(const RealtimeEvent(type: 'one', sequence: 1)).map(
            (event) => event.type,
          ),
      ['one', 'two'],
    );
    expect(
      orderer.accept(const RealtimeEvent(type: 'late', sequence: 1)),
      isEmpty,
    );
  });

  test('replays persisted events without opening a transport', () async {
    final store = MemoryRealtimeEventStore();
    await store.append(const RealtimeEvent(type: 'increment', data: 2));
    await store.append(const RealtimeEvent(type: 'increment', data: 3));
    final session = RealtimeSession<int>(
      initialValue: 0,
      reducer: (value, event) => value + ((event.data as int?) ?? 0),
      store: store,
    );

    await session.restore();

    expect(session.value, 5);
  });

  test('persists only ordered events in a realtime session', () async {
    final store = MemoryRealtimeEventStore();
    final session = RealtimeSession<int>(
      initialValue: 0,
      reducer: (value, event) => value + ((event.data as int?) ?? 0),
      store: store,
    );

    await session.apply(const RealtimeEvent(type: 'two', sequence: 2, data: 2));
    expect(session.value, 0);
    await session.apply(const RealtimeEvent(type: 'one', sequence: 1, data: 1));

    expect(session.value, 3);
    expect((await store.read()).map((event) => event.type), ['one', 'two']);
  });
}

const _instantPolicy = RealtimeReconnectPolicy(
  initialDelay: Duration.zero,
  maxDelay: Duration.zero,
);

Stream<RealtimeEvent> _events(List<RealtimeEvent> events) async* {
  yield* Stream<RealtimeEvent>.fromIterable(events);
}

Stream<RealtimeEvent> _errorStream(Object error) async* {
  throw error;
}

final class _FakeSource implements RealtimeEventSource {
  _FakeSource(this.streams);

  final List<Stream<RealtimeEvent>> streams;
  final requestedEventIds = <String?>[];
  var opens = 0;
  String? lastEventId;

  @override
  Stream<RealtimeEvent> open({String? lastEventId}) {
    this.lastEventId = lastEventId;
    requestedEventIds.add(lastEventId);
    opens++;
    final index = opens - 1 < streams.length ? opens - 1 : streams.length - 1;
    return streams[index];
  }

  Future<void> waitForOpen(int count) async {
    while (opens < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<void> close() async {
    // The fake streams are finite; production sources close their sockets here.
  }
}
