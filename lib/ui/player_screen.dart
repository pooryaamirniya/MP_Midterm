import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state/app_controller.dart';
import '../state/player_controller.dart';
import 'playlist_actions.dart';
import 'theme.dart';
import 'widgets.dart';

void openPlayer(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<PlayerController>(), t = audio.current;
    if (t == null) return const SizedBox.shrink();
    return Semantics(
      label: 'مینی پلیر',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Material(
          color: const Color(0xFF2B3930),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openPlayer(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
                  child: Row(
                    children: [
                      Cover(t.coverUrl, size: 44, radius: 12),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              audio.error != null
                                  ? 'خطای پخش؛ برای تلاش مجدد لمس کن'
                                  : t.artist,
                              textDirection: audio.error == null
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: audio.error != null
                                    ? const Color(0xFFFFB1B1)
                                    : muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: audio.playing ? 'توقف پخش' : 'پخش',
                        onPressed: audio.toggle,
                        icon: audio.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                audio.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: lime,
                                size: 30,
                              ),
                      ),
                      IconButton(
                        tooltip: 'آهنگ بعدی',
                        onPressed: audio.player.hasNext ? audio.next : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<Duration>(
                  stream: audio.player.positionStream,
                  builder: (_, s) {
                    final duration =
                        audio.player.duration ?? Duration(seconds: t.duration);
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: LinearProgressIndicator(
                        value: duration.inMilliseconds == 0
                            ? 0
                            : ((s.data ?? Duration.zero).inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0, 1),
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: lime,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<PlayerController>(),
        app = context.watch<AppController>(),
        t = audio.current;
    return Scaffold(
      backgroundColor: const Color(0xFF17221B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'کوچک کردن پلیر',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        title: const Column(
          children: [
            Text('در حال پخش', style: TextStyle(fontSize: 13)),
            Text(
              'S O U N D I F Y',
              style: TextStyle(fontSize: 9, color: muted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (t != null)
            IconButton(
              tooltip: 'گزینه‌های آهنگ',
              onPressed: () => showTrackActions(context, t),
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
      body: t == null
          ? const StateView(
              title: 'یک آهنگ انتخاب کن',
              icon: Icons.music_note_rounded,
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .35),
                                  blurRadius: 35,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Cover(
                              t.coverUrl,
                              size: (constraints.maxHeight * .43).clamp(
                                160,
                                340,
                              ),
                              radius: 26,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      textDirection: TextDirection.ltr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t.artist,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (t.album.isNotEmpty)
                                      Text(
                                        t.album,
                                        textDirection: TextDirection.ltr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'علاقه‌مندی',
                                onPressed: app.favoriteBusy.contains(t.id)
                                    ? null
                                    : () => runAction(
                                        context,
                                        () => app.toggleFavorite(t),
                                      ),
                                icon: Icon(
                                  app.favoriteIds.contains(t.id)
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: app.favoriteIds.contains(t.id)
                                      ? lime
                                      : paper,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (audio.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Text(
                                    audio.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB1B1),
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: audio.toggle,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('تلاش دوباره'),
                                  ),
                                ],
                              ),
                            ),
                          _SeekBar(audio),
                          const SizedBox(height: 10),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'پخش تصادفی',
                                  onPressed: audio.shuffle,
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: audio.player.shuffleModeEnabled
                                        ? lime
                                        : muted,
                                    size: 23,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'آهنگ قبلی',
                                  onPressed: audio.previous,
                                  icon: const Icon(
                                    Icons.skip_previous_rounded,
                                    size: 38,
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: const CircleBorder(),
                                    ),
                                    onPressed: audio.busy ? null : audio.toggle,
                                    child: audio.busy
                                        ? const SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            audio.playing
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 42,
                                          ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'آهنگ بعدی',
                                  onPressed: audio.player.hasNext
                                      ? audio.next
                                      : null,
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    size: 38,
                                  ),
                                ),
                                IconButton(
                                  tooltip: switch (audio.player.loopMode) {
                                    LoopMode.off => 'تکرار خاموش',
                                    LoopMode.all => 'تکرار همه',
                                    LoopMode.one => 'تکرار تک آهنگ',
                                  },
                                  onPressed: audio.repeat,
                                  icon: Icon(
                                    audio.player.loopMode == LoopMode.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: audio.player.loopMode == LoopMode.off
                                        ? muted
                                        : lime,
                                    size: 23,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Rhythm(
                            playing: audio.playing && !audio.busy,
                            height: 24,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _queue(context, audio),
                                icon: const Icon(
                                  Icons.queue_music_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  'صف پخش · ${audio.queue.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                tooltip: 'افزودن به پلی‌لیست',
                                onPressed: () => addToPlaylist(context, t),
                                icon: const Icon(
                                  Icons.playlist_add_rounded,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _queue(BuildContext context, PlayerController audio) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(c).height * .65,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'صف پخش',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: audio.queue.length,
                    itemBuilder: (_, i) => TrackTile(
                      audio.queue[i],
                      onPlay: () {
                        audio.selectQueueIndex(i);
                        Navigator.pop(c);
                      },
                      onMore: () => showTrackActions(c, audio.queue[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SeekBar extends StatefulWidget {
  final PlayerController audio;
  const _SeekBar(this.audio);
  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? dragging;
  @override
  Widget build(BuildContext context) => StreamBuilder<Duration?>(
    stream: widget.audio.player.durationStream,
    builder: (_, d) => StreamBuilder<Duration>(
      stream: widget.audio.player.positionStream,
      builder: (_, p) {
        final total =
            d.data ?? Duration(seconds: widget.audio.current?.duration ?? 0);
        final max = total.inMilliseconds.toDouble();
        final value =
            dragging ?? (p.data ?? Duration.zero).inMilliseconds.toDouble();
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: max <= 0 ? 1 : max,
                  value: value.clamp(0, max <= 0 ? 1 : max),
                  semanticFormatterCallback: (v) =>
                      clockText(Duration(milliseconds: v.round())),
                  onChanged: max <= 0
                      ? null
                      : (v) => setState(() => dragging = v),
                  onChangeEnd: max <= 0
                      ? null
                      : (v) async {
                          await widget.audio.seek(
                            Duration(milliseconds: v.round()),
                          );
                          if (mounted) setState(() => dragging = null);
                        },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      clockText(Duration(milliseconds: value.round())),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    Text(
                      clockText(total),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
