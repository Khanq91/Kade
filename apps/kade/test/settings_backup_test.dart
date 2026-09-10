// Cài đặt → "Sao lưu" (plan §6 bước 9) với FileIo giả: bấm Xuất → fake nhận
// đúng JSON; xóa; bấm Nhập → dialog → sự kiện hiện lại trong "Sự kiện của
// tôi"; file hỏng / hủy → thông báo hoặc không làm gì.
import 'dart:convert';

import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/models/sync_envelope.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/features/settings/settings_screen.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testTall('Xuất → fake nhận JSON; xóa; Nhập → dialog → hiện lại', (
    tester,
  ) async {
    final fake = FakeFileIo();
    final box = await memoryUserEventsBox();
    await tester.pumpWidget(
      await testApp('/settings', userEventsBox: box, fileIo: fake),
    );
    await tester.pumpAndSettle();
    expect(find.text(Strings.backupSection), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    final notifier = container.read(userEventsProvider.notifier);
    final e = await notifier.create(
      title: 'Giỗ ông',
      type: CalendarType.lunar,
      day: 15,
      month: 8,
      note: 'ghi chú',
    );

    // Xuất.
    await tester.tap(key('backup-export'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.exported(1)), findsOneWidget);
    final (name, content) = fake.saved.single;
    expect(name, SyncEnvelope.fileName(DateTime.now()));
    final json = jsonDecode(content) as Map<String, dynamic>;
    expect(json['schema'], 1);
    expect(json['deviceId'], container.read(deviceIdProvider));
    final parsed = SyncEnvelope.parse(content) as EnvelopeOk;
    expect(parsed.envelope.events, [e]);

    // Xóa (tombstone) rồi nhập lại chính file vừa xuất.
    await notifier.remove(e.id);
    expect(container.read(activeUserEventsProvider), isEmpty);
    fake.pickResult = content;
    await tester.tap(key('backup-import'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.importConfirmTitle(1)), findsOneWidget);
    expect(find.text(Strings.importConfirmBody), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, Strings.importButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.imported(1)), findsOneWidget);
    expect(container.read(activeUserEventsProvider).single.title, 'Giỗ ông');
    final stored = UserEventRepository(box).all().single;
    expect(stored.isDeleted, isFalse);
    expect(stored.note, 'ghi chú');

    // "Sự kiện của tôi" thấy lại.
    await tester.tap(find.text(Strings.myEvents));
    await tester.pumpAndSettle();
    expect(find.text('Giỗ ông'), findsOneWidget);
    expect(find.text('15/8 ÂL · ${Strings.everyYear}'), findsOneWidget);
  });

  testTall('hủy chọn file / file hỏng / schema sai / hủy dialog / hủy lưu', (
    tester,
  ) async {
    final fake = FakeFileIo();
    await tester.pumpWidget(await testApp('/settings', fileIo: fake));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );

    // Hủy chọn file → không dialog, không SnackBar.
    fake.pickResult = null;
    await tester.tap(key('backup-import'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    // JSON hỏng → lỗi.
    fake.pickResult = '{oops';
    await tester.tap(key('backup-import'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.backupInvalidJson), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // Schema sai → lỗi.
    fake.pickResult =
        '{"schema": 2, "exportedAt": "2026-09-10T08:00:00Z", "deviceId": "d", "events": []}';
    await tester.tap(key('backup-import'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.backupUnsupportedSchema(2, 1)), findsOneWidget);

    // File hợp lệ nhưng bấm Hủy → không nhập.
    final t0 = DateTime.utc(2026, 9, 10);
    fake.pickResult = SyncEnvelope(
      exportedAt: t0,
      deviceId: 'd',
      events: [
        UserEvent(
          id: 'x',
          title: 'Không nhập',
          type: CalendarType.solar,
          day: 1,
          month: 1,
          createdAt: t0,
          updatedAt: t0,
        ),
      ],
    ).encode();
    await tester.tap(key('backup-import'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.importConfirmTitle(1)), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, Strings.cancel));
    await tester.pumpAndSettle();
    expect(container.read(activeUserEventsProvider), isEmpty);
    expect(find.text(Strings.imported(1)), findsNothing);

    // Xuất nhưng user hủy lưu → không SnackBar "Đã xuất".
    fake.saveResult = false;
    await tester.tap(key('backup-export'));
    await tester.pumpAndSettle();
    expect(fake.saved.length, 1);
    expect(find.text(Strings.exported(0)), findsNothing);
  });
}
