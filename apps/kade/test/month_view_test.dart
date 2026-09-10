import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/features/month_view/month_view_screen.dart';

import 'test_app.dart';

void main() {
  Key key(int day) => ValueKey('day-2027-02-${day.toString().padLeft(2, '0')}');
  DayTile tile(WidgetTester t, int day) =>
      t.widget<DayTile>(find.byKey(key(day)));
  Finder inTile(int day, String text) =>
      find.descendant(of: find.byKey(key(day)), matching: find.text(text));

  testWidgets('2/2027: sự kiện, ngày nghỉ, nhãn ÂL/DL, mùng 1 "1/1"', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
    expect(find.byType(DayTile), findsNWidgets(28));

    // 05/02 Giao thừa (âm) + nghỉ.
    expect(tile(tester, 5).cell.appEvents.map((e) => e.id), ['giao-thua']);
    expect(tile(tester, 5).cell.isOffDay, isTrue);
    expect(inTile(5, Strings.lunarTag), findsOneWidget);

    // 06–08/02 Tết + nghỉ; mùng 1 hiện "1/1".
    for (final d in [6, 7, 8]) {
      expect(tile(tester, d).cell.appEvents.map((e) => e.id), ['tet']);
      expect(tile(tester, d).cell.isOffDay, isTrue, reason: 'ngày $d');
      expect(inTile(d, Strings.lunarTag), findsOneWidget);
    }
    expect(inTile(6, '1/1'), findsOneWidget);
    expect(inTile(7, '2'), findsOneWidget);

    // 09/02 nghỉ bù từ overrides asset, không có sự kiện.
    expect(tile(tester, 9).cell.appEvents, isEmpty);
    expect(tile(tester, 9).cell.isOffDay, isTrue);

    // 14/02 Valentine (dương, quốc tế) không nghỉ.
    expect(tile(tester, 14).cell.appEvents.map((e) => e.id), ['valentine']);
    expect(tile(tester, 14).cell.isOffDay, isFalse);
    expect(inTile(14, Strings.solarTag), findsOneWidget);
    expect(inTile(14, Strings.lunarTag), findsNothing);

    // 20/02 Rằm tháng Giêng (âm, kỷ niệm).
    expect(tile(tester, 20).cell.appEvents.map((e) => e.id), [
      'ram-thang-gieng',
    ]);
    expect(tile(tester, 20).cell.isOffDay, isFalse);
    expect(inTile(20, Strings.lunarTag), findsOneWidget);

    // Ô nghỉ tô màu errorContainer, ô thường không.
    Color? bg(int d) {
      final c = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(key(d)),
              matching: find.byType(Container),
            )
            .first,
      );
      return (c.decoration as BoxDecoration?)?.color;
    }

    final scheme = Theme.of(tester.element(find.byKey(key(6)))).colorScheme;
    expect(bg(6), scheme.errorContainer);
    expect(bg(14), isNull);

    // Chú giải (trong phần lịch — panel Sắp tới ở ≥ 600 nằm ngoài).
    Finder inCalendar(String text) => find.descendant(
      of: find.byType(MonthCalendar),
      matching: find.text(text),
    );
    expect(inCalendar(Strings.kindHoliday), findsOneWidget);
    expect(inCalendar(Strings.kindMemorial), findsOneWidget);
    expect(inCalendar(Strings.kindInternational), findsOneWidget);
    expect(inCalendar(Strings.tagLegend), findsOneWidget);
  });

  testWidgets('◀ ▶ và Hôm nay đổi tháng qua route', (tester) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(Strings.nextMonth));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(3, 2027)), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.prevMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Strings.prevMonth));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(1, 2027)), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.prevMonth));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(12, 2026)), findsOneWidget);

    await tester.tap(find.text(Strings.today));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(find.text(Strings.monthTitle(now.month, now.year)), findsOneWidget);
  });

  testWidgets('vuốt trái → tháng sau', (tester) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(DayTile).first, const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(3, 2027)), findsOneWidget);
  });

  testWidgets('tap ô 6/2 → DayDetail Tết; Quay lại → giữ tháng', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(key(6)));
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.text('Tết Nguyên đán'), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
  });

  testWidgets('bottom nav: Đổi ngày, Cài đặt, về Lịch vẫn giữ 2/2027', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();
    expect(find.text(Strings.solarToLunarTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Strings.remoteConfigSection), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
  });

  testWidgets(
    'picker tháng dương → /2027/05; picker tháng âm → tháng chứa mùng 1',
    (tester) async {
      await tester.pumpWidget(await testApp('/2027/02'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.monthTitle(2, 2027)));
      await tester.pumpAndSettle();
      expect(find.text(Strings.pickMonth), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '5'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.monthTitle(5, 2027)), findsOneWidget);

      // Tháng âm: chọn Chạp (12) năm 2026 → mùng 1 tháng Chạp Bính Ngọ = 08/01/2027.
      await tester.tap(find.text(Strings.lunarMonthButton));
      await tester.pumpAndSettle();
      expect(find.text(Strings.pickLunarMonth), findsOneWidget);
      await tester.tap(find.byTooltip(Strings.prevYear));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chạp'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.monthTitle(1, 2027)), findsOneWidget);
    },
  );

  testWidgets('/ → tháng hiện tại; /2027/13 → tháng hiện tại', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(await testApp('/'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(now.month, now.year)), findsOneWidget);

    await tester.pumpWidget(await testApp('/2027/13'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(now.month, now.year)), findsOneWidget);
  });
}
