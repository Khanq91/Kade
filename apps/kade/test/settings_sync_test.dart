// Cài đặt → "Đồng bộ Google" (bước 11) với GoogleAuth giả: Android-like nút
// "Đồng bộ với Google" → email + đã cấp quyền → Đăng xuất; web-like nút GIS
// (stub ngoài web) → sự kiện → "Cấp quyền Drive"; chưa cấu hình → cảnh báo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kade/core/strings.dart';

import 'test_app.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testTall('Android-like: đăng nhập → email + quyền Drive → đăng xuất', (
    tester,
  ) async {
    final fake = FakeGoogleAuth();
    await tester.pumpWidget(await testApp('/settings', googleAuth: fake));
    await tester.pumpAndSettle();
    expect(find.text(Strings.syncSection), findsOneWidget);
    expect(key('sync-signin'), findsOneWidget);
    expect(key('sync-signout'), findsNothing);

    await tester.tap(key('sync-signin'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn A'), findsOneWidget);
    expect(find.text('a@gmail.com'), findsOneWidget);
    expect(find.text(Strings.driveGranted), findsOneWidget);
    expect(key('sync-grant'), findsNothing);
    expect(key('sync-signin'), findsNothing);
    expect(fake.interactiveCalls, 1);

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
    'web-like: không có nút app; sự kiện GIS → Cấp quyền Drive → đã cấp',
    (tester) async {
      final fake = FakeGoogleAuth(supportsAuthenticate: false);
      await tester.pumpWidget(await testApp('/settings', googleAuth: fake));
      await tester.pumpAndSettle();
      expect(key('sync-signin'), findsNothing);

      fake.emitSignIn(fake.signInUser);
      await tester.pumpAndSettle();
      expect(find.text('a@gmail.com'), findsOneWidget);
      expect(find.text(Strings.driveNotGranted), findsOneWidget);
      expect(key('sync-grant'), findsOneWidget);

      await tester.tap(key('sync-grant'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.driveGranted), findsOneWidget);
      expect(key('sync-grant'), findsNothing);
      expect(fake.interactiveCalls, 1);
    },
  );

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
    expect(key('sync-grant'), findsNothing);
  });
}
