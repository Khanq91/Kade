// Cảnh báo một lần trên web (plan §4.4, bước 14): hiện khi là web và chưa
// tắt; "Đã hiểu" → ẩn và không hiện lại (cờ trong box settings); "Bật đồng
// bộ" → sang Cài đặt; không phải web → không hiện.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/settings_provider.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('web: banner → Đã hiểu → ẩn, mở lại không hiện', (tester) async {
    final box = await memorySettingsBox();
    await tester.pumpWidget(
      await testApp('/2027/02', settingsBox: box, isWeb: true),
    );
    await tester.pumpAndSettle();
    expect(key('web-notice'), findsOneWidget);
    expect(find.text(Strings.webStorageNotice), findsOneWidget);

    await tester.tap(key('web-notice-ok'));
    await tester.pumpAndSettle();
    expect(key('web-notice'), findsNothing);
    expect(box.get(WebNoticeNotifier.key), isTrue);

    await tester.pumpWidget(
      await testApp('/2027/02', settingsBox: box, isWeb: true),
    );
    await tester.pumpAndSettle();
    expect(key('web-notice'), findsNothing);
  });

  testWidgets('web: Bật đồng bộ → Cài đặt, banner tắt luôn', (tester) async {
    final box = await memorySettingsBox();
    await tester.pumpWidget(
      await testApp('/2027/02', settingsBox: box, isWeb: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(key('web-notice-sync'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.syncSection), findsOneWidget);
    expect(box.get(WebNoticeNotifier.key), isTrue);
  });

  testWidgets('không phải web → không có banner', (tester) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();
    expect(key('web-notice'), findsNothing);
  });
}
