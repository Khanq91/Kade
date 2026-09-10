// Layout 3 breakpoint (plan §4.2, bước 14) + DayDetail dialog/trang + phím tắt
// (plan §4.7): ≥ 1024 rail + 2 cột (hero hôm nay + Sắp tới), tap ô → dialog,
// Esc/Đóng đóng; 600–1023 rail + lịch trên Sắp tới dưới, tap ô → trang riêng,
// Esc quay lại; < 600 bottom nav, chỉ lịch. ← → đổi tháng, T về hôm nay.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/features/month_view/month_view_screen.dart';
import 'package:kade/features/month_view/today_card.dart';
import 'package:kade/features/upcoming/upcoming_screen.dart';

import 'test_app.dart';

void main() {
  final today = DateTime.utc(2027, 2, 1); // Thứ Hai, 25/12 Bính Ngọ
  Finder day(int d) =>
      find.byKey(ValueKey('day-2027-02-${d < 10 ? '0$d' : d}'));

  testWidgets('≥ 1024: rail + hero hôm nay + Sắp tới; ô → dialog; Esc/Đóng', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 800));
    await tester.pumpWidget(await testApp('/2027/02', today: today));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(DayTile), findsNWidgets(28));

    // Hero: dữ liệu hôm nay từ engine + cache tháng.
    expect(find.byType(TodayCard), findsOneWidget);
    expect(find.text('Thứ Hai'), findsOneWidget);
    expect(find.text(Strings.monthYearLong(2, 2027)), findsOneWidget);
    expect(
      find.text('${Strings.lunarLabel} 25/12 · ${Strings.yearLabel} Bính Ngọ'),
      findsOneWidget,
    );
    // Sắp tới gọn (không chip) trong panel.
    expect(find.byType(UpcomingList), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(
      find.descendant(
        of: find.byType(UpcomingList),
        matching: find.text('Giao thừa', skipOffstage: false),
      ),
      findsOneWidget,
    );

    // Tap ô 6/2 → dialog, không đổi trang lịch.
    await tester.tap(day(6));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Tết Nguyên đán'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(Strings.close), findsOneWidget);
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);

    // ▶ trong dialog vẫn là dialog.
    await tester.tap(find.byTooltip(Strings.nextDay));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('07/02/2027'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);

    // Hero tap → dialog hôm nay; nút Đóng.
    await tester.tap(find.byType(TodayCard));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('01/02/2027'), findsOneWidget);
    await tester.tap(find.byTooltip(Strings.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('≥ 1024 nhưng mở thẳng /d/… → trang riêng (dưới không có gì)', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 800));
    await tester.pumpWidget(await testApp('/d/2027-02-06', today: today));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Tết Nguyên đán'), findsOneWidget);
    expect(find.byTooltip(Strings.back), findsOneWidget);
    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
  });

  testWidgets('600–1023: rail + lịch trên, Sắp tới dưới; ô → trang; Esc', (
    tester,
  ) async {
    setViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(await testApp('/2027/02', today: today));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TodayCard), findsNothing);
    expect(find.byType(UpcomingList), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(DayTile), findsNWidgets(28));

    await tester.tap(day(6));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.byTooltip(Strings.back), findsOneWidget);
    expect(find.byType(DayTile), findsNothing); // trang riêng che lịch

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsNothing);
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
  });

  testWidgets('< 600: bottom nav, chỉ lịch', (tester) async {
    setViewport(tester, const Size(400, 800));
    await tester.pumpWidget(await testApp('/2027/02', today: today));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(TodayCard), findsNothing);
    expect(find.byType(UpcomingList), findsNothing);
    expect(find.byType(DayTile), findsNWidgets(28));
  });

  testWidgets('phím ← → đổi tháng, T về tháng hôm nay', (tester) async {
    await tester.pumpWidget(
      await testApp('/2027/02', today: DateTime.utc(2027, 6, 15)),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(3, 2027)), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(1, 2027)), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(6, 2027)), findsOneWidget);
  });
}
