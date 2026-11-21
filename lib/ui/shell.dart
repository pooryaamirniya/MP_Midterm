import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'player_screen.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    if (app.notice != null) {
      final notice = app.notice!;
      app.notice = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) toast(context, notice);
      });
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            height: 68,
            selectedIndex: index,
            onDestinationSelected: (v) {
              setState(() => index = v);
              if (v == 2 && app.signedIn) app.loadLibrary();
              if (v == 3) app.checkSecurity();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'خانه',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'جست‌وجو',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'کتابخانه',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'پروفایل',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
