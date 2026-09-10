import 'package:hive_ce_flutter/hive_flutter.dart';

/// Tên box Hive (plan §3.1).
abstract final class HiveBoxes {
  /// Cài đặt người dùng (key-value).
  static const settings = 'settings';

  /// Cache remote config: `json`, `version`, `fetchedAt` (chuỗi).
  static const remoteConfig = 'remote_config';

  /// Sự kiện cá nhân: key = id, value = JSON `UserEvent` (D025, không cần adapter).
  static const userEvents = 'user_events';

  /// Khởi tạo Hive (IndexedDB trên web, file trên Android) và mở box cần lúc start.
  static Future<void> open() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(remoteConfig);
    await Hive.openBox<dynamic>(settings);
    await Hive.openBox<String>(userEvents);
  }
}
