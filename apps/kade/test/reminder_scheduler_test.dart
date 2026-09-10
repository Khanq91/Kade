// ReminderScheduler + UI (bước 16) với Notifications giả: start → init + đặt
// nhắc lễ; form "Nhắc trước" → lưu remindBeforeDays, xin quyền, đặt lại;
// quyền bị từ chối → SnackBar; Cài đặt "Nhắc lễ trước" → đặt lại + lưu box +
// xin quyền; chạm thông báo → DayDetail; web không có mục Nhắc nhở.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/reminder_scheduler.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/main.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  DateTime clock() => DateTime(2027, 1, 20, 10);

  testTall('start: init + nhắc lễ; form Nhắc trước → lưu, xin quyền, đặt lại', (
    tester,
  ) async {
    final fake = FakeNotifications();
    final box = await memoryUserEventsBox();
    await tester.pumpWidget(
      await testApp(
        '/events/new',
        notifications: fake,
        clock: clock,
        userEventsBox: box,
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.initialized, isTrue);
    expect(fake.scheduleCalls, 1);
    expect(fake.scheduled.map((r) => r.title), contains('Tết Nguyên đán'));
    expect(fake.permissionRequests, 0); // không xin lúc mở app

    await tester.enterText(key('ev-title'), 'Sinh nhật');
    await tester.enterText(key('ev-day'), '1');
    await tester.enterText(key('ev-month'), '3');
    await tester.tap(key('ev-remind'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.remindDaysBefore(3)).last);
    await tester.pumpAndSettle();
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();

    expect(UserEventRepository(box).all().single.remindBeforeDays, 3);
    expect(fake.permissionRequests, 1);
    final r = fake.scheduled.singleWhere((r) => r.title == 'Sinh nhật');
    expect(r.date, DateTime.utc(2027, 3, 1));
    expect(r.fireAt, DateTime(2027, 2, 26, 8));
    expect(find.text(Strings.notificationsDenied), findsNothing);

    final c = ProviderScope.containerOf(
      tester.element(find.byType(AppLifecycle)),
    );
    expect(c.read(reminderSchedulerProvider).last, fake.scheduled);
  });

  testTall('quyền bị từ chối → SnackBar; sửa bỏ nhắc → không xin nữa', (
    tester,
  ) async {
    final fake = FakeNotifications()..permissionGranted = false;
    await tester.pumpWidget(
      await testApp('/events/new', notifications: fake, clock: clock),
    );
    await tester.pumpAndSettle();
    await tester.enterText(key('ev-title'), 'A');
    await tester.tap(key('ev-remind'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.remindSameDay).last);
    await tester.pumpAndSettle();
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(fake.permissionRequests, 1);
    expect(find.text(Strings.notificationsDenied), findsOneWidget);

    // Mở lại sửa → chọn "Không nhắc" → lưu không xin quyền.
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(key('ev-remind'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.remindNone).last);
    await tester.pumpAndSettle();
    await tester.tap(key('ev-save'));
    await tester.pumpAndSettle();
    expect(fake.permissionRequests, 1);
    expect(fake.scheduled.where((r) => r.title == 'A'), isEmpty);
  });

  testTall(
    'Cài đặt: Nhắc lễ trước → Không nhắc (lưu box) → 3 ngày (xin quyền)',
    (tester) async {
      final fake = FakeNotifications();
      final box = await memorySettingsBox();
      await tester.pumpWidget(
        await testApp(
          '/settings',
          notifications: fake,
          clock: clock,
          settingsBox: box,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Strings.remindSection), findsOneWidget);
      expect(fake.scheduled.map((r) => r.title), contains('Tết Nguyên đán'));

      await tester.tap(key('remind-holiday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.remindNone).last);
      await tester.pumpAndSettle();
      expect(box.get(HolidayRemindDaysNotifier.key), 0);
      expect(fake.scheduled, isEmpty);
      expect(fake.permissionRequests, 0);

      await tester.tap(key('remind-holiday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.remindDaysBefore(3)).last);
      await tester.pumpAndSettle();
      expect(box.get(HolidayRemindDaysNotifier.key), 3);
      expect(fake.permissionRequests, 1);
      final tet = fake.scheduled.singleWhere(
        (r) => r.title == 'Tết Nguyên đán',
      );
      expect(tet.fireAt, DateTime(2027, 2, 3, 8));
    },
  );

  testWidgets('chạm thông báo → mở DayDetail của ngày trong payload', (
    tester,
  ) async {
    final fake = FakeNotifications();
    await tester.pumpWidget(await testApp('/2027/01', notifications: fake));
    await tester.pumpAndSettle();
    fake.tap('/d/2027-02-06');
    await tester.pumpAndSettle();
    expect(find.text('06/02/2027'), findsOneWidget);
    expect(find.text('Tết Nguyên đán'), findsOneWidget);
  });

  testTall('web: không có mục Nhắc nhở; form có ghi chú chỉ Android', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/settings', isWeb: true));
    await tester.pumpAndSettle();
    expect(find.text(Strings.remindSection), findsNothing);
    await tester.pumpWidget(await testApp('/events/new', isWeb: true));
    await tester.pumpAndSettle();
    expect(find.text(Strings.remindWebHint), findsOneWidget);
  });
}
