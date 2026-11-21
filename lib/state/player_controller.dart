import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../core/models.dart';

class PlayerController extends ChangeNotifier {
  final AudioPlayer player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<Track> queue = [];
  String? error;
  int _loadId = 0;
  int _selectedIndex = 0;
  bool loading = false;
  PlayerController({AudioPlayer? audioPlayer})
    : player =
          audioPlayer ??
          AudioPlayer(
            userAgent: 'Soundify/1.0',
            useProxyForRequestHeaders: false,
          ) {
    _subscriptions.add(
      player.playerStateStream.listen((_) => notifyListeners()),
    );
    _subscriptions.add(
      player.currentIndexStream.listen((_) => notifyListeners()),
    );
    _subscriptions.add(
      player.shuffleModeEnabledStream.listen((_) => notifyListeners()),
    );
    _subscriptions.add(player.loopModeStream.listen((_) => notifyListeners()));
    _subscriptions.add(
      player.errorStream.listen((_) {
        error = 'پخش این قطعه ممکن نیست؛ اتصال را بررسی کن یا آهنگ بعدی را امتحان کن';
        loading = false;
        notifyListeners();
      }),
    );
  }
  Track? get current {
    if (queue.isEmpty) return null;
    final index = loading
        ? _selectedIndex
        : player.currentIndex ?? _selectedIndex;
    return index >= 0 && index < queue.length ? queue[index] : null;
  }

  bool get busy =>
      loading ||
      player.processingState == ProcessingState.loading ||
      player.processingState == ProcessingState.buffering;
  bool get playing =>
      player.playing && player.processingState != ProcessingState.completed;

  Future<void> play(List<Track> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    final id = ++_loadId;
    error = null;
    loading = true;
    notifyListeners();
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      if (id != _loadId) return;
      await player.stop();
      queue = List.unmodifiable(tracks);
      _selectedIndex = index;
      notifyListeners();
      await player.setAudioSources(
        queue
            .map(
              (t) => AudioSource.uri(
                Uri.parse(t.streamUrl),
                tag: MediaItem(
                  id: t.id,
                  title: t.title,
                  artist: t.artist,
                  album: t.album,
                  duration: Duration(seconds: t.duration),
                  artUri: t.coverUrl.isEmpty ? null : Uri.tryParse(t.coverUrl),
                ),
              ),
            )
            .toList(),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      if (id != _loadId) return;
      loading = false;
      notifyListeners();
      unawaited(
        player.play().catchError((Object _) {
          error = 'پخش متوقف شد؛ دوباره تلاش کن';
          notifyListeners();
        }),
      );
    } on PlayerInterruptedException {
      // A newer selection superseded this one.
    } catch (_) {
      if (id == _loadId) {
        error = 'بارگذاری آهنگ انجام نشد؛ اینترنت را بررسی و دوباره تلاش کن';
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggle() async {
    if (current == null) return;
    try {
      if (error != null) {
        await play(queue, player.currentIndex ?? 0);
        return;
      }
      if (playing) {
        await player.pause();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero, index: 0);
        }
        unawaited(
          player.play().catchError((Object _) {
            error = 'پخش انجام نشد؛ دوباره تلاش کن';
            notifyListeners();
          }),
        );
      }
    } catch (_) {
      error = 'کنترل پخش انجام نشد';
      notifyListeners();
    }
  }

  Future<void> next() => _control(() => player.seekToNext());
  Future<void> previous() => _control(() async {
    if (player.position.inSeconds > 3) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
  });
  Future<void> seek(Duration value) => _control(() => player.seek(value));
  Future<void> selectQueueIndex(int index) =>
      _control(() => player.seek(Duration.zero, index: index));
  Future<void> shuffle() =>
      _control(() => player.setShuffleModeEnabled(!player.shuffleModeEnabled));
  Future<void> repeat() => _control(
    () => player.setLoopMode(
      player.loopMode == LoopMode.off
          ? LoopMode.all
          : player.loopMode == LoopMode.all
          ? LoopMode.one
          : LoopMode.off,
    ),
  );
  Future<void> _control(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      error = 'کنترل پخش انجام نشد؛ دوباره تلاش کن';
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _loadId++;
    await player.stop();
    queue = [];
    error = null;
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(player.dispose());
    super.dispose();
  }
}
