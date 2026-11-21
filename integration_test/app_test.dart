import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundify/main.dart' as app;
import 'package:soundify/state/app_controller.dart';
import 'package:soundify/state/player_controller.dart';
import 'package:soundify/ui/auth_screen.dart';
import 'package:soundify/ui/player_screen.dart';
import 'package:soundify/ui/widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real-device catalog, login, library, search and audio smoke', (
    tester,
  ) async {
    Future<void> until(bool Function() condition, {int seconds = 45}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!condition() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        condition(),
        isTrue,
        reason: 'Timed out waiting for expected app state',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }

    unawaited(app.main());
    await tester.pump(const Duration(seconds: 2));
    await until(() => find.byType(app.AppGate).evaluate().isNotEmpty);
    final context = tester.element(find.byType(app.AppGate));
    final state = context.read<AppController>();
    final audio = context.read<PlayerController>();
    await until(() => !state.booting);
    if (state.onboarding) {
      await tester.tap(find.text('رد کردن'));
      await until(() => !state.onboarding);
    }
    if (state.locked) {
      debugPrint('WAIT: biometric confirmation on the device');
      await tester.tap(find.text('ورود با اثر انگشت / چهره'));
      await until(() => !state.locked, seconds: 120);
    }
    await until(() => !state.homeLoading && state.tracks.isNotEmpty);
    debugPrint('PASS: device startup, onboarding and live catalog');
    expect(state.homeError, isNull);
    expect(state.featured, isNotEmpty);
    const email = String.fromEnvironment('TEST_EMAIL');
    const password = String.fromEnvironment('TEST_PASSWORD');
    if (!state.signedIn && email.isNotEmpty) {
      await tester.tap(find.text('ورود').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byKey(const ValueKey('email')), email);
      await tester.enterText(find.byKey(const ValueKey('password')), password);
      await tester.ensureVisible(find.text('ورود به Soundify'));
      await tester.tap(find.text('ورود به Soundify'));
      await until(
        () => state.signedIn && find.byType(AuthScreen).evaluate().isEmpty,
      );
    }
    if (state.signedIn || email.isNotEmpty) {
      expect(state.signedIn, isTrue);
      await until(() => !state.libraryLoading);
      debugPrint('PASS: UI login and initial library');
      expect(state.libraryError, isNull);
      // Confirm a protected endpoint and the real encrypted storage round-trip.
      await state.refreshProfile();
      expect((await state.store.read())?['refresh'], isNotNull);
      debugPrint('PASS: secure storage, profile and library reads');
      if (const bool.fromEnvironment('TEST_MUTATIONS')) {
        final track = state.featured.firstWhere(
          (t) => t.artist == 'Coldplay',
          orElse: () => state.featured.first,
        );
        final before = state.favoriteIds.contains(track.id);
        final playlist = await state.savePlaylist(
          'Soundify validation',
          'Temporary validation playlist',
        );
        try {
          await state.savePlaylist(
            'Soundify validated',
            'Updated description',
            id: playlist.id,
          );
          await state.addTrack(playlist.id, track);
          final details = await state.playlist(playlist.id);
          expect(details.name, 'Soundify validated');
          expect(details.description, 'Updated description');
          expect(details.tracks.single.id, track.id);
          await state.removeTrack(playlist.id, track.id);
          expect((await state.playlist(playlist.id)).tracks, isEmpty);
          await state.toggleFavorite(track);
          await state.loadLibrary();
          expect(state.favoriteIds.contains(track.id), !before);
          await state.toggleFavorite(track);
          await state.loadLibrary();
          expect(state.favoriteIds.contains(track.id), before);
        } finally {
          await state.loadLibrary();
          if (state.favoriteIds.contains(track.id) != before) {
            await state.toggleFavorite(track);
          }
          await state.deletePlaylist(playlist.id);
        }
        debugPrint(
          'PASS: live playlist CRUD, track membership and favorite synchronization',
        );
      }
    }
    await tester.tap(find.text('جست‌وجو').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('search-input')),
      'Coldplay',
    );
    await tester.pump(const Duration(seconds: 1));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await until(
      () => find.byType(TrackTile).hitTestable().evaluate().isNotEmpty,
    );
    await tester.tap(find.byType(TrackTile).hitTestable().first);
    await tester.pump(const Duration(seconds: 1));
    await until(
      () =>
          audio.current != null &&
          audio.player.processingState == ProcessingState.ready,
      seconds: 75,
    );
    await until(() => audio.player.position.inMilliseconds > 1500, seconds: 20);
    expect(find.byType(PlayerScreen), findsOneWidget);
    await audio.seek(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(audio.player.position.inSeconds, greaterThanOrEqualTo(29));
    await audio.toggle();
    expect(audio.playing, isFalse);
    await audio.toggle();
    await until(() => audio.playing);
    final first = audio.current!.id;
    if (audio.player.hasNext) {
      await audio.next();
      await until(() => audio.current!.id != first);
    }
    await audio.previous();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('کوچک کردن پلیر'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MiniPlayer).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await audio.player.pause();
  }, timeout: const Timeout(Duration(minutes: 8)));
}
