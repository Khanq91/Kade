import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/core/effects/particle_field.dart';
import 'package:kade/features/settings/theme_screen.dart';
import 'package:kade/features/shell/snap_rail_navigation_bar.dart';

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

    expect(box.containsKey('graphicsMode'), isFalse);
    await tester.tap(find.text(Strings.graphicsFancy));
    // ParticleField chạy liên tục nên không dùng pumpAndSettle ở chế độ này.
    await tester.pump();
    expect(box.get('graphicsMode'), 'fancy');
    expect(find.byType(ParticleField), findsOneWidget);
    expect(
      tester
          .widget<SnapRailNavigationBar>(find.byType(SnapRailNavigationBar))
          .liquidGlass,
      isTrue,
    );

    await tester.tap(find.text(Strings.graphicsNormal));
    await tester.pumpAndSettle();
    expect(box.get('graphicsMode'), 'normal');
    expect(find.byType(ParticleField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
