// Cài đặt người dùng trong box `settings` (key-value). Bước 8: lớp hiển thị
// của "Sắp tới" (plan §3.6); bước 14: cảnh báo lưu trữ web. Các cài đặt sau
// (nhắc trước N ngày) thêm ở đây.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'models/event_layer.dart';

/// Đang chạy trên web; test override để bật phần chỉ có trên web.
final platformIsWebProvider = Provider<bool>((_) => kIsWeb);

/// Cảnh báo một lần trên web "Dữ liệu lưu trên trình duyệt này…" (plan §4.4):
/// `true` = còn phải hiện. [dismiss] ghi cờ vào box settings.
class WebNoticeNotifier extends Notifier<bool> {
  static const key = 'webNoticeDismissed';

  @override
  bool build() =>
      ref.watch(platformIsWebProvider) &&
      ref.watch(settingsBoxProvider).get(key) != true;

  Future<void> dismiss() async {
    state = false;
    await ref.read(settingsBoxProvider).put(key, true);
  }
}

/// Có hiện cảnh báo lưu trữ web không.
final webNoticeProvider = NotifierProvider<WebNoticeNotifier, bool>(
  WebNoticeNotifier.new,
);

/// Box `settings` (đã mở) — override trong `main()`; test dùng box in-memory.
final settingsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError(
    'settingsBoxProvider phải được override trong ProviderScope',
  ),
);

/// Lớp đang bật; lưu key `layers` = danh sách tên enum. Mặc định bật hết.
class LayersNotifier extends Notifier<Set<EventLayer>> {
  static const key = 'layers';

  @override
  Set<EventLayer> build() {
    final raw = ref.watch(settingsBoxProvider).get(key);
    if (raw is! List) return EventLayer.values.toSet();
    return {
      for (final v in raw)
        for (final l in EventLayer.values)
          if (l.name == v) l,
    };
  }

  /// Bật ↔ tắt một lớp, ghi ngay vào box.
  Future<void> toggle(EventLayer layer) async {
    final next = {...state};
    if (!next.remove(layer)) next.add(layer);
    state = next;
    await ref.read(settingsBoxProvider).put(key, [
      for (final l in next) l.name,
    ]);
  }
}

/// Lớp sự kiện đang bật ở "Sắp tới".
final layersProvider = NotifierProvider<LayersNotifier, Set<EventLayer>>(
  LayersNotifier.new,
);

/// Mã thiết bị cho `SyncEnvelope.deviceId` (bước 9/12): uuid v4 sinh một lần,
/// lưu key `deviceId` trong box settings.
final deviceIdProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final saved = box.get('deviceId');
  if (saved is String && saved.isNotEmpty) return saved;
  final id = const Uuid().v4();
  box.put('deviceId', id);
  return id;
});
