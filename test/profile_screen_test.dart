import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:soundify/state/app_controller.dart';
import 'package:soundify/ui/profile_screen.dart';
import 'package:soundify/ui/theme.dart';

void main() {
  testWidgets('security settings use a Material surface for ListTile ink', (
    tester,
  ) async {
    final state = AppController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: soundifyTheme(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ورود بیومتریک'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
