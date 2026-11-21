import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../state/app_controller.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'player_screen.dart';
import 'playlist_actions.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    if (!app.signedIn) {
      return StateView(
        title: 'جای موسیقی‌های تو اینجاست',
        message: 'وارد حساب شو تا پلی‌لیست بسازی و آهنگ‌های موردعلاقه‌ات را همیشه پیدا کنی.',
        icon: Icons.library_music_outlined,
        retry: () => showAuth(context),
        action: 'ورود / ثبت‌نام',
      );
    }
    return RefreshIndicator(
      color: lime,
      onRefresh: app.loadLibrary,
      child: CustomScrollView(
        key: const PageStorageKey('library-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'کتابخانهٔ تو',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'پلی‌لیست تازه',
                        onPressed: () => editPlaylist(context),
                        icon: const Icon(Icons.add_circle_outline, color: lime),
                      ),
                    ],
                  ),
                  const Text(
                    'آهنگ‌ها و لحظه‌هایی که نگه داشتی',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.queue_music_rounded, size: 19),
                          label: Text('پلی‌لیست‌ها · ${app.playlists.length}'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: const Icon(
                            Icons.favorite_border_rounded,
                            size: 19,
                          ),
                          label: Text(
                            'علاقه‌مندی‌ها · ${app.favoriteIds.length}',
                          ),
                        ),
                      ],
                      selected: {tab},
                      onSelectionChanged: (v) => setState(() => tab = v.first),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (app.libraryLoading)
            const SliverToBoxAdapter(child: LoadingView())
          else if (app.libraryError != null)
            SliverToBoxAdapter(
              child: StateView(
                title: 'کتابخانه بارگذاری نشد',
                message: app.libraryError!,
                retry: app.loadLibrary,
              ),
            )
          else if (tab == 0) ...[
            if (app.playlists.isEmpty)
              SliverToBoxAdapter(
                child: StateView(
                  title: 'اولین پلی‌لیستت را بساز',
                  message: 'برای سفر، تمرکز یا حال خوب؛ یک مجموعهٔ مخصوص خودت.',
                  icon: Icons.queue_music_rounded,
                  retry: () => editPlaylist(context),
                  action: 'ساخت پلی‌لیست',
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList.separated(
                itemCount: app.playlists.length,
                separatorBuilder: (_, i) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = app.playlists[i];
                  return Material(
                    color: panel,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      leading: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: i.isEven
                                ? [
                                    const Color(0xFF46563B),
                                    const Color(0xFF273B32),
                                  ]
                                : [
                                    const Color(0xFF4B4061),
                                    const Color(0xFF2E2939),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.queue_music_rounded,
                          color: i.isEven ? lime : const Color(0xFFC4B5FD),
                          size: 30,
                        ),
                      ),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${p.count} آهنگ${p.description.isEmpty ? '' : ' · ${p.description}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.chevron_left_rounded,
                        textDirection: TextDirection.ltr,
                        color: muted,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistScreen(id: p.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            if (app.favorites.isEmpty)
              const SliverToBoxAdapter(
                child: StateView(
                  title: 'جای آهنگ‌های محبوبت خالی است',
                  message: 'قلب کنار هر آهنگ را لمس کن تا اینجا ذخیره شود.',
                  icon: Icons.favorite_border_rounded,
                ),
              ),
            if (app.favorites.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: FilledButton.icon(
                    onPressed: () => playSelection(context, app.favorites, 0),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('پخش علاقه‌مندی‌ها'),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.builder(
                itemCount: app.favorites.length,
                itemBuilder: (_, i) => TrackTile(
                  app.favorites[i],
                  onPlay: () => playSelection(context, app.favorites, i),
                  onMore: () => showTrackActions(context, app.favorites[i]),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class PlaylistScreen extends StatefulWidget {
  final int id;
  const PlaylistScreen({super.key, required this.id});
  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  MusicPlaylist? playlist;
  String? error;
  bool loading = true, busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final value = await context.read<AppController>().playlist(widget.id);
      if (mounted) setState(() => playlist = value);
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>(), p = playlist;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'پلی‌لیست'),
        actions: [
          if (p != null)
            PopupMenuButton<String>(
              enabled: !busy,
              tooltip: 'گزینه‌های پلی‌لیست',
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await editPlaylist(context, playlist: p);
                  if (updated != null) await load();
                }
                if (value == 'delete' && context.mounted) {
                  if (!await confirmDelete(context, p.name) ||
                      !context.mounted) {
                    return;
                  }
                  setState(() => busy = true);
                  final ok = await runAction(
                    context,
                    () => app.deletePlaylist(p.id),
                  );
                  if (context.mounted && ok) Navigator.pop(context);
                  if (mounted) setState(() => busy = false);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('ویرایش نام و توضیحات'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'حذف پلی‌لیست',
                    style: TextStyle(color: Color(0xFFFF9E9E)),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: !app.signedIn
          ? const StateView(
              title: 'ابتدا وارد حساب شو',
              icon: Icons.lock_outline,
            )
          : loading
          ? const LoadingView()
          : error != null
          ? StateView(
              title: 'پلی‌لیست بارگذاری نشد',
              message: error!,
              retry: load,
            )
          : RefreshIndicator(
              color: lime,
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(22),
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF46563B), Color(0xFF22382B)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: lime,
                        size: 75,
                      ),
                    ),
                  ),
                  SectionTitle(
                    p!.name,
                    subtitle:
                        '${p.tracks.length} آهنگ${p.description.isEmpty ? '' : ' · ${p.description}'}',
                  ),
                  if (p.tracks.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => playSelection(context, p.tracks, 0),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('پخش پلی‌لیست'),
                    ),
                  if (p.tracks.isEmpty)
                    const StateView(
                      title: 'آهنگ‌های این مجموعه را انتخاب کن',
                      message: 'از صفحهٔ خانه یا جست‌وجو، منوی سه‌نقطهٔ آهنگ و «افزودن به پلی‌لیست» را بزن.',
                      icon: Icons.playlist_add_rounded,
                    ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < p.tracks.length; i++)
                    TrackTile(
                      p.tracks[i],
                      onPlay: () => playSelection(context, p.tracks, i),
                      onMore: () => showTrackActions(
                        context,
                        p.tracks[i],
                        playlistId: p.id,
                        onRemoved: load,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
