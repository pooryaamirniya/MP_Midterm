import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:soundify/core/models.dart';
import 'package:soundify/main.dart';
import 'package:soundify/state/app_controller.dart';
import 'package:soundify/state/player_controller.dart';
import 'package:soundify/ui/theme.dart';

class _PlayingAudio extends Fake implements AudioPlayer {
  @override
  Stream<PlayerState> get playerStateStream =>
      Stream.value(PlayerState(true, ProcessingState.ready));
  @override
  Stream<int?> get currentIndexStream => Stream.value(0);
  @override
  Stream<bool> get shuffleModeEnabledStream => Stream.value(false);
  @override
  Stream<LoopMode> get loopModeStream => Stream.value(LoopMode.off);
  @override
  Stream<PlayerException> get errorStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream =>
      Stream.value(const Duration(seconds: 10));
  @override
  int? get currentIndex => 0;
  @override
  Duration? get duration => const Duration(minutes: 1);
  @override
  ProcessingState get processingState => ProcessingState.ready;
  @override
  bool get playing => true;
  @override
  bool get hasNext => false;
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('ongoing music remains accessible from the biometric lock page', (
    tester,
  ) async {
    final app = AppController()..locked = true;
    final audio = PlayerController(audioPlayer: _PlayingAudio())
      ..queue = const [
        Track(
          id: 'playing',
          title: 'Current song',
          artist: 'Current artist',
          album: 'Album',
          coverUrl: 'https://example.com/cover.jpg',
          streamUrl: 'https://example.com/music.mp3',
          duration: 60,
        ),
      ];
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: audio),
        ],
        child: MaterialApp(
          theme: soundifyTheme(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const BiometricScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('خوش برگشتی'), findsOneWidget);
    expect(find.text('Current song'), findsOneWidget);
    expect(find.byTooltip('توقف پخش'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
