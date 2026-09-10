// Trigger sync tự động (plan §3.10, bước 13). Luôn im lặng — không popup;
// sync tương tác chỉ từ nút "Đồng bộ ngay". Chạy khi:
//   (a) có user (khôi phục phiên lúc start / đăng nhập) hoặc vừa có quyền Drive;
//   (b) sự kiện cá nhân đổi (tạo/sửa/xóa/nhập file) → debounce 5s, gộp nhiều lần;
//   (c) app resume sau ≥ 15 phút ở nền.
// Không hẹn giờ khi chưa đăng nhập; không sync chồng (SyncNotifier tự trả busy).
// Resume qua ngày → làm mới `todayProvider` (plan §5.6).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formats.dart';
import '../models/user_event.dart';
import '../upcoming_provider.dart';
import '../user_events_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';

/// Đồng hồ của app; test override để giả thời gian resume.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Chờ sau lần sửa cuối rồi mới sync (gộp nhiều lần sửa liên tiếp).
const syncDebounce = Duration(seconds: 5);

/// Ở nền lâu hơn khoảng này rồi resume → sync.
const syncResumeAfter = Duration(minutes: 15);

/// Nghe auth + sự kiện cá nhân + vòng đời app, gọi `sync()` im lặng.
class SyncTrigger {
  SyncTrigger(this._ref) {
    _seenDate = dateOnly(_now());
    _ref.listen<AuthState>(authProvider, _onAuth);
    _ref.listen<List<UserEvent>>(
      userEventsProvider,
      (_, _) => onEventsChanged(),
    );
    _ref.onDispose(() => _debounce?.cancel());
  }

  final Ref _ref;
  Timer? _debounce;
  bool _foreground = true;
  DateTime? _hiddenAt;
  late DateTime _seenDate;

  /// Số lần trigger đã gọi sync (test).
  int fired = 0;

  /// Đang chờ debounce (test).
  bool get pending => _debounce?.isActive ?? false;

  DateTime _now() => _ref.read(clockProvider)();

  bool get _signedIn => _ref.read(authProvider).signedIn;

  void _onAuth(AuthState? prev, AuthState next) {
    if (!next.signedIn) {
      _debounce?.cancel();
      return;
    }
    if (next.busy) return;
    final appeared = prev?.user == null;
    final granted = next.driveGranted && !(prev?.driveGranted ?? false);
    if (appeared || granted) _fire();
  }

  /// Sự kiện cá nhân vừa đổi: hẹn sync sau [syncDebounce]. Bỏ qua khi chưa
  /// đăng nhập hoặc chính sync đang ghi (`replaceAll`) để không lặp.
  void onEventsChanged() {
    if (!_signedIn || _ref.read(syncProvider).running) return;
    _debounce?.cancel();
    _debounce = Timer(syncDebounce, _fire);
  }

  /// App rời foreground (inactive/hidden/paused): ghi mốc để [onResume] tính.
  void onPause() {
    if (!_foreground) return;
    _foreground = false;
    _hiddenAt = _now();
  }

  /// App về foreground: qua ngày → hôm nay tính lại; ở nền ≥ 15 phút → sync.
  void onResume() {
    final now = _now();
    if (dateOnly(now) != _seenDate) {
      _seenDate = dateOnly(now);
      _ref.invalidate(todayProvider);
    }
    if (_foreground) return;
    _foreground = true;
    final hiddenAt = _hiddenAt;
    if (hiddenAt != null &&
        _signedIn &&
        now.difference(hiddenAt) >= syncResumeAfter) {
      _fire();
    }
  }

  void _fire() {
    _debounce?.cancel();
    fired++;
    unawaited(_ref.read(syncProvider.notifier).sync());
  }
}

/// Tạo một lần lúc app start (`AppLifecycle` trong main.dart) và giữ sống.
final syncTriggerProvider = Provider<SyncTrigger>(SyncTrigger.new);
