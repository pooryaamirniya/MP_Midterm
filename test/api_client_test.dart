import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/api_client.dart';
import 'package:soundify/core/models.dart';

import 'support/fakes.dart';

const original = {
  'access': 'expired',
  'refresh': 'refresh-1',
  'user': {'email': 'test@example.com', 'username': 'test'},
};

void main() {
  late MemoryStore store;
  late Dio transport, refresh;
  late ApiClient api;
  setUp(() async {
    store = MemoryStore();
    transport = Dio();
    refresh = Dio();
    api = ApiClient(store, transport: transport, refreshTransport: refresh);
    await api.accept(Map<String, dynamic>.of(original));
  });
  test(
    'concurrent 401s share one refresh and replay with the rotated pair',
    () async {
      var calls = 0;
      refresh.httpClientAdapter = FakeAdapter((o) async {
        calls++;
        expect(o.data, {'refresh': 'refresh-1'});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return response(200, {'access': 'fresh', 'refresh': 'refresh-2'});
      });
      transport.httpClientAdapter = FakeAdapter(
        (o) => o.headers['Authorization'] == 'Bearer fresh'
            ? response(200, {'ok': true})
            : response(401, {
                'error': {'code': 'expired'},
              }),
      );
      final results = await Future.wait(
        List.generate(8, (_) => api.dio.get<Json>('/users/me')),
      );
      expect(results.every((r) => r.data?['ok'] == true), true);
      expect(calls, 1);
      expect(store.value?['refresh'], 'refresh-2');
      expect(store.value?['user'], original['user']);
    },
  );
  test('refresh network errors preserve the session for retry', () async {
    refresh.httpClientAdapter = FakeAdapter(
      (o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      ),
    );
    transport.httpClientAdapter = FakeAdapter((o) => response(401, {}));
    await expectLater(
      api.dio.get<Json>('/users/me'),
      throwsA(isA<DioException>()),
    );
    expect(store.value?['refresh'], 'refresh-1');
    expect(api.session, isNotNull);
  });
  test(
    'revoked refresh clears encrypted record and signals expiration once',
    () async {
      var expired = 0;
      api.onSessionExpired = () => expired++;
      refresh.httpClientAdapter = FakeAdapter((o) => response(401, {}));
      transport.httpClientAdapter = FakeAdapter((o) => response(401, {}));
      await expectLater(
        api.dio.get<Json>('/users/me'),
        throwsA(isA<DioException>()),
      );
      expect(api.session, isNull);
      expect(store.value, isNull);
      expect(expired, 1);
    },
  );
  test('a replayed 401 never triggers an infinite refresh loop', () async {
    var calls = 0;
    refresh.httpClientAdapter = FakeAdapter((o) {
      calls++;
      return response(200, {'access': 'fresh', 'refresh': 'refresh-2'});
    });
    transport.httpClientAdapter = FakeAdapter((o) => response(401, {}));
    await expectLater(
      api.dio.get<Json>('/favorites'),
      throwsA(isA<DioException>()),
    );
    expect(calls, 1);
  });
  test(
    'public login failures do not refresh or attach existing bearer tokens',
    () async {
      var calls = 0;
      refresh.httpClientAdapter = FakeAdapter((o) {
        calls++;
        return response(200, {});
      });
      transport.httpClientAdapter = FakeAdapter((o) {
        expect(o.headers.containsKey('Authorization'), false);
        return response(401, {});
      });
      await expectLater(
        api.postPublic('/auth/login', {
          'email': 'test@example.com',
          'password': 'wrong',
        }),
        throwsA(isA<DioException>()),
      );
      expect(calls, 0);
      expect(api.session, isNotNull);
    },
  );
  test('logout during refresh prevents session resurrection', () async {
    final gate = Completer<void>(), started = Completer<void>();
    refresh.httpClientAdapter = FakeAdapter((o) async {
      started.complete();
      await gate.future;
      return response(200, {'access': 'fresh', 'refresh': 'refresh-2'});
    });
    final rotation = api.refresh();
    await started.future;
    await api.forget();
    gate.complete();
    await rotation;
    expect(store.value, isNull);
    expect(api.session, isNull);
  });
  test(
    'biometric lock keeps a rotating pair encrypted without reactivating it',
    () async {
      final gate = Completer<void>(), started = Completer<void>();
      refresh.httpClientAdapter = FakeAdapter((o) async {
        started.complete();
        await gate.future;
        return response(200, {'access': 'fresh', 'refresh': 'refresh-2'});
      });
      final rotation = api.refresh();
      await started.future;
      api.suspend();
      gate.complete();
      await rotation;
      expect(api.session, isNull);
      expect(store.value?['refresh'], 'refresh-2');
      final saved = await api.restore();
      expect(saved?['access'], 'fresh');
      expect(api.session?['refresh'], 'refresh-2');
    },
  );
  test(
    'unlock waits for rotation instead of reading a revoked old refresh token',
    () async {
      final gate = Completer<void>(), started = Completer<void>();
      refresh.httpClientAdapter = FakeAdapter((o) async {
        started.complete();
        await gate.future;
        return response(200, {'access': 'fresh', 'refresh': 'refresh-2'});
      });
      final rotation = api.refresh();
      await started.future;
      api.suspend();
      final restoring = api.restore();
      expect(api.session, isNull);
      gate.complete();
      await rotation;
      expect((await restoring)?['refresh'], 'refresh-2');
    },
  );
  test(
    'locking during a secure profile write does not reactivate credentials',
    () async {
      final gate = Completer<void>(), started = Completer<void>();
      store.beforeWrite = () async {
        started.complete();
        await gate.future;
      };
      final writing = api.accept({
        ...original,
        'user': {'email': 'test@example.com'},
      });
      await started.future;
      api.suspend();
      gate.complete();
      await writing;
      expect(api.session, isNull);
      expect(store.value?['refresh'], 'refresh-1');
    },
  );
  test(
    'a new account does not reuse an older account refresh in flight',
    () async {
      final oldGate = Completer<void>(), newGate = Completer<void>();
      final oldStarted = Completer<void>(), newStarted = Completer<void>();
      var calls = 0;
      refresh.httpClientAdapter = FakeAdapter((o) async {
        calls++;
        if ((o.data as Map)['refresh'] == 'refresh-1') {
          oldStarted.complete();
          await oldGate.future;
          return response(200, {
            'access': 'old-fresh',
            'refresh': 'old-rotated',
          });
        }
        newStarted.complete();
        await newGate.future;
        return response(200, {'access': 'new-fresh', 'refresh': 'new-rotated'});
      });
      final oldRotation = api.refresh();
      await oldStarted.future;
      await api.accept({'access': 'new', 'refresh': 'new-refresh'});
      final newRotation = api.refresh();
      await newStarted.future;
      oldGate.complete();
      await oldRotation;
      final sharedNewRotation = api.refresh();
      expect(calls, 2);
      newGate.complete();
      await Future.wait([newRotation, sharedNewRotation]);
      expect(store.value?['refresh'], 'new-rotated');
    },
  );
  test(
    'logout waits behind an in-flight secure write and clears it last',
    () async {
      final gate = Completer<void>(), started = Completer<void>();
      store.beforeWrite = () async {
        started.complete();
        await gate.future;
      };
      final accepting = api.accept({'access': 'new', 'refresh': 'new-refresh'});
      await started.future;
      final logout = api.forget();
      gate.complete();
      await Future.wait([accepting, logout]);
      expect(store.value, isNull);
      expect(api.session, isNull);
    },
  );
  test('all pages are read without dropping favorites or playlists', () async {
    transport.httpClientAdapter = FakeAdapter((o) {
      final page = o.queryParameters['page'];
      return response(200, {
        'results': [
          {'id': page, 'name': 'list $page', 'track_count': 0},
        ],
        'count': 2,
        'next': page == 1
            ? 'https://soundify.easyfound.ir/api/v1/playlists?page=2'
            : null,
      });
    });
    final values = await api.all('/playlists', MusicPlaylist.fromJson);
    expect(values.map((p) => p.id), [1, 2]);
  });
}
