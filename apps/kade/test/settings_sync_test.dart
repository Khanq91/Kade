// Cài đặt → "Đồng bộ Google" (bước 11–12) với GoogleAuth + DriveStore giả:
// Android-like nút "Đồng bộ với Google" → email + đã cấp quyền → "Đồng bộ
// ngay" → SnackBar + lần cuối → Đăng xuất; web-like nút GIS (stub ngoài web)
// → sự kiện → "Đồng bộ ngay" xin quyền trong cùng thao tác; chưa cấu hình → cảnh báo.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/sync/drive_store.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/features/settings/settings_screen.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testTall('Android-like: đăng nhập → quyền Drive → Đồng bộ ngay → đăng xuất', (
    tester,
  ) async {
    final fake = FakeGoogleAuth();
    final store = FakeDriveStore();
    await tester.pumpWidget(
      await testApp('/settings', googleAuth: fake, driveStore: store),
    );
    await tester.pumpAndSettle();
    expect(find.text(Strings.syncSection), findsOneWidget);
    expect(key('sync-signin'), findsOneWidget);
    expect(key('sync-signout'), findsNothing);
    expect(key('sync-now'), findsNothing);

    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn A'), findsOneWidget);
    expect(find.text('a@gmail.com'), findsOneWidget);
    expect(find.text(Strings.driveGranted), findsOneWidget);
    expect(key('sync-signin'), findsNothing);
    expect(fake.interactiveCalls, 1);
    // Bước 13: vừa có quyền Drive → trigger sync im lặng luôn.
    expect(store.calls, ['find', 'create']);
    expect(find.textContaining('Đồng bộ lần cuối:'), findsOneWidget);
    expect(find.text(Strings.neverSynced), findsNothing);

    await tester.tap(key('sync-now'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.syncDone), findsOneWidget);
    expect(store.calls, ['find', 'create', 'find']);

    await tester.tap(key('sync-signout'));
    await tester.pumpAndSettle();
    expect(key('sync-signin'), findsOneWidget);
    expect(find.text('a@gmail.com'), findsNothing);
  });

  testTall(
    'Android-like: lỗi cấu hình → hiện lỗi, vẫn ở trạng thái chưa đăng nhập',
    (tester) async {
      final fake = FakeGoogleAuth()
        ..signInError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'DEVELOPER_ERROR',
        );
      await tester.pumpWidget(await testApp('/settings', googleAuth: fake));
      await tester.pumpAndSettle();
      await tester.tap(key('sync-signin'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(key('sync-error')).data,
        contains('DEVELOPER_ERROR'),
      );
      expect(key('sync-signin'), findsOneWidget);
    },
  );

  testTall(
    'web-like: không có nút app; sự kiện GIS → Đồng bộ ngay xin quyền + sync',
    (tester) async {
      final fake = FakeGoogleAuth(supportsAuthenticate: false);
      final store = FakeDriveStore();
      await tester.pumpWidget(
        await testApp('/settings', googleAuth: fake, driveStore: store),
      );
      await tester.pumpAndSettle();
      expect(key('sync-signin'), findsNothing);
      expect(key('sync-now'), findsNothing);

      fake.emitSignIn(fake.signInUser);
      await tester.pumpAndSettle();
      expect(find.text('a@gmail.com'), findsOneWidget);
      expect(find.text(Strings.driveNotGranted), findsOneWidget);
      expect(key('sync-now'), findsOneWidget);

      await tester.tap(key('sync-now'));
      await tester.pumpAndSettle();
      expect(fake.interactiveCalls, 1);
      expect(find.text(Strings.driveGranted), findsOneWidget);
      expect(find.text(Strings.syncDone), findsOneWidget);
      expect(store.calls, ['find', 'create']);
    },
  );

  testTall('Drive lỗi → SnackBar + dòng lỗi trong mục', (tester) async {
    final fake = FakeGoogleAuth();
    final store = FakeDriveStore()
      ..error = DriveException(403, 'Drive API has not been used');
    await tester.pumpWidget(
      await testApp('/settings', googleAuth: fake, driveStore: store),
    );
    await tester.pumpAndSettle();
    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    // Sync nền sau đăng nhập lỗi → chỉ dòng lỗi trong mục, không SnackBar.
    expect(find.textContaining('Drive 403'), findsOneWidget);
    await tester.tap(key('sync-now'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Drive 403'),
      findsNWidgets(2),
    ); // SnackBar + mục
    expect(key('sync-now'), findsOneWidget);
  });

  testTall('Xóa dữ liệu trên Drive: dialog → xóa file + đăng xuất, local còn', (
    tester,
  ) async {
    final fake = FakeGoogleAuth();
    final store = FakeDriveStore();
    final box = await memoryUserEventsBox();
    await tester.pumpWidget(
      await testApp(
        '/settings',
        googleAuth: fake,
        driveStore: store,
        userEventsBox: box,
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    await container
        .read(userEventsProvider.notifier)
        .create(title: 'Giỗ ông', type: CalendarType.lunar, day: 15, month: 8);
    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    expect(store.file, isNotNull);

    await tester.tap(key('sync-delete-remote'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteRemoteTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, Strings.cancel));
    await tester.pumpAndSettle();
    expect(store.file, isNotNull);

    await tester.tap(key('sync-delete-remote'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, Strings.delete));
    await tester.pumpAndSettle();
    expect(store.calls.last, 'delete');
    expect(store.file, isNull);
    expect(find.text(Strings.deleteRemoteDone), findsOneWidget);
    expect(key('sync-signin'), findsOneWidget); // đã đăng xuất
    expect(key('sync-delete-remote'), findsNothing);
    expect(UserEventRepository(box).all().single.title, 'Giỗ ông');
  });

  testTall('chưa cấu hình KADE_WEB_CLIENT_ID → cảnh báo, không nút', (
    tester,
  ) async {
    await tester.pumpWidget(
      await testApp(
        '/settings',
        googleAuth: FakeGoogleAuth(isConfigured: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Strings.noWebClientId), findsOneWidget);
    expect(key('sync-signin'), findsNothing);
    expect(key('sync-now'), findsNothing);
  });
}
