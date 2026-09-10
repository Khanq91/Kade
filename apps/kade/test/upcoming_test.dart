// "Sắp tới" (plan §6 bước 8): sự kiện âm hiện đúng ngày dương năm nay / năm
// sau, gom theo ngày, nhiều ngày chỉ 1 dòng, lớp bật/tắt lưu settings.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/models/event_layer.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/upcoming_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/features/upcoming/upcoming_screen.dart';
import 'package:lunar_core/lunar_core.dart';

import 'test_app.dart';

void main() {
  Future<ProviderContainer> container({
    required DateTime today,
    Box<dynamic>? settingsBox,
  }) async {
    final c = ProviderContainer.test(
      overrides: await testOverrides(today: today, settingsBox: settingsBox),
    );
    await c.read(remoteConfigProvider.future);
    return c;
  }

  /// (ngày, số ngày còn) của sự kiện app [id], hoặc null.
  (DateTime, int)? hit(List<UpcomingDay> days, String id) {
    for (final d in days) {
      for (final it in d.items) {
        if (it.appEvent?.id == id) return (d.date, d.daysFromToday);
      }
    }
    return null;
  }

  test(
    'từ 01/01/2027: Tết Dương lịch hôm nay, Tết âm 06/02 (còn 36 ngày), 1 dòng',
    () async {
      final c = await container(today: DateTime.utc(2027, 1, 1));
      final days = c.read(upcomingProvider);

      expect(hit(days, 'tet-duong-lich'), (DateTime.utc(2027, 1, 1), 0));
      expect(hit(days, 'giao-thua'), (DateTime.utc(2027, 2, 5), 35));
      expect(hit(days, 'tet'), (DateTime.utc(2027, 2, 6), 36));
      expect(hit(days, 'ram-thang-gieng'), (DateTime.utc(2027, 2, 20), 50));
      expect(hit(days, 'valentine'), (DateTime.utc(2027, 2, 14), 44));
      // Ông Táo 23/12 âm → ngày dương lấy từ engine.
      final ongTao = lunarToSolar(
        const LunarDate(day: 23, month: 12, year: 2026),
      )!;
      expect(hit(days, 'ong-tao')?.$1, ongTao);
      // Tết 3 ngày: chỉ 1 dòng (07, 08/02 không lặp).
      final tetRows = [
        for (final d in days)
          for (final it in d.items)
            if (it.appEvent?.id == 'tet') d.date,
      ];
      expect(tetRows, [DateTime.utc(2027, 2, 6)]);
      // Ngày không có sự kiện không xuất hiện; đúng thứ tự tăng dần.
      expect(days.map((d) => d.daysFromToday), isNot(contains(2)));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].daysFromToday, greaterThan(days[i - 1].daysFromToday));
      }
      expect(days.last.daysFromToday, lessThan(upcomingWindowDays));
    },
  );

  test('từ 01/12/2027: Tết 2028 (năm sau) hiện đúng ngày dương', () async {
    final c = await container(today: DateTime.utc(2027, 12, 1));
    final days = c.read(upcomingProvider);
    final tet2028 = lunarToSolar(
      const LunarDate(day: 1, month: 1, year: 2028),
    )!;
    final tet = hit(days, 'tet');
    expect(tet?.$1, tet2028);
    expect(tet?.$2, tet2028.difference(DateTime.utc(2027, 12, 1)).inDays);
    expect(hit(days, 'giang-sinh'), (DateTime.utc(2027, 12, 25), 24));
  });

  test(
    'sự kiện cá nhân âm 1/1 hàng năm: năm nay và năm sau đúng ngày dương',
    () async {
      final c1 = await container(today: DateTime.utc(2027, 1, 1));
      await c1
          .read(userEventsProvider.notifier)
          .create(title: 'Giỗ ông', type: CalendarType.lunar, day: 1, month: 1);
      final personal = [
        for (final d in c1.read(upcomingProvider))
          for (final it in d.items)
            if (it.userEvent != null) (d.date, it.title),
      ];
      expect(personal, [(DateTime.utc(2027, 2, 6), 'Giỗ ông')]);

      final c2 = await container(today: DateTime.utc(2027, 12, 1));
      await c2
          .read(userEventsProvider.notifier)
          .create(
            title: 'Giỗ ông',
            type: CalendarType.lunar,
            day: 1,
            month: 1,
            durationDays: 2,
          );
      final tet2028 = lunarToSolar(
        const LunarDate(day: 1, month: 1, year: 2028),
      )!;
      final rows = [
        for (final d in c2.read(upcomingProvider))
          for (final it in d.items)
            if (it.userEvent != null) d.date,
      ];
      expect(rows, [tet2028]); // 2 ngày → 1 dòng
    },
  );

  test('đang diễn ra: hôm nay mùng 2 Tết → Tết ở "Hôm nay"', () async {
    final c = await container(today: DateTime.utc(2027, 2, 7));
    expect(hit(c.read(upcomingProvider), 'tet'), (DateTime.utc(2027, 2, 7), 0));
  });

  test('lớp tắt → ẩn; lưu settings; container mới cùng box đọc lại', () async {
    final box = await memorySettingsBox();
    final c = await container(
      today: DateTime.utc(2027, 1, 1),
      settingsBox: box,
    );
    expect(c.read(layersProvider), EventLayer.values.toSet());

    await c.read(layersProvider.notifier).toggle(EventLayer.vnHoliday);
    final days = c.read(upcomingProvider);
    expect(hit(days, 'tet'), isNull);
    expect(hit(days, 'ram-thang-gieng'), isNotNull);
    expect(box.get(LayersNotifier.key), [
      'vnMemorial',
      'international',
      'personal',
    ]);

    final c2 = await container(
      today: DateTime.utc(2027, 1, 1),
      settingsBox: box,
    );
    expect(c2.read(layersProvider), isNot(contains(EventLayer.vnHoliday)));
    await c2.read(layersProvider.notifier).toggle(EventLayer.vnHoliday);
    expect(hit(c2.read(upcomingProvider), 'tet'), isNotNull);
  });

  testWidgets(
    'màn Sắp tới: nhóm theo ngày, chip tắt Nghỉ lễ, tap → DayDetail',
    (tester) async {
      await tester.pumpWidget(
        await testApp('/upcoming', today: DateTime.utc(2027, 1, 1)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UpcomingScreen), findsOneWidget);
      expect(find.text(Strings.navUpcoming), findsNWidgets(2)); // AppBar + nav
      expect(
        find.textContaining('${Strings.today} · Thứ Sáu, 01/01/2027'),
        findsOneWidget,
      );
      expect(find.text('Tết Dương lịch'), findsOneWidget);
      expect(find.text('Tết Nguyên đán', skipOffstage: false), findsOneWidget);
      expect(
        find.textContaining(Strings.inDays(36), skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilterChip, Strings.kindHoliday));
      await tester.pumpAndSettle();
      expect(find.text('Tết Nguyên đán', skipOffstage: false), findsNothing);
      expect(find.text('Tết Dương lịch'), findsNothing);
      expect(
        find.text('Lễ tình nhân (Valentine)', skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilterChip, Strings.kindHoliday));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tết Dương lịch'));
      await tester.pumpAndSettle();
      expect(find.text('01/01/2027'), findsOneWidget); // DayDetail
    },
  );

  testWidgets('bottom nav có 4 tab, Sắp tới ở vị trí 2', (tester) async {
    await tester.pumpWidget(await testApp('/2027/02'));
    await tester.pumpAndSettle();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 4);
    await tester.tap(find.byIcon(Icons.upcoming_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(UpcomingScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
