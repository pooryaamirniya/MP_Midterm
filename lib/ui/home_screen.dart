import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state/app_controller.dart';
import '../state/player_controller.dart';
import 'auth_screen.dart';
import 'player_screen.dart';
import 'playlist_actions.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> playSelection(
  BuildContext context,
  List<Track> list,
  int index,
) async {
  final player = context.read<PlayerController>();
  final future = player.play(list, index);
  openPlayer(context);
  await future;
  if (context.mounted && player.error != null) toast(context, player.error!);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return RefreshIndicator(
      color: lime,
      onRefresh: () => app.loadHome(),
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Brand(size: 34),
                      if (!app.signedIn)
                        TextButton.icon(
                          onPressed: () => showAuth(context),
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('ورود'),
                        )
                      else
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: panel,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'سلام، ${app.user!.displayName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'برای حال خوبت.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'کشف کن. پلی کن. دوباره گوش بده.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  if (app.homeLoading)
                    const LoadingView()
                  else if (app.homeError != null)
                    StateView(
                      title: 'موسیقی در راه است',
                      message: app.homeError!,
                      retry: () => app.loadHome(),
                    )
                  else if (app.featured.isNotEmpty) ...[
                    _HeroCard(app.featured),
                    SectionTitle(
                      'منتخب‌های Soundify',
                      subtitle: 'یک انتخاب تازه برای امروز',
                      trailing: const Icon(
                        Icons.auto_awesome_outlined,
                        color: lime,
                        size: 22,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!app.homeLoading &&
              app.homeError == null &&
              app.featured.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 232,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: app.featured.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 15),
                  itemBuilder: (_, i) {
                    final t = app.featured[i];
                    return SizedBox(
                      width: 150,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => playSelection(context, app.featured, i),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Cover(t.coverUrl, size: 150, radius: 20),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: lime,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: ink,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              t.title,
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              t.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.album,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  clockText(Duration(seconds: t.duration)),
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (!app.homeLoading && app.homeError == null) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      'همهٔ آهنگ‌ها',
                      subtitle: '${app.totalTracks} قطعه برای شنیدن',
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final a in <String?>[
                            null,
                            'Ebi',
                            'Coldplay',
                            'Amir Tataloo',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(
                                  a == null
                                      ? 'همه'
                                      : a == 'Ebi'
                                      ? 'ابی'
                                      : a == 'Amir Tataloo'
                                      ? 'امیر تتلو'
                                      : a,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: app.artist == a,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    app.loadHome(filter: a, changeFilter: true),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (app.tracks.isEmpty)
              const SliverToBoxAdapter(
                child: StateView(
                  title: 'آهنگی پیدا نشد',
                  icon: Icons.music_off_rounded,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: app.tracks.length,
                itemBuilder: (_, i) => TrackTile(
                  app.tracks[i],
                  onPlay: () => playSelection(context, app.tracks, i),
                  onMore: () => showTrackActions(context, app.tracks[i]),
                ),
              ),
            ),
            if (app.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: app.moreLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : OutlinedButton.icon(
                            onPressed: () => runAction(context, app.loadMore),
                            icon: const Icon(Icons.expand_more),
                            label: const Text('آهنگ‌های بیشتر'),
                          ),
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final List<Track> featured;
  const _HeroCard(this.featured);
  @override
  Widget build(BuildContext context) {
    final index = featured.indexWhere((t) => t.artist == 'Coldplay');
    final selected = index < 0 ? 0 : index;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF354C33), Color(0xFF202C25)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF45573D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'انتخاب امروز',
                    style: TextStyle(color: lime, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'یک مکث،\nیک آهنگ خوب.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(50, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => playSelection(context, featured, selected),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('بشنو', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: -.10,
            child: Cover(
              featured[selected].coverUrl,
              size: (MediaQuery.sizeOf(context).width * .31).clamp(90, 140),
              radius: 20,
            ),
          ),
        ],
      ),
    );
  }
}
