// State sự kiện cá nhân (plan §3.5): Notifier giữ toàn bộ danh sách (kể cả
// tombstone) đọc từ Hive; mọi thao tác ghi Hive rồi cập nhật state →
// monthProvider (watch activeUserEventsProvider) tự tính lại cache tháng.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'local/user_event_repository.dart';
import 'models/user_event.dart';

/// Repository thật được override trong `main()` (cần box đã mở); test override
/// bằng box in-memory.
final userEventRepositoryProvider = Provider<UserEventRepository>(
  (ref) => throw UnimplementedError(
    'userEventRepositoryProvider phải được override trong ProviderScope',
  ),
);

/// Toàn bộ sự kiện cá nhân, kể cả tombstone.
class UserEventsNotifier extends Notifier<List<UserEvent>> {
  static const _uuid = Uuid();

  @override
  List<UserEvent> build() => ref.watch(userEventRepositoryProvider).all();

  UserEventRepository get _repo => ref.read(userEventRepositoryProvider);

  Future<void> _write(UserEvent e) async {
    await _repo.put(e);
    state = [
      for (final x in state)
        if (x.id != e.id) x,
      e,
    ];
  }

  /// Tạo mới: id uuid v4, `createdAt = updatedAt = now` (UTC).
  Future<UserEvent> create({
    required String title,
    required CalendarType type,
    required int day,
    required int month,
    int? year,
    int durationDays = 1,
    LeapMonthRule leapRule = LeapMonthRule.firstMonth,
    String? note,
    int colorIndex = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final e = UserEvent(
      id: _uuid.v4(),
      title: title,
      type: type,
      day: day,
      month: month,
      year: year,
      durationDays: durationDays,
      leapRule: leapRule,
      note: note,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
    await _write(e);
    return e;
  }

  /// Sửa: ghi [e] với `updatedAt = now`.
  Future<void> update(UserEvent e) =>
      _write(e.copyWith(updatedAt: DateTime.now().toUtc()));

  /// Xóa mềm: `deletedAt = updatedAt = now` (tombstone, D007).
  Future<void> remove(String id) async {
    final e = state.firstWhere((x) => x.id == id);
    final now = DateTime.now().toUtc();
    await _write(e.copyWith(deletedAt: now, updatedAt: now));
  }
}

/// Provider chính (kể cả tombstone — Export/Sync dùng).
final userEventsProvider =
    NotifierProvider<UserEventsNotifier, List<UserEvent>>(
      UserEventsNotifier.new,
    );

/// Sự kiện còn hiệu lực, sắp theo tháng/ngày rồi tên (UI + resolveMonth dùng).
final activeUserEventsProvider = Provider<List<UserEvent>>((ref) {
  final list = ref.watch(userEventsProvider).where((e) => !e.isDeleted).toList()
    ..sort((a, b) {
      final c = a.month.compareTo(b.month);
      if (c != 0) return c;
      final d = a.day.compareTo(b.day);
      return d != 0 ? d : a.title.compareTo(b.title);
    });
  return list;
});

/// Một sự kiện theo id (form sửa), `null` nếu không có / đã xóa.
final userEventByIdProvider = Provider.family<UserEvent?, String>((ref, id) {
  for (final e in ref.watch(userEventsProvider)) {
    if (e.id == id && !e.isDeleted) return e;
  }
  return null;
});
