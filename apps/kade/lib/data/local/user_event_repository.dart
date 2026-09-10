// Lưu UserEvent trong box Hive `user_events`: key = id, value = JSON string
// (D025). Không xóa cứng — xóa = ghi bản có `deletedAt` (tombstone, D007).
import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../models/user_event.dart';

/// Đọc/ghi box `user_events`. Không giữ state UI.
class UserEventRepository {
  UserEventRepository(this.box);

  /// Box `user_events` (đã mở).
  final Box<String> box;

  /// Mọi sự kiện kể cả tombstone (sync/export cần tombstone).
  List<UserEvent> all() => [
    for (final v in box.values)
      UserEvent.fromJson(jsonDecode(v) as Map<String, dynamic>),
  ];

  /// Sự kiện theo [id], hoặc `null`.
  UserEvent? get(String id) {
    final v = box.get(id);
    return v == null
        ? null
        : UserEvent.fromJson(jsonDecode(v) as Map<String, dynamic>);
  }

  /// Ghi đè theo `id` (tạo mới, sửa, hay tombstone đều đi qua đây).
  Future<void> put(UserEvent e) => box.put(e.id, jsonEncode(e.toJson()));

  /// Ghi nhiều sự kiện một lần (import/sync).
  Future<void> putAll(Iterable<UserEvent> events) =>
      box.putAll({for (final e in events) e.id: jsonEncode(e.toJson())});

  /// Thay toàn bộ box bằng [events] (kết quả merge sync): ghi đè theo id và
  /// xóa cứng key không còn — tombstone đã purge > 90 ngày, ngoại lệ duy nhất
  /// của "không xóa cứng" (D007, D030).
  Future<void> replaceAll(Iterable<UserEvent> events) async {
    final keep = {for (final e in events) e.id};
    final gone = [
      for (final k in box.keys)
        if (!keep.contains(k)) k,
    ];
    if (gone.isNotEmpty) await box.deleteAll(gone);
    await putAll(events);
  }
}
