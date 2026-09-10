import 'package:hive_ce_flutter/hive_flutter.dart';

/// Tên box Hive (plan §3.1). `user_events` thêm ở Phase 1 bước 7 (cần adapter).
abstract final class HiveBoxes {
  /// Cài đặt người dùng (key-value).
  static const settings = 'settings';

  /// Cache remote config: `json`, `version`, `fetchedAt` (chuỗi).
  static const remoteConfig = 'remote_config';

  /// Khởi tạo Hive (IndexedDB trên web, file trên Android) và mở box cần lúc start.
  static Future<void> open() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(remoteConfig);
    await Hive.openBox<dynamic>(settings);
  }
}
