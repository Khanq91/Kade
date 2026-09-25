import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/features/settings/theme_screen.dart';

import 'test_app.dart';

void main() {
  testWidgets('Cài đặt → Giao diện: chọn palette và chế độ lưu vào settings', (
    tester,
  ) async {
    setViewport(tester, const Size(360, 760));
    final box = await memorySettingsBox();
    await tester.pumpWidget(
      await testApp('/settings', settingsBox: box, isWeb: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Strings.themeTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-hong')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-kem')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-mint')));
    await tester.pumpAndSettle();
    expect(box.get('themeId'), 'mint');

    await tester.tap(find.text(Strings.themeDark));
    await tester.pumpAndSettle();
    expect(box.get('darkMode'), isTrue);
    expect(
      Theme.of(tester.element(find.byType(ThemeScreen))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text(Strings.themeSystem));
    await tester.pumpAndSettle();
    expect(box.containsKey('darkMode'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
