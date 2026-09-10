// Thông báo cục bộ (plan §3.8, §5.4): bọc flutter_local_notifications 22 +
// timezone. Web không nhắc (plan §4.6) → [NoopNotifications]. UI/test chỉ
// thấy [Notifications]; scheduler ở `data/reminder_scheduler.dart`.
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/strings.dart';
import '../data/reminders.dart';

/// Lớp thông báo. Bản thật [LocalNotifications]; web [NoopNotifications];
/// test dùng fake.
abstract class Notifications {
  /// Khởi tạo một lần; [onSelect] nhận payload (route) khi user chạm thông
  /// báo, kể cả khi app được mở từ thông báo.
  Future<void> init(void Function(String payload) onSelect);

  /// Xin quyền hiện thông báo (Android 13+). true = được phép.
  Future<bool> requestPermission();

  /// Xóa hết thông báo đã đặt rồi đặt lại [reminders].
  Future<void> schedule(List<Reminder> reminders);
}

/// Web: không có thông báo hẹn giờ.
class NoopNotifications implements Notifications {
  const NoopNotifications();

  @override
  Future<void> init(void Function(String payload) onSelect) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<Reminder> reminders) async {}
}

/// Android: kênh "Nhắc sự kiện", `inexactAllowWhileIdle` (không cần
/// SCHEDULE_EXACT_ALARM), icon launcher.
class LocalNotifications implements Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _android = AndroidNotificationDetails(
    'reminders',
    Strings.notificationChannel,
    channelDescription: Strings.notificationChannelHint,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  Future<void> init(void Function(String payload) onSelect) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.isNotEmpty) onSelect(p);
      },
    );
    // App mở từ thông báo (khi đang tắt) không đi qua callback trên.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final p = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && p != null && p.isNotEmpty) {
      onSelect(p);
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(List<Reminder> reminders) async {
    await _plugin.cancelAll();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        payload: r.payload,
        // Cùng mốc tuyệt đối; Android dùng epoch millis nên không cần tên múi
        // giờ (VN không có DST) → khỏi nạp bảng timezone.
        scheduledDate: tz.TZDateTime.from(r.fireAt, tz.UTC),
        notificationDetails: const NotificationDetails(android: _android),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    log('đã đặt ${reminders.length} thông báo', name: 'kade.notify');
  }
}

/// Override trong `main()` (web: Noop, Android: LocalNotifications); test fake.
final notificationsProvider = Provider<Notifications>(
  (_) => const NoopNotifications(),
);
