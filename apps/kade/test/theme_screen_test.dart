import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/core/effects/particle_field.dart';
import 'package:kade/features/settings/theme_screen.dart';
import 'package:kade/features/shell/snap_rail_navigation_bar.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
    expect(find.byType(GlassScaffold), findsOneWidget);
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(SnapRailNavigationBar), findsNothing);
    final glassScaffold = tester.widget<GlassScaffold>(
      find.byType(GlassScaffold),
    );
    final glassBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
    expect(glassScaffold.extendBody, isTrue);
    expect(glassScaffold.backgroundColor, Colors.transparent);
    expect(glassScaffold.bottomBar, same(glassBar));
    expect(glassBar.quality, GlassQuality.premium);
    expect(glassBar.backgroundQuality, GlassQuality.premium);
    expect(glassBar.textStyle?.decoration, TextDecoration.none);
    expect(
      tester.widget<Text>(find.text(Strings.navCalendar)).style?.decoration,
      TextDecoration.none,
    );
    expect(glassBar.tabs, hasLength(4));
    expect(glassBar.selectedIndex, 3);

    await tester.tap(find.text(Strings.graphicsNormal));
    await tester.pumpAndSettle();
    expect(box.get('graphicsMode'), 'normal');
    expect(find.byType(ParticleField), findsNothing);
    expect(find.byType(GlassTabBar), findsNothing);
    expect(find.byType(SnapRailNavigationBar), findsOneWidget);
    final normalScaffold = tester.widget<GlassScaffold>(
      find.byType(GlassScaffold),
    );
    expect(normalScaffold.extendBody, isTrue);
    expect(normalScaffold.backgroundColor, isNot(Colors.transparent));
    expect(normalScaffold.bottomEdgeFade, isFalse);
    expect(normalScaffold.bottomBar, isA<SnapRailNavigationBar>());
    expect(tester.takeException(), isNull);
  });
}
