import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'state/app_controller.dart';
import 'state/player_controller.dart';
import 'ui/auth_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/player_screen.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await JustAudioBackground.init(
    androidNotificationChannelId: 'ir.soundify.soundify.audio',
    androidNotificationChannelName: 'پخش موسیقی Soundify',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_notification',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()..initialize()),
        ChangeNotifierProvider(create: (_) => PlayerController()),
      ],
      child: const SoundifyApp(),
    ),
  );
}

class SoundifyApp extends StatelessWidget {
  const SoundifyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Soundify',
    debugShowCheckedModeBanner: false,
    theme: soundifyTheme(),
    builder: (_, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const AppGate(),
  );
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});
  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  bool wasBackground = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final app = context.read<AppController>();
    if (state == AppLifecycleState.paused) {
      wasBackground = true;
      app.lockForBackground();
    } else if (state == AppLifecycleState.resumed && wasBackground) {
      wasBackground = false;
      app.lockForBackground();
      if (app.locked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    if (app.booting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Brand(size: 64),
              SizedBox(height: 32),
              CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      );
    }
    if (app.startupError != null) {
      return Scaffold(
        body: StateView(
          title: 'راه‌اندازی انجام نشد',
          message: app.startupError!,
          retry: app.initialize,
        ),
      );
    }
    if (app.onboarding) return const OnboardingScreen();
    if (app.locked) return const BiometricScreen();
    return const AppShell();
  }
}

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});
  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Brand(size: 52)),
            const SizedBox(height: 56),
            const Icon(Icons.fingerprint_rounded, color: lime, size: 88),
            const SizedBox(height: 24),
            const Text(
              'خوش برگشتی',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای دسترسی به حسابت، هویتت را تأیید کن',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 32),
            BusyButton(
              busy: busy,
              label: 'ورود با اثر انگشت / چهره',
              onPressed: () async {
                setState(() => busy = true);
                await runAction(context, context.read<AppController>().unlock);
                if (mounted) setState(() => busy = false);
              },
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      await context.read<AppController>().passwordInstead();
                      if (context.mounted) unawaited(showAuth(context));
                    },
              child: const Text('ورود با ایمیل و رمز عبور'),
            ),
          ],
        ),
      ),
    ),
  );
}
