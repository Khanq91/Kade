// Đăng nhập Google + access token scope drive.appdata (plan §3.10, bước 11).
// google_sign_in 7 tách authentication (ai đăng nhập) và authorization (token
// gọi API) — E003. UI/test chỉ thấy [GoogleAuth]; bản thật bọc GoogleSignIn.
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show immutable, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/env.dart';

/// Scope Drive appDataFolder (D007) — scope duy nhất app xin.
const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Tài khoản Google đã đăng nhập (chỉ phần app cần hiển thị).
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);
}

/// Lớp đăng nhập Google. Bản thật [GoogleSignInAuth]; test dùng fake.
abstract class GoogleAuth {
  /// Có Web Client ID không; false → tắt đồng bộ, UI báo thiếu cấu hình.
  bool get isConfigured;

  /// Web: false → phải dùng nút do GIS vẽ (`platform/sign_in_button.dart`),
  /// kết quả về qua [userChanges].
  bool get supportsAuthenticate;

  /// Sự kiện đăng nhập (user) / đăng xuất (null).
  Stream<AuthUser?> get userChanges;

  /// `initialize()` đúng một lần; [restore] = thử khôi phục phiên im lặng.
  Future<void> init({required bool restore});

  /// Đăng nhập tương tác (Android). Throw [GoogleSignInException] nếu lỗi/hủy.
  Future<AuthUser> signIn();

  /// Đăng xuất (giữ dữ liệu local).
  Future<void> signOut();

  /// Access token có [driveAppDataScope] của user hiện tại: im lặng trước,
  /// [interactive] → hỏi quyền (popup web / consent Android). `null` = chưa
  /// đăng nhập hoặc chưa cấp quyền (khi không interactive).
  Future<String?> accessToken({bool interactive = false});
}

/// Bản thật trên google_sign_in 7.2 (web: google_sign_in_web 1.1 — GIS;
/// Android: google_sign_in_android 7.2 — Credential Manager, minSdk 24).
class GoogleSignInAuth implements GoogleAuth {
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  final _controller = StreamController<AuthUser?>.broadcast();
  GoogleSignInAccount? _current;
  bool _initialized = false;

  @override
  bool get isConfigured => Env.hasWebClientId;

  @override
  bool get supportsAuthenticate => _signIn.supportsAuthenticate();

  @override
  Stream<AuthUser?> get userChanges => _controller.stream;

  @override
  Future<void> init({required bool restore}) async {
    if (_initialized || !isConfigured) return;
    _initialized = true;
    // Web: clientId bắt buộc (thay meta tag trong index.html), serverClientId
    // phải null. Android: serverClientId = Web Client ID (không dùng
    // google-services.json), clientId bị bỏ qua.
    await _signIn.initialize(
      clientId: kIsWeb ? Env.webClientId : null,
      serverClientId: kIsWeb ? null : Env.webClientId,
    );
    _signIn.authenticationEvents.listen(
      _onEvent,
      onError: (Object e) => log('authenticationEvents: $e', name: 'kade.auth'),
    );
    if (restore) {
      // Android: khôi phục tài khoản đã cấp quyền, không UI. Web: One Tap /
      // FedCM, trả null future — kết quả (nếu có) về qua stream.
      await _signIn.attemptLightweightAuthentication();
    }
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        _current = user;
        _controller.add(_toUser(user));
      case GoogleSignInAuthenticationEventSignOut():
        _current = null;
        _controller.add(null);
    }
  }

  static AuthUser _toUser(GoogleSignInAccount a) => AuthUser(
    id: a.id,
    email: a.email,
    displayName: a.displayName,
    photoUrl: a.photoUrl,
  );

  @override
  Future<AuthUser> signIn() async {
    final account = await _signIn.authenticate(
      scopeHint: const [driveAppDataScope],
    );
    _current = account;
    return _toUser(account);
  }

  @override
  Future<void> signOut() async {
    await _signIn.signOut();
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String?> accessToken({bool interactive = false}) async {
    final account = _current;
    if (account == null) return null;
    final client = account.authorizationClient;
    final silent = await client.authorizationForScopes(const [
      driveAppDataScope,
    ]);
    if (silent != null) return silent.accessToken;
    if (!interactive) return null;
    final granted = await client.authorizeScopes(const [driveAppDataScope]);
    return granted.accessToken;
  }
}

/// Override trong `main()` bằng [GoogleSignInAuth]; test override bằng fake.
final googleAuthProvider = Provider<GoogleAuth>(
  (ref) => throw UnimplementedError(
    'googleAuthProvider phải được override trong ProviderScope',
  ),
);
