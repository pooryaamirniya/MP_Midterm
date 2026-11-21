import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../state/app_controller.dart';
import 'home_screen.dart';
import 'playlist_actions.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final input = TextEditingController();
  Timer? debounce;
  CancelToken? cancel;
  List<Track> results = [];
  String? error;
  String query = '';
  int request = 0, page = 1, count = 0;
  bool loading = false, more = false, hasMore = false;
  @override
  void dispose() {
    input.dispose();
    debounce?.cancel();
    cancel?.cancel();
    super.dispose();
  }

  void changed(String value) {
    debounce?.cancel();
    cancel?.cancel();
    request++;
    final text = value.trim();
    setState(() {
      query = text;
      error = null;
      results = [];
      count = 0;
      hasMore = false;
      loading = text.isNotEmpty;
      more = false;
    });
    if (text.isEmpty) return;
    debounce = Timer(const Duration(milliseconds: 450), () => search());
  }

  Future<void> search({bool next = false}) async {
    if (query.isEmpty) return;
    final ticket = ++request;
    cancel?.cancel();
    cancel = CancelToken();
    setState(() {
      if (next) {
        more = true;
      } else {
        loading = true;
        error = null;
      }
    });
    try {
      final value = await context.read<AppController>().api.tracks(
        query: query,
        page: next ? page + 1 : 1,
        cancelToken: cancel,
      );
      if (!mounted || ticket != request) return;
      setState(() {
        results = next ? [...results, ...value.items] : value.items;
        page = next ? page + 1 : 1;
        count = value.count;
        hasMore = value.hasNext;
      });
    } catch (e) {
      if (mounted &&
          ticket == request &&
          (e is! DioException || !CancelToken.isCancel(e))) {
        if (next) {
          toast(context, errorText(e));
        } else {
          setState(() => error = errorText(e));
        }
      }
    } finally {
      if (mounted && ticket == request) {
        setState(() {
          loading = false;
          more = false;
        });
      }
    }
  }

  void suggestion(String text) {
    input.text = text;
    changed(text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return CustomScrollView(
      key: const PageStorageKey('search-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'چی دوست داری بشنوی؟',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نام آهنگ، خواننده یا آلبوم را جست‌وجو کن',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('search-input'),
                  controller: input,
                  onChanged: changed,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    debounce?.cancel();
                    FocusScope.of(context).unfocus();
                    search();
                  },
                  decoration: InputDecoration(
                    hintText: 'جست‌وجو در Soundify',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: input.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'پاک کردن جست‌وجو',
                            onPressed: () {
                              input.clear();
                              changed('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                if (query.isEmpty) ...[
                  const SectionTitle(
                    'از اینجا شروع کن',
                    subtitle: 'خواننده‌های محبوب',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Ebi', 'Coldplay', 'Amir Tataloo']
                        .map(
                          (a) => ActionChip(
                            avatar: const Icon(
                              Icons.north_west_rounded,
                              size: 15,
                              color: lime,
                            ),
                            label: Text(a),
                            onPressed: () => suggestion(a),
                          ),
                        )
                        .toList(),
                  ),
                  const SectionTitle(
                    'برای کشف کردن',
                    subtitle: 'از بین منتخب‌ها شروع کن',
                  ),
                ] else if (!loading && error == null)
                  SectionTitle(
                    'نتایج جست‌وجو',
                    subtitle: '$count آهنگ برای «$query»',
                  ),
              ],
            ),
          ),
        ),
        if (loading)
          const SliverToBoxAdapter(child: LoadingView())
        else if (error != null)
          SliverToBoxAdapter(
            child: StateView(
              title: 'جست‌وجو انجام نشد',
              message: error!,
              retry: () => search(),
            ),
          )
        else if (query.isNotEmpty && results.isEmpty)
          const SliverToBoxAdapter(
            child: StateView(
              title: 'هنوز پیداش نکردیم',
              message: 'نام دیگری را امتحان کن یا املای عبارت را تغییر بده.',
              icon: Icons.manage_search_rounded,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: query.isEmpty ? app.featured.length : results.length,
              itemBuilder: (_, i) {
                final list = query.isEmpty ? app.featured : results;
                return TrackTile(
                  list[i],
                  onPlay: () => playSelection(context, list, i),
                  onMore: () => showTrackActions(context, list[i]),
                );
              },
            ),
          ),
        if (hasMore && !loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: more
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : OutlinedButton(
                        onPressed: () => search(next: true),
                        child: const Text('نتایج بیشتر'),
                      ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
