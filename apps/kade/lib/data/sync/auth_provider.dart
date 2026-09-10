// Trạng thái đăng nhập Google cho UI (Cài đặt → Đồng bộ Google) và cho sync
// (bước 12/13 lấy token qua [AuthNotifier.driveToken]).
import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;

import '../../core/strings.dart';
import '../settings_provider.dart';
import 'google_auth.dart';

/// Trạng thái đăng nhập + quyền Drive.
@immutable
class AuthState {
  const AuthState({
    this.configured = true,
    this.user,
    this.driveGranted = false,
    this.busy = false,
    this.error,
  });

  /// Có Web Client ID; false → mục Đồng bộ chỉ hiện cảnh báo.
  final bool configured;

  final AuthUser? user;

  /// Đã lấy được access token scope drive.appdata trong phiên này (web: token
  /// chỉ sống trong tab, hết hạn 1h — plan §4.4).
  final bool driveGranted;

  /// Đang đăng nhập / xin quyền.
  final bool busy;

  /// Lỗi tiếng Việt lần thao tác gần nhất, `null` nếu không có.
  final String? error;

  bool get signedIn => user != null;
}

/// Đăng nhập / đăng xuất / xin quyền Drive; lưu cờ `googleSignedIn` vào box
/// settings để lần mở sau khôi phục im lặng (plan §3.1).
class AuthNotifier extends Notifier<AuthState> {
  static const signedInKey = 'googleSignedIn';

  GoogleAuth get _auth => ref.read(googleAuthProvider);

  @override
  AuthState build() {
    final auth = ref.watch(googleAuthProvider);
    final box = ref.watch(settingsBoxProvider);
    final sub = auth.userChanges.listen((user) {
      state = AuthState(
        configured: state.configured,
        user: user,
        driveGranted: user != null && state.driveGranted,
      );
      box.put(signedInKey, user != null);
    });
    ref.onDispose(sub.cancel);
    if (auth.isConfigured) {
      unawaited(_init(auth, restore: box.get(signedInKey) == true));
    }
    return AuthState(configured: auth.isConfigured);
  }

  Future<void> _init(GoogleAuth auth, {required bool restore}) async {
    try {
      await auth.init(restore: restore);
    } catch (e) {
      state = AuthState(error: '${Strings.signInFailed} ($e)');
    }
  }

  /// Android: đăng nhập tương tác rồi xin quyền Drive luôn (không cần thao tác
  /// riêng). Web không gọi hàm này — dùng nút GIS, kết quả về qua stream.
  Future<void> signIn() async {
    state = const AuthState(busy: true);
    try {
      final user = await _auth.signIn();
      state = AuthState(user: user, busy: true);
      await ref.read(settingsBoxProvider).put(signedInKey, true);
      final token = await _auth.accessToken(interactive: true);
      state = AuthState(user: user, driveGranted: token != null);
    } on GoogleSignInException catch (e) {
      state = AuthState(
        user: state.user,
        driveGranted: state.driveGranted,
        error: e.code == GoogleSignInExceptionCode.canceled
            ? null
            : Strings.signInError(e.code.name, e.description),
      );
    } catch (e) {
      state = AuthState(
        user: state.user,
        error: '${Strings.signInFailed} ($e)',
      );
    }
  }

  /// Access token Drive cho sync (bước 12). [interactive] có thể mở popup →
  /// trên web chỉ gọi từ thao tác của user. `null` = chưa có quyền / lỗi.
  Future<String?> driveToken({bool interactive = false}) async {
    if (!state.signedIn) return null;
    if (interactive) state = AuthState(user: state.user, busy: true);
    try {
      final token = await _auth.accessToken(interactive: interactive);
      state = AuthState(user: state.user, driveGranted: token != null);
      return token;
    } on GoogleSignInException catch (e) {
      state = AuthState(
        user: state.user,
        error: e.code == GoogleSignInExceptionCode.canceled
            ? null
            : Strings.driveAuthError(e.code.name, e.description),
      );
      return null;
    } catch (e) {
      state = AuthState(user: state.user, error: '${Strings.driveFailed} ($e)');
      return null;
    }
  }

  /// Drive trả 401 với [token] (bước 13): bỏ khỏi cache, `driveGranted` về
  /// false tới khi [driveToken] lấy được token mới.
  Future<void> clearToken(String token) async {
    await _auth.clearToken(token);
    state = AuthState(user: state.user);
  }

  /// Đăng xuất: giữ dữ liệu local, xóa cờ khôi phục.
  Future<void> signOut() async {
    await _auth.signOut();
    await ref.read(settingsBoxProvider).put(signedInKey, false);
    state = const AuthState();
  }
}

/// Trạng thái đăng nhập Google.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
