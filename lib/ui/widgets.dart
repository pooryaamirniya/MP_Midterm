import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../state/app_controller.dart';
import '../state/player_controller.dart';
import 'theme.dart';

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) toast(context, success);
    return true;
  } catch (e) {
    if (context.mounted) toast(context, errorText(e));
    return false;
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class Brand extends StatelessWidget {
  final double size;
  final bool label;
  const Brand({super.key, this.size = 38, this.label = true});
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: lime,
              borderRadius: BorderRadius.circular(size * .32),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [0.28, .55, .76, .42]
                    .map(
                      (h) => Container(
                        width: size * .10,
                        height: size * h,
                        margin: EdgeInsets.symmetric(horizontal: size * .035),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (label) ...[
            const SizedBox(width: 10),
            Text(
              'soundify',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                fontSize: size * .68,
                letterSpacing: -1.3,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class Cover extends StatelessWidget {
  final String url;
  final double size, radius;
  const Cover(this.url, {super.key, this.size = 56, this.radius = 14});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const ColoredBox(
                color: Color(0xFF2B3931),
                child: Center(child: Icon(Icons.album_outlined, color: muted)),
              ),
        errorBuilder: (_, e, s) => const ColoredBox(
          color: Color(0xFF2B3931),
          child: Center(
            child: Icon(Icons.music_note_rounded, color: lime, size: 32),
          ),
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const SectionTitle(
    this.title, {
    super.key,
    this.subtitle = '',
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class StateView extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback? retry;
  final String action;
  const StateView({
    super.key,
    required this.title,
    this.message = '',
    this.icon = Icons.wifi_off_rounded,
    this.retry,
    this.action = 'تلاش دوباره',
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lime.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: lime),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
            ),
          if (retry != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: Text(action),
              ),
            ),
        ],
      ),
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: lime),
    ),
  );
}

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;
  final VoidCallback? onMore;
  const TrackTile(this.track, {super.key, required this.onPlay, this.onMore});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final current = context.watch<PlayerController>().current?.id == track.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: current ? lime.withValues(alpha: .07) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                Cover(track.coverUrl),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: current ? lime : paper,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist} · ${track.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  clockText(Duration(seconds: track.duration)),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
                IconButton(
                  tooltip: app.favoriteIds.contains(track.id)
                      ? 'حذف از علاقه‌مندی‌ها'
                      : 'افزودن به علاقه‌مندی‌ها',
                  visualDensity: VisualDensity.compact,
                  onPressed: app.favoriteBusy.contains(track.id)
                      ? null
                      : () =>
                            runAction(context, () => app.toggleFavorite(track)),
                  icon: Icon(
                    app.favoriteIds.contains(track.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 21,
                    color: app.favoriteIds.contains(track.id) ? lime : muted,
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    tooltip: 'گزینه‌های آهنگ',
                    visualDensity: VisualDensity.compact,
                    onPressed: onMore,
                    icon: const Icon(Icons.more_vert, size: 21, color: muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative rhythm visual, driven by playback state, not microphone data.
class Rhythm extends StatefulWidget {
  final bool playing;
  final double height;
  const Rhythm({super.key, required this.playing, this.height = 22});
  @override
  State<Rhythm> createState() => _RhythmState();
}

class _RhythmState extends State<Rhythm> with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void initState() {
    super.initState();
    if (widget.playing) animation.repeat();
  }

  @override
  void didUpdateWidget(Rhythm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing) {
      animation.repeat();
    } else {
      animation.stop();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'نمایش ریتم پخش',
    child: AnimatedBuilder(
      animation: animation,
      builder: (_, child) => SizedBox(
        height: widget.height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            15,
            (i) => Container(
              width: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height:
                  widget.height *
                  (widget.playing
                      ? .2 +
                            .8 *
                                (math
                                    .sin(
                                      animation.value * math.pi * 2 + i * 1.8,
                                    )
                                    .abs())
                      : .18),
              decoration: BoxDecoration(
                color: lime.withValues(alpha: .4 + (i % 3) * .25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BusyButton extends StatelessWidget {
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  const BusyButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}
