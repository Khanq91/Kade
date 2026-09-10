// Duyệt theo tháng âm (`?lunar=1`, D033): shiftLunarMonth cho tháng dương có
// 1, 2 hoặc 0 mùng 1; route giữ cờ khi ◀ ▶, picker âm bật, picker dương /
// Hôm nay tắt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/lunar_utils.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/features/month_view/month_view_screen.dart';
import 'package:lunar_core/lunar_core.dart';

import 'test_app.dart';

void main() {
  (int, int) solarMonthOf(LunarDate first) {
    final s = lunarToSolar(first)!;
    return (s.year, s.month);
  }

  test('2/2027 (mùng 1 Giêng 06/02): sau → 3/2027 (Hai), trước → 1/2027', () {
    expect(lunarMonthsStartingIn(2027, 2).single.month, 1);
    expect(shiftLunarMonth(2027, 2, 1), (2027, 3));
    expect(shiftLunarMonth(2027, 2, -1), (2027, 1));
    // Kiểm bằng engine: mùng 1 tháng Hai / tháng Chạp.
    expect(solarMonthOf(const LunarDate(day: 1, month: 2, year: 2027)), (
      2027,
      3,
    ));
    expect(solarMonthOf(const LunarDate(day: 1, month: 12, year: 2026)), (
      2027,
      1,
    ));
  });

  test('tháng dương có 2 mùng 1 → sau/trước vẫn đổi tháng dương', () {
    var found = 0;
    for (var y = 2024; y <= 2030; y++) {
      for (var m = 1; m <= 12; m++) {
        final firsts = lunarMonthsStartingIn(y, m);
        if (firsts.length != 2) continue;
        found++;
        final next = DateTime.utc(y, m + 1);
        final prev = DateTime.utc(y, m - 1);
        expect(shiftLunarMonth(y, m, 1), (next.year, next.month));
        expect(shiftLunarMonth(y, m, -1), (prev.year, prev.month));
        // Tháng đích là tháng âm kề với mùng 1 muộn nhất / sớm nhất.
        expect(solarMonthOf(adjacentLunarMonth(firsts.last, 1)), (
          next.year,
          next.month,
        ));
        expect(solarMonthOf(adjacentLunarMonth(firsts.first, -1)), (
          prev.year,
          prev.month,
        ));
      }
    }
    expect(found, greaterThan(0));
  });

  test('tháng 2 không có mùng 1 → sau = tháng 3, trước = tháng 1', () {
    var found = 0;
    for (var y = 2000; y <= 2060; y++) {
      if (lunarMonthsStartingIn(y, 2).isNotEmpty) continue;
      found++;
      expect(shiftLunarMonth(y, 2, 1), (y, 3));
      expect(shiftLunarMonth(y, 2, -1), (y, 1));
    }
    expect(found, greaterThan(0));
  });

  test('adjacentLunarMonth đi qua tháng nhuận (2025 nhuận 6)', () {
    const sau = LunarDate(day: 1, month: 6, year: 2025);
    final nhuan = adjacentLunarMonth(sau, 1);
    expect((nhuan.month, nhuan.isLeapMonth), (6, true));
    final bay = adjacentLunarMonth(nhuan, 1);
    expect((bay.month, bay.isLeapMonth), (7, false));
    final back = adjacentLunarMonth(bay, -1);
    expect((back.month, back.isLeapMonth), (6, true));
  });

  testWidgets('?lunar=1: ▶ ◀ theo tháng âm; Hôm nay tắt; picker âm bật', (
    tester,
  ) async {
    bool lunarMode() =>
        tester.widget<MonthViewScreen>(find.byType(MonthViewScreen)).lunar;

    await tester.pumpWidget(
      await testApp('/2027/02?lunar=1', today: DateTime.utc(2027, 6, 15)),
    );
    await tester.pumpAndSettle();
    expect(lunarMode(), isTrue);

    await tester.tap(find.byTooltip(Strings.nextMonth));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(3, 2027)), findsOneWidget);
    expect(lunarMode(), isTrue);

    await tester.tap(find.byTooltip(Strings.prevMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Strings.prevMonth));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(1, 2027)), findsOneWidget);
    expect(lunarMode(), isTrue);

    await tester.tap(find.text(Strings.today));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(6, 2027)), findsOneWidget);
    expect(lunarMode(), isFalse);

    // Picker âm: Chạp năm trước (2026) → 1/2027, bật chế độ âm.
    await tester.tap(find.text(Strings.lunarMonthButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Strings.prevYear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chạp'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(1, 2027)), findsOneWidget);
    expect(lunarMode(), isTrue);

    // Picker dương tắt chế độ âm.
    await tester.tap(find.text(Strings.monthTitle(1, 2027)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '5'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(5, 2027)), findsOneWidget);
    expect(lunarMode(), isFalse);
  });
}
