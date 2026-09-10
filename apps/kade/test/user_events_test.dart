// CRUD sự kiện cá nhân qua UI thật (plan §6 bước 7: tạo/sửa/xóa, reload,
// tháng nhuận firstMonth).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/month_provider.dart';
import 'package:kade/features/month_view/month_view_screen.dart';
import 'package:kade/features/user_events/user_events_screen.dart';
import 'package:lunar_core/lunar_core.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testTall('tạo từ DayDetail → hiện ở DayDetail + MonthView; sửa; xóa; reload', (
    tester,
  ) async {
    final box = await memoryUserEventsBox();
    await tester.pumpWidget(await testApp('/d/2027-02-06', userEventsBox: box));
    await tester.pumpAndSettle();
    expect(find.text(Strings.noUserEvents), findsOneWidget);

    // Tạo: form điền sẵn 6/2 dương, lặp hàng năm.
    await tester.tap(find.text(Strings.addEvent));
    await tester.pumpAndSettle();
    expect(find.text(Strings.newEvent), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: key('ev-day'),
              matching: find.byType(TextFormField),
            ),
          )
          .controller!
          .text,
      '6',
    );
    // Lưu khi chưa có tên → báo lỗi, vẫn ở form.
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.titleRequired), findsOneWidget);
    await tester.enterText(key('ev-title'), 'Giỗ ông');
    await tester.tap(key('ev-color-2'));
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();

    // Về DayDetail, thấy sự kiện.
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.text('Giỗ ông'), findsOneWidget);
    expect(find.text(Strings.noUserEvents), findsNothing);
    expect(find.text('6/2 DL · ${Strings.everyYear}'), findsOneWidget);

    // MonthView: ô 6/2 có sự kiện cá nhân + nhãn DL (Tết là ÂL).
    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    final tile = tester.widget<DayTile>(key('day-2027-02-06'));
    expect(tile.cell.userEvents.single.title, 'Giỗ ông');
    expect(
      find.descendant(
        of: key('day-2027-02-06'),
        matching: find.text(Strings.solarTag),
      ),
      findsOneWidget,
    );

    // Sửa: tap ô → DayDetail → tap sự kiện → form sửa → đổi tên.
    await tester.tap(key('day-2027-02-06'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giỗ ông'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.editEvent), findsOneWidget);
    await tester.enterText(key('ev-title'), 'Giỗ bà');
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(find.text('Giỗ bà'), findsOneWidget);
    expect(find.text('Giỗ ông'), findsNothing);

    // Xóa: form sửa → nút xóa → xác nhận.
    await tester.tap(find.text('Giỗ bà'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Strings.delete));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteEventTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, Strings.delete));
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.text(Strings.noUserEvents), findsOneWidget);

    // "Reload": app mới trên cùng box → tombstone còn trong box, UI không hiện.
    await tester.pumpWidget(await testApp('/d/2027-02-06', userEventsBox: box));
    await tester.pumpAndSettle();
    expect(find.text(Strings.noUserEvents), findsOneWidget);
    final all = UserEventRepository(box).all();
    expect(all.single.title, 'Giỗ bà');
    expect(all.single.isDeleted, isTrue);
    expect(all.single.colorIndex, 2);
  });

  testTall('reload giữ sự kiện: tạo ở app 1, app 2 cùng box thấy', (
    tester,
  ) async {
    final box = await memoryUserEventsBox();
    await tester.pumpWidget(
      await testApp('/events/new?date=2027-02-06', userEventsBox: box),
    );
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-title'), 'Sinh nhật');
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(await testApp('/2027/02', userEventsBox: box));
    await tester.pumpAndSettle();
    final tile = tester.widget<DayTile>(key('day-2027-02-06'));
    expect(tile.cell.userEvents.single.title, 'Sinh nhật');
  });

  testTall('âm lịch 15/6 hàng năm firstMonth: 2025 chỉ tháng chính', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/events'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.noUserEvents), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.addEvent));
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-title'), 'Giỗ cụ');
    await tester.tap(find.text(Strings.lunarType));
    await tester.pumpAndSettle();
    expect(find.text(Strings.leapRuleLabel), findsOneWidget);
    await tester.enterText(key('ev-day'), '15');
    await tester.enterText(key('ev-month'), '6');
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();

    // Danh sách: subtitle "15/6 ÂL · hàng năm".
    expect(find.text('Giỗ cụ'), findsOneWidget);
    expect(find.text('15/6 ÂL · ${Strings.everyYear}'), findsOneWidget);

    // Kiểm tra qua cache tháng thật của app (2025 nhuận tháng 6).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UserEventsScreen)),
    );
    final chinh = lunarToSolar(const LunarDate(day: 15, month: 6, year: 2025))!;
    final nhuan = lunarToSolar(
      const LunarDate(day: 15, month: 6, year: 2025, isLeapMonth: true),
    )!;
    DayCell cell(DateTime d) =>
        container.read(monthProvider((d.year, d.month)))[d]!;
    expect(cell(chinh).userEvents.map((e) => e.title), ['Giỗ cụ']);
    expect(cell(nhuan).userEvents, isEmpty);
  });

  testTall('sự kiện một lần ngày không tồn tại → báo lỗi, không lưu', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/events/new'));
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-title'), 'x');
    await tester.tap(find.text(Strings.lunarType));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.yearly)); // bỏ lặp hàng năm
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-day'), '1');
    await tester.enterText(key('ev-month'), '5');
    await tester.enterText(key('ev-year'), '2027');
    await tester.tap(
      find.text(Strings.leapSecond),
    ); // 2027 không nhuận → vẫn tháng chính, hợp lệ
    await tester.pumpAndSettle();
    expect(
      find.text(Strings.leapBoth),
      findsNothing,
    ); // một lần: không có "Cả hai"

    await tester.enterText(key('ev-day'), '31');
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.invalidEventDate), findsOneWidget);
    expect(find.text(Strings.newEvent), findsOneWidget);

    await tester.tap(find.text(Strings.solarType));
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-day'), '30');
    await tester.enterText(key('ev-month'), '2');
    await tester.enterText(key('ev-year'), '2027');
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.eventDateMissing), findsOneWidget);
  });

  testTall('Cài đặt → Sự kiện của tôi → danh sách', (tester) async {
    await tester.pumpWidget(await testApp('/settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.myEvents));
    await tester.pumpAndSettle();
    expect(find.byType(UserEventsScreen), findsOneWidget);
    expect(find.text(Strings.noUserEvents), findsOneWidget);
    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    expect(find.text(Strings.remoteConfigSection), findsOneWidget);
  });
}
