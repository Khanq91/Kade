// Trigger sync tự động (bước 13) qua app thật + fake: sau đăng nhập; debounce
// 5s gộp nhiều lần sửa; chưa đăng nhập không hẹn giờ; khởi động khôi phục
// phiên (Android sync, web không popup); nhận từ Drive không sync lặp; resume
// < 15' không sync, ≥ 15' sync, qua ngày todayProvider mới; 401 ở sync nền →
// bỏ token, không popup, "Phiên Google hết hạn"; nút xin lại rồi thành công.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/formats.dart';
import 'package:kade/core/router.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/models/sync_envelope.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/sync/auth_provider.dart';
import 'package:kade/data/sync/drive_store.dart';
import 'package:kade/data/sync/sync_trigger.dart';
import 'package:kade/data/upcoming_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/main.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(AppLifecycle)));

  List<UserEvent> remoteEvents(FakeDriveStore store) =>
      (SyncEnvelope.parse(store.file!.content) as EnvelopeOk).envelope.events;

  Future<UserEvent> createEvent(ProviderContainer c, String title) => c
      .read(userEventsProvider.notifier)
      .create(title: title, type: CalendarType.solar, day: 1, month: 1);

  testTall('đăng nhập → tự sync; sửa sự kiện → sync sau 5s, gộp nhiều lần', (
    tester,
  ) async {
    final fake = FakeGoogleAuth();
    final store = FakeDriveStore();
    await tester.pumpWidget(
      await testApp('/settings', googleAuth: fake, driveStore: store),
    );
    await tester.pumpAndSettle();
    expect(store.calls, isEmpty);

    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    // (d) ngay sau đăng nhập + quyền Drive, không cần bấm "Đồng bộ ngay".
    expect(store.calls, ['find', 'create']);
    expect(find.textContaining('Đồng bộ lần cuối:'), findsOneWidget);

    final c = containerOf(tester);
    final trigger = c.read(syncTriggerProvider);
    final notifier = c.read(userEventsProvider.notifier);
    final e = await createEvent(c, 'A');
    await notifier.update(e.copyWith(title: 'B'));
    expect(trigger.pending, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(store.calls.length, 2); // chưa tới 5s
    await notifier.remove(e.id); // sửa tiếp → đếm lại từ đầu
    await tester.pump(const Duration(seconds: 3));
    expect(store.calls.length, 2); // 6s từ lần đầu, mới 3s từ lần cuối
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(trigger.pending, isFalse);
    // Một lần sync cho cả 3 thao tác; Drive nhận tombstone.
    expect(store.calls, ['find', 'create', 'find', 'update']);
    expect(remoteEvents(store).single.isDeleted, isTrue);
  });

  testTall('chưa đăng nhập: sửa sự kiện không hẹn sync', (tester) async {
    final store = FakeDriveStore();
    await tester.pumpWidget(await testApp('/settings', driveStore: store));
    await tester.pumpAndSettle();
    final c = containerOf(tester);
    await createEvent(c, 'A');
    expect(c.read(syncTriggerProvider).pending, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(store.calls, isEmpty);
  });

  testTall(
    'khởi động đã đăng nhập: khôi phục im lặng → sync (Android); web không token → không popup',
    (tester) async {
      final box = await memorySettingsBox();
      await box.put(AuthNotifier.signedInKey, true);
      final fake = FakeGoogleAuth()..silentToken = 'tok';
      final store = FakeDriveStore();
      // Mở màn lịch (không phải Cài đặt): trigger sống ở gốc app.
      await tester.pumpWidget(
        await testApp(
          '/2027/02',
          settingsBox: box,
          googleAuth: fake,
          driveStore: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(fake.initRestore, isTrue);
      fake.emitSignIn(fake.signInUser); // attemptLightweightAuthentication về
      await tester.pumpAndSettle();
      expect(store.calls, ['find', 'create']);
      expect(store.tokens, ['tok', 'tok']);

      final web = FakeGoogleAuth(supportsAuthenticate: false);
      final store2 = FakeDriveStore();
      await tester.pumpWidget(
        await testApp(
          '/2027/02',
          settingsBox: box,
          googleAuth: web,
          driveStore: store2,
        ),
      );
      await tester.pumpAndSettle();
      web.emitSignIn(web.signInUser);
      await tester.pumpAndSettle();
      expect(store2.calls, isEmpty);
      expect(web.interactiveCalls, 0);
    },
  );

  testTall('nhận thay đổi từ Drive không gây sync lặp', (tester) async {
    final fake = FakeGoogleAuth()..silentToken = 'tok';
    final remote = UserEvent(
      id: 'r',
      title: 'Từ Drive',
      type: CalendarType.lunar,
      day: 15,
      month: 8,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final store = FakeDriveStore()
      ..file = RemoteFile(
        id: 'f1',
        content: SyncEnvelope(
          exportedAt: DateTime.utc(2026, 9, 1),
          deviceId: 'other',
          events: [remote],
        ).encode(),
      );
    await tester.pumpWidget(
      await testApp('/settings', googleAuth: fake, driveStore: store),
    );
    await tester.pumpAndSettle();
    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    expect(store.calls, ['find']);
    expect(
      containerOf(tester).read(activeUserEventsProvider).single.title,
      'Từ Drive',
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(store.calls, ['find']); // replaceAll của sync không hẹn sync mới
  });

  testTall(
    'resume: < 15 phút không sync; ≥ 15 phút sync; qua ngày → hôm nay mới',
    (tester) async {
      var now = DateTime(2026, 9, 10, 23, 50);
      final fake = FakeGoogleAuth()..silentToken = 'tok';
      final store = FakeDriveStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await testOverrides(
              googleAuth: fake,
              driveStore: store,
              clock: () => now,
            ),
            todayProvider.overrideWith(
              (ref) => dateOnly(ref.read(clockProvider)()),
            ),
          ],
          child: KadeApp(router: createRouter(initialLocation: '/settings')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(key('sync-signin'));
      await tester.pumpAndSettle();
      expect(store.calls, ['find', 'create']);
      final c = containerOf(tester);
      expect(c.read(todayProvider), DateTime.utc(2026, 9, 10));

      await sendLifecycle(tester, AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      await sendLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.calls.length, 2); // < 15 phút: không sync
      expect(c.read(todayProvider), DateTime.utc(2026, 9, 10));

      await sendLifecycle(tester, AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 20)); // 00:15 hôm sau
      await sendLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.calls, ['find', 'create', 'find']);
      expect(c.read(todayProvider), DateTime.utc(2026, 9, 11));

      // Chưa đăng nhập → resume lâu cũng không sync.
      await tester.tap(key('sync-signout'));
      await tester.pumpAndSettle();
      await sendLifecycle(tester, AppLifecycleState.paused);
      now = now.add(const Duration(hours: 1));
      await sendLifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.calls.length, 3);
    },
  );

  testTall(
    '401 ở sync nền (web): bỏ token, không popup, "Phiên Google hết hạn"; nút xin lại',
    (tester) async {
      final fake = FakeGoogleAuth(supportsAuthenticate: false)
        ..silentToken = 'tok-old';
      final store = FakeDriveStore()..badTokens.add('tok-old');
      await tester.pumpWidget(
        await testApp('/settings', googleAuth: fake, driveStore: store),
      );
      await tester.pumpAndSettle();
      fake.emitSignIn(fake.signInUser);
      await tester.pumpAndSettle();
      expect(store.calls, ['find']);
      expect(fake.clearedTokens, ['tok-old']);
      expect(fake.interactiveCalls, 0);
      expect(
        tester.widget<Text>(key('sync-error')).data,
        Strings.syncSessionExpired,
      );
      expect(find.text(Strings.driveNotGranted), findsOneWidget);

      await tester.tap(key('sync-now'));
      await tester.pumpAndSettle();
      expect(fake.interactiveCalls, 1);
      expect(store.calls, ['find', 'find', 'create']);
      expect(store.tokens.last, 'tok-1');
      expect(find.text(Strings.syncDone), findsOneWidget);
      expect(key('sync-error'), findsNothing);
      expect(find.text(Strings.driveGranted), findsOneWidget);
    },
  );
}
