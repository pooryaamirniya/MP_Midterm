import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/api_client.dart';
import 'package:soundify/core/models.dart';
import 'package:soundify/state/app_controller.dart';

import 'support/fakes.dart';

const a = Track(
  id: 'a',
  title: 'A',
  artist: 'Artist',
  album: 'Album',
  coverUrl: '',
  streamUrl: 'https://example.com/a.mp3',
  duration: 60,
);
const b = Track(
  id: 'b',
  title: 'B',
  artist: 'Artist',
  album: 'Album',
  coverUrl: '',
  streamUrl: 'https://example.com/b.mp3',
  duration: 90,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController app;
  late Dio transport;
  setUp(() {
    final store = MemoryStore();
    transport = Dio();
    final api = ApiClient(store, transport: transport);
    app = AppController(client: api, sessionStore: store);
    app.user = const UserProfile(
      email: 'test@example.com',
      username: 'test',
      displayName: 'Test',
    );
  });
  test('background biometric lock removes active credentials but preserves encrypted session', () async {
    final saved = {
      'access': 'access',
      'refresh': 'refresh',
      'user': app.user!.toJson(),
    };
    await app.api.accept(saved);
    app.biometric = true;
    app.lockForBackground();
    expect(app.locked, isTrue);
    expect(app.signedIn, isFalse);
    expect(app.api.session, isNull);
    expect((await app.store.read())?['refresh'], 'refresh');
  });
  test('a failed like rolls back only its track, preserving a parallel successful like', () async {
    final gate = Completer<void>();
    transport.httpClientAdapter = FakeAdapter((o) async {
      if ((o.data as Map)['track_id'] == 'a') {
        await gate.future;
        return response(503, {});
      }
      return response(201, {});
    });
    final failed = app.toggleFavorite(a);
    final checked = expectLater(failed, throwsA(isA<DioException>()));
    await app.toggleFavorite(b);
    gate.complete();
    await checked;
    expect(app.favoriteIds, {'b'});
    expect(app.favorites.map((t) => t.id), ['b']);
    expect(app.favoriteBusy, isEmpty);
  });
  test(
    'late library snapshots never undo a completed optimistic mutation',
    () async {
      final gate = Completer<void>();
      transport.httpClientAdapter = FakeAdapter((o) async {
        if (o.method == 'GET' && o.path == '/favorites') {
          await gate.future;
          return response(200, {'results': [], 'count': 0, 'next': null});
        }
        if (o.method == 'GET') {
          return response(200, {'results': [], 'count': 0, 'next': null});
        }
        return response(201, {});
      });
      final loading = app.loadLibrary();
      await Future<void>.delayed(Duration.zero);
      await app.toggleFavorite(a);
      gate.complete();
      await loading;
      expect(app.favoriteIds, {'a'});
      expect(app.favorites.single.id, 'a');
    },
  );
  test('double tapping one favorite never sends two mutations', () async {
    final gate = Completer<void>();
    var calls = 0;
    transport.httpClientAdapter = FakeAdapter((o) async {
      calls++;
      await gate.future;
      return response(201, {});
    });
    final first = app.toggleFavorite(a);
    await app.toggleFavorite(a);
    gate.complete();
    await first;
    expect(calls, 1);
    expect(app.favoriteIds, {'a'});
  });
  test(
    'an old account favorite failure cannot change a newer account library',
    () async {
      final gate = Completer<void>();
      transport.httpClientAdapter = FakeAdapter((o) async {
        if (o.method == 'GET') {
          return response(200, {'results': [], 'count': 0, 'next': null});
        }
        if ((o.data as Map)['track_id'] == 'a') {
          await gate.future;
          return response(503, {});
        }
        return response(201, {});
      });
      final oldLike = app.toggleFavorite(a);
      final checked = expectLater(oldLike, throwsA(isA<DioException>()));
      await app.acceptLogin({
        'access': 'new',
        'refresh': 'new-refresh',
        'user': {
          'email': 'other@example.com',
          'username': 'other',
          'display_name': 'Other',
        },
      });
      await Future.wait([app.loadHome(), app.loadLibrary()]);
      await app.toggleFavorite(b);
      gate.complete();
      await checked;
      expect(app.favoriteIds, {'b'});
      expect(app.favorites.map((t) => t.id), ['b']);
    },
  );
  test('an OTP token pair can load its profile from users/me', () async {
    transport.httpClientAdapter = FakeAdapter(
      (o) => o.path == '/users/me'
          ? response(200, {
              'email': 'otp@example.com',
              'username': 'otp',
              'display_name': 'OTP',
            })
          : response(200, {'results': [], 'count': 0, 'next': null}),
    );
    await app.acceptLogin({'access': 'otp-access', 'refresh': 'otp-refresh'});
    await Future.wait([app.loadHome(), app.loadLibrary()]);
    expect(app.user?.email, 'otp@example.com');
    expect((await app.store.read())?['user']?['username'], 'otp');
  });
}
