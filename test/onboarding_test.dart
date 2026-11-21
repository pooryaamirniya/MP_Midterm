import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundify/state/app_controller.dart';
import 'package:soundify/ui/onboarding_screen.dart';
import 'package:soundify/ui/theme.dart';

void main() {
  testWidgets(
    'all intro slides fit a small RTL phone and completion persists',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final state = AppController();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: soundifyTheme(),
            builder: (_, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: const OnboardingScreen(),
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('ادامه'));
        await tester.pumpAndSettle();
      }
      expect(find.text('شروع شنیدن'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('شروع شنیدن'));
      await tester.pumpAndSettle();
      expect(state.onboarding, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getBool('onboarding.done'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
