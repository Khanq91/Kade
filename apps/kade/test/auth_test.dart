// Đăng nhập Google (plan §6 bước 11) qua GoogleAuth giả: init theo cờ
// settings, signIn Android-like (user + quyền Drive + cờ), hủy / lỗi cấu
// hình, web-like (sự kiện nút GIS → Cấp quyền Drive), signOut.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kade/data/sync/auth_provider.dart';

import 'test_app.dart';

void main() {
  /// Cho listener stream / init chạy.
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test(
    'build: init(restore) theo cờ googleSignedIn trong box settings',
    () async {
      final fake1 = FakeGoogleAuth();
      final c1 = ProviderContainer.test(
        overrides: await testOverrides(googleAuth: fake1),
      );
      expect(c1.read(authProvider).signedIn, isFalse);
      expect(c1.read(authProvider).configured, isTrue);
      await tick();
      expect(fake1.initRestore, isFalse);

      final box = await memorySettingsBox();
      await box.put(AuthNotifier.signedInKey, true);
      final fake2 = FakeGoogleAuth();
      final c2 = ProviderContainer.test(
        overrides: await testOverrides(googleAuth: fake2, settingsBox: box),
      );
      c2.read(authProvider);
      await tick();
      expect(fake2.initRestore, isTrue);

      // Khôi phục im lặng → sự kiện từ stream → state có user.
      fake2.emitSignIn(fake2.signInUser);
      await tick();
      expect(c2.read(authProvider).user?.email, 'a@gmail.com');
      expect(c2.read(authProvider).driveGranted, isFalse);
    },
  );

  test('chưa cấu hình client ID → configured false, không init', () async {
    final fake = FakeGoogleAuth(isConfigured: false);
    final c = ProviderContainer.test(
      overrides: await testOverrides(googleAuth: fake),
    );
    expect(c.read(authProvider).configured, isFalse);
    await tick();
    expect(fake.initRestore, isNull);
  });

  test(
    'signIn (Android): user + token Drive tương tác + cờ settings',
    () async {
      final box = await memorySettingsBox();
      final fake = FakeGoogleAuth();
      final c = ProviderContainer.test(
        overrides: await testOverrides(googleAuth: fake, settingsBox: box),
      );
      await c.read(authProvider.notifier).signIn();
      final s = c.read(authProvider);
      expect(s.user, fake.signInUser);
      expect(s.driveGranted, isTrue);
      expect(s.busy, isFalse);
      expect(s.error, isNull);
      expect(fake.interactiveCalls, 1);
      expect(box.get(AuthNotifier.signedInKey), isTrue);

      // Có token rồi → lần sau im lặng, không hỏi lại.
      fake.silentToken = 'tok-silent';
      expect(await c.read(authProvider.notifier).driveToken(), 'tok-silent');
      expect(fake.interactiveCalls, 1);

      await c.read(authProvider.notifier).signOut();
      await tick();
      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(authProvider).driveGranted, isFalse);
      expect(box.get(AuthNotifier.signedInKey), isFalse);
      expect(await c.read(authProvider.notifier).driveToken(), isNull);
    },
  );

  test('signIn hủy → không lỗi; lỗi cấu hình → error có code', () async {
    final fake = FakeGoogleAuth();
    final c = ProviderContainer.test(
      overrides: await testOverrides(googleAuth: fake),
    );
    final notifier = c.read(authProvider.notifier);

    fake.signInError = const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );
    await notifier.signIn();
    expect(c.read(authProvider).signedIn, isFalse);
    expect(c.read(authProvider).error, isNull);
    expect(c.read(authProvider).busy, isFalse);

    fake.signInError = const GoogleSignInException(
      code: GoogleSignInExceptionCode.clientConfigurationError,
      description: 'SHA-1?',
    );
    await notifier.signIn();
    final err = c.read(authProvider).error!;
    expect(err, contains('clientConfigurationError'));
    expect(err, contains('SHA-1?'));
  });

  test(
    'web-like: sự kiện GIS → user chưa quyền; driveToken(interactive) → có; lỗi',
    () async {
      final fake = FakeGoogleAuth(supportsAuthenticate: false);
      final c = ProviderContainer.test(
        overrides: await testOverrides(googleAuth: fake),
      );
      c.read(authProvider);
      fake.emitSignIn(fake.signInUser);
      await tick();
      expect(c.read(authProvider).signedIn, isTrue);
      expect(c.read(authProvider).driveGranted, isFalse);
      // Im lặng chưa có → null, không lỗi.
      expect(await c.read(authProvider.notifier).driveToken(), isNull);
      expect(c.read(authProvider).error, isNull);

      fake.authorizeError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'popup blocked',
      );
      expect(
        await c.read(authProvider.notifier).driveToken(interactive: true),
        isNull,
      );
      expect(c.read(authProvider).error, contains('popup blocked'));
      expect(c.read(authProvider).signedIn, isTrue);

      fake.authorizeError = null;
      expect(
        await c.read(authProvider.notifier).driveToken(interactive: true),
        'tok-1',
      );
      expect(c.read(authProvider).driveGranted, isTrue);
      expect(c.read(authProvider).error, isNull);
    },
  );
}
