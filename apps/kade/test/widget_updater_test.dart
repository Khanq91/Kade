// WidgetUpdater (bước 17) với HomeWidgets giả: start → đẩy 35 ngày + hẹn 35
// mốc 00:00:05; sửa sự kiện → đẩy lại có sự kiện; đổi lớp → đẩy lại; resume →
// đẩy; chạm widget khi đang chạy → DayDetail; mở app từ widget → DayDetail.
import 'dart:convert';

import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/models/event_layer.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/data/widget_data.dart';
import 'package:kade/main.dart';

import 'test_app.dart';

void main() {
  DateTime clock() => DateTime(2027, 2, 1, 10);
  final today = DateTime.utc(2027, 2, 1);

  List<dynamic> days(String json) =>
      (jsonDecode(json) as Map<String, dynamic>)['days'] as List;

  testWidgets(
    'start → đẩy 35 ngày + hẹn 35 mốc; sửa sự kiện / lớp / resume → đẩy lại',
    (tester) async {
      final fake = FakeHomeWidgets();
      await tester.pumpWidget(
        await testApp(
          '/2027/02',
          homeWidgets: fake,
          clock: clock,
          today: today,
        ),
      );
      await tester.pumpAndSettle();
      // Start đẩy 1 lần + 1 lần khi remote config nạp xong (overrides đổi).
      expect(fake.pushed, isNotEmpty);
      final n0 = fake.pushed.length;
      expect(days(fake.pushed.last).length, widgetDays);
      expect((days(fake.pushed.last).first as Map)['date'], '2027-02-01');
      expect(fake.refreshAt.length, widgetDays);
      expect(fake.refreshAt.first, DateTime(2027, 2, 2, 0, 0, 5));
      expect(fake.refreshAt.last, DateTime(2027, 3, 8, 0, 0, 5));

      final c = ProviderScope.containerOf(
        tester.element(find.byType(AppLifecycle)),
      );
      await c
          .read(userEventsProvider.notifier)
          .create(title: 'Giỗ ông', type: CalendarType.solar, day: 3, month: 2);
      await tester.pumpAndSettle();
      expect(fake.pushed.length, n0 + 1);
      final d3 = days(fake.pushed.last)[2] as Map<String, dynamic>;
      expect(d3['date'], '2027-02-03');
      // 03/02 sẵn có sự kiện app (thành lập Đảng) + sự kiện vừa tạo.
      List<Object?> titles(Map<String, dynamic> d) =>
          (d['events'] as List).map((e) => (e as Map)['title']).toList();
      expect(titles(d3), contains('Giỗ ông'));

      await c.read(layersProvider.notifier).toggle(EventLayer.personal);
      await tester.pumpAndSettle();
      expect(fake.pushed.length, n0 + 2);
      expect(
        titles(days(fake.pushed.last)[2] as Map<String, dynamic>),
        isNot(contains('Giỗ ông')),
      );

      await sendLifecycle(tester, AppLifecycleState.paused);
      await sendLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(fake.pushed.length, n0 + 3);
    },
  );

  testWidgets('chạm widget khi app đang chạy → DayDetail', (tester) async {
    final fake = FakeHomeWidgets();
    await tester.pumpWidget(await testApp('/2027/01', homeWidgets: fake));
    await tester.pumpAndSettle();
    fake.emitClick(Uri.parse('kade://open/d/2027-02-06'));
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.text('Tết Nguyên đán'), findsOneWidget);
  });

  testWidgets('mở app từ widget → DayDetail ngay lúc start', (tester) async {
    final fake = FakeHomeWidgets()
      ..initial = Uri.parse('kade://open/d/2027-02-06');
    await tester.pumpWidget(await testApp('/2027/01', homeWidgets: fake));
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsOneWidget);
    await tester.tap(find.byTooltip(Strings.back));
    await tester.pumpAndSettle();
    expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
  });
}
