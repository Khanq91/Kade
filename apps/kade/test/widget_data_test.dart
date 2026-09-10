// buildWidgetData / widgetDataProvider (plan §5.2, bước 17): 35 ngày từ hôm
// nay, ngày Tết có sự kiện + nghỉ, sự kiện cá nhân, lọc theo lớp, JSON đúng
// schema TodayCardData; widgetRouteOf, nextMidnights.
import 'dart:convert';

import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/data/models/event_layer.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/data/widget_data.dart';
import 'package:kade/data/widget_updater.dart';

import 'test_app.dart';

void main() {
  test(
    '35 ngày từ 01/02/2027: Tết 06/02 nghỉ + sự kiện, JSON đúng schema',
    () async {
      final c = ProviderContainer.test(
        overrides: await testOverrides(today: DateTime.utc(2027, 2, 1)),
      );
      await c.read(remoteConfigProvider.future);
      await c
          .read(userEventsProvider.notifier)
          .create(title: 'Giỗ ông', type: CalendarType.lunar, day: 1, month: 1);
      final data = c.read(widgetDataProvider);
      expect(data.days.length, widgetDays);
      expect(data.days.first.date, DateTime.utc(2027, 2, 1));
      expect(data.days.last.date, DateTime.utc(2027, 3, 7));

      final tet = data.days[5];
      expect(tet.date, DateTime.utc(2027, 2, 6));
      expect(tet.isOffDay, isTrue);
      expect(tet.lunar.day, 1);
      expect(tet.events.map((e) => e.title), ['Tết Nguyên đán', 'Giỗ ông']);
      expect(tet.events.first.layer, EventLayer.vnHoliday);
      expect(tet.events.last.layer, EventLayer.personal);

      final json = jsonDecode(data.encode()) as Map<String, dynamic>;
      expect(json['schema'], 1);
      expect(json['generatedAt'], isA<String>());
      final days = json['days'] as List;
      expect(days.length, widgetDays);
      final d = days[5] as Map<String, dynamic>;
      expect(d['date'], '2027-02-06');
      expect(d['weekday'], 'Thứ Bảy');
      expect(d['solarDay'], 6);
      expect(d['solarMonth'], 2);
      expect(d['lunarDay'], 1);
      expect(d['lunarMonth'], 1);
      expect(d['isLeapMonth'], false);
      expect(d['canChiDay'], 'Bính Thìn');
      expect(d['isOffDay'], true);
      final ev = (d['events'] as List).first as Map<String, dynamic>;
      expect(ev['title'], 'Tết Nguyên đán');
      expect(ev['layer'], 'vnHoliday');
      expect(ev['color'], 0xFFC62828);
    },
  );

  test('lớp tắt → sự kiện lớp đó không vào widget; tính lại khi đổi', () async {
    final c = ProviderContainer.test(
      overrides: await testOverrides(today: DateTime.utc(2027, 2, 1)),
    );
    await c.read(remoteConfigProvider.future);
    expect(c.read(widgetDataProvider).days[5].events, isNotEmpty);
    await c.read(layersProvider.notifier).toggle(EventLayer.vnHoliday);
    final tet = c.read(widgetDataProvider).days[5];
    expect(tet.events, isEmpty);
    expect(tet.isOffDay, isTrue); // nghỉ vẫn đúng
  });

  test('widgetRouteOf: kade://open/d/… → /d/…; rỗng → null', () {
    expect(
      widgetRouteOf(Uri.parse('kade://open/d/2027-02-06')),
      '/d/2027-02-06',
    );
    expect(widgetRouteOf(Uri.parse('kade://open/')), isNull);
    expect(widgetRouteOf(Uri()), isNull);
    expect(widgetRouteOf(null), isNull);
  });

  test('nextMidnights: 00:00:05 các ngày sau, qua tháng/năm', () {
    final list = nextMidnights(DateTime(2026, 12, 30, 15, 20), 3);
    expect(list, [
      DateTime(2026, 12, 31, 0, 0, 5),
      DateTime(2027, 1, 1, 0, 0, 5),
      DateTime(2027, 1, 2, 0, 0, 5),
    ]);
  });
}
