import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state/app_controller.dart';
import 'auth_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<MusicPlaylist?> editPlaylist(
  BuildContext context, {
  MusicPlaylist? playlist,
}) => showDialog<MusicPlaylist>(
  context: context,
  builder: (_) => _PlaylistEditor(playlist: playlist),
);

class _PlaylistEditor extends StatefulWidget {
  final MusicPlaylist? playlist;
  const _PlaylistEditor({this.playlist});
  @override
  State<_PlaylistEditor> createState() => _PlaylistEditorState();
}

class _PlaylistEditorState extends State<_PlaylistEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.playlist?.name);
  late final description = TextEditingController(
    text: widget.playlist?.description,
  );
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(
        widget.playlist == null ? 'پلی‌لیست تازه' : 'ویرایش پلی‌لیست',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                enabled: !busy,
                maxLength: 100,
                autofocus: true,
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'نام پلی‌لیست را وارد کن'
                    : null,
                decoration: const InputDecoration(labelText: 'نام پلی‌لیست'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                enabled: !busy,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'توضیحات (اختیاری)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        BusyButton(
          busy: busy,
          label: 'ذخیره',
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            setState(() => busy = true);
            await runAction(context, () async {
              final result = await context.read<AppController>().savePlaylist(
                name.text.trim(),
                description.text.trim(),
                id: widget.playlist?.id,
              );
              if (context.mounted) Navigator.pop(context, result);
            });
            if (mounted) setState(() => busy = false);
          },
        ),
      ],
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف پلی‌لیست؟'),
        content: Text('پلی‌لیست «$name» و فهرست آهنگ‌های آن حذف می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'حذف',
              style: TextStyle(color: Color(0xFFFF9E9E)),
            ),
          ),
        ],
      ),
    ) ??
    false;

Future<void> addToPlaylist(BuildContext context, Track track) async {
  final app = context.read<AppController>();
  if (!app.signedIn) {
    await showAuth(context);
    if (!context.mounted || !app.signedIn) return;
  }
  await app.loadLibrary();
  if (!context.mounted) return;
  if (app.libraryError != null) {
    toast(context, app.libraryError!);
    return;
  }
  final id = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(c).height * .7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'افزودن به پلی‌لیست',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...app.playlists.map(
                    (p) => ListTile(
                      leading: const Icon(
                        Icons.queue_music_rounded,
                        color: lime,
                      ),
                      title: Text(p.name),
                      subtitle: Text('${p.count} آهنگ'),
                      onTap: () => Navigator.pop(c, p.id),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: lime),
                    title: const Text('ساخت پلی‌لیست تازه'),
                    onTap: () async {
                      final p = await editPlaylist(c);
                      if (p != null && c.mounted) Navigator.pop(c, p.id);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  if (id != null && context.mounted) {
    await runAction(
      context,
      () => app.addTrack(id, track),
      success: 'آهنگ به پلی‌لیست اضافه شد',
    );
  }
}

Future<void> showTrackActions(
  BuildContext context,
  Track track, {
  int? playlistId,
  Future<void> Function()? onRemoved,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Cover(track.coverUrl, size: 48),
            title: Text(
              track.title,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(track.artist, textDirection: TextDirection.ltr),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded, color: lime),
            title: const Text('افزودن به پلی‌لیست'),
            onTap: () => Navigator.pop(c, 'add'),
          ),
          if (playlistId != null)
            ListTile(
              leading: const Icon(
                Icons.playlist_remove_rounded,
                color: Color(0xFFFF9E9E),
              ),
              title: const Text('حذف از این پلی‌لیست'),
              onTap: () => Navigator.pop(c, 'remove'),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'add') await addToPlaylist(context, track);
  if (action == 'remove' && playlistId != null && context.mounted) {
    await runAction(context, () async {
      await context.read<AppController>().removeTrack(playlistId, track.id);
      await onRemoved?.call();
    }, success: 'آهنگ از پلی‌لیست حذف شد');
  }
}
