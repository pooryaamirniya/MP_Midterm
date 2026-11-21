import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import 'theme.dart';
import 'widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pages = PageController();
  int index = 0;
  bool busy = false;
  static const titles = [
    'دنیات رو\nروی پخش بذار.',
    'موسیقی تو،\nهمیشه همراه تو.',
    'حسابت امن،\nخیالت راحت.',
  ];
  static const descriptions = [
    'آهنگ‌های تازه را کشف کن، خوانندهٔ محبوبت را پیدا کن و از شنیدن لذت ببر.',
    'پلی‌لیست خودت را بساز. حتی با صفحهٔ خاموش، موسیقی و کنترل پخش همراهت می‌مانند.',
    'ورود با ایمیل، نگهداری امن نشست و دسترسی سریع با اثر انگشت یا تشخیص چهره.',
  ];
  Future<void> finish() async {
    setState(() => busy = true);
    await runAction(context, context.read<AppController>().completeOnboarding);
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Brand(size: 34)),
                TextButton(
                  onPressed: busy ? null : finish,
                  child: const Text('رد کردن', style: TextStyle(color: muted)),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: pages,
              itemCount: 3,
              onPageChanged: (v) => setState(() => index = v),
              itemBuilder: (_, i) => LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * .04),
                      SizedBox(
                        height: math.min(280, constraints.maxHeight * .46),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CustomPaint(painter: _RecordPainter(i)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        titles[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 35,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        descriptions[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                width: i == index ? 26 : 6,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: i == index ? lime : const Color(0xFF38413D),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: SizedBox(
              width: double.infinity,
              child: BusyButton(
                busy: busy,
                label: index == 2 ? 'شروع شنیدن' : 'ادامه',
                onPressed: index == 2
                    ? finish
                    : () => pages.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecordPainter extends CustomPainter {
  final int page;
  _RecordPainter(this.page);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2),
        r = size.shortestSide * .44;
    canvas.drawCircle(
      c,
      r * 1.12,
      Paint()..color = lime.withValues(alpha: .04),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3F5441), Color(0xFF171E1A)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        c,
        r * (.35 + i * .075),
        Paint()
          ..color = lime.withValues(alpha: .1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * .86),
      -1.8,
      1.8,
      false,
      Paint()
        ..color = lime.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      c,
      r * .30,
      Paint()..color = page == 1 ? const Color(0xFFC4B5FD) : lime,
    );
    canvas.drawCircle(c, r * .07, Paint()..color = ink);
    final text = TextPainter(
      text: TextSpan(
        text: page == 2 ? '◈' : '♪',
        style: TextStyle(color: lime, fontSize: r * .5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(size.width * .78, size.height * .08));
    canvas.drawCircle(
      Offset(size.width * .12, size.height * .70),
      7,
      Paint()..color = const Color(0xFFC4B5FD),
    );
  }

  @override
  bool shouldRepaint(_RecordPainter oldDelegate) => oldDelegate.page != page;
}
