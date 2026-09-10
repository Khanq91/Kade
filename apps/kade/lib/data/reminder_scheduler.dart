// Đặt lại thông báo (plan §5.4, bước 16): lúc start, khi sự kiện cá nhân đổi
// (tạo/sửa/xóa/nhập file/sync `replaceAll`), khi "Nhắc lễ trước N ngày" đổi,
// khi app resume (có thể đã qua ngày). Các lần đặt chạy tuần tự để
// cancelAll/schedule không chồng nhau.
import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/notifications.dart';
import 'models/user_event.dart';
import 'reminders.dart';
import 'settings_provider.dart';
import 'sync/sync_trigger.dart';
import 'user_events_provider.dart';

class ReminderScheduler {
  ReminderScheduler(this._ref) {
    _ref.listen<List<UserEvent>>(userEventsProvider, (_, _) => reschedule());
    _ref.listen<int>(holidayRemindDaysProvider, (_, _) => reschedule());
  }

  final Ref _ref;
  Future<void> _chain = Future.value();

  /// Số lần đã đặt và danh sách gần nhất (test).
  int runs = 0;
  List<Reminder> last = const [];

  /// Lúc app start: khởi tạo plugin (chạm thông báo → [onSelect] route) rồi
  /// đặt lần đầu. Không xin quyền ở đây (plan §5.4).
  Future<void> start(void Function(String payload) onSelect) async {
    try {
      await _ref.read(notificationsProvider).init(onSelect);
    } catch (e) {
      log('init thông báo lỗi: $e', name: 'kade.notify');
    }
    await reschedule();
  }

  /// Tính lại từ dữ liệu hiện tại và đặt lại toàn bộ.
  Future<void> reschedule() {
    _chain = _chain.then((_) => _run());
    return _chain;
  }

  /// Xin quyền — gọi khi user bật nhắc (form sự kiện / Cài đặt).
  Future<bool> requestPermission() =>
      _ref.read(notificationsProvider).requestPermission();

  Future<void> _run() async {
    final reminders = buildReminders(
      events: _ref.read(userEventsProvider),
      now: _ref.read(clockProvider)(),
      holidayRemindDays: _ref.read(holidayRemindDaysProvider),
    );
    last = reminders;
    runs++;
    try {
      await _ref.read(notificationsProvider).schedule(reminders);
    } catch (e) {
      log('đặt thông báo lỗi: $e', name: 'kade.notify');
    }
  }
}

/// Tạo lúc app start (`AppLifecycle`), giữ sống.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);
