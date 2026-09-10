// Merge sự kiện local ↔ remote theo id (plan §3.10, D007): last-write-wins
// theo `updatedAt`, tombstone cũng là một bản. Pure Dart để test 4 case.
import '../models/user_event.dart';

/// Tombstone có `deletedAt` cũ hơn ngưỡng này bị xóa cứng sau khi sync (D007).
const tombstoneTtl = Duration(days: 90);

/// Gộp [local] và [remote]: chỉ một bên có → lấy bên đó; cả hai → bản có
/// `updatedAt` lớn hơn; bằng nhau → local. Kết quả sắp theo id.
List<UserEvent> mergeEvents(
  Iterable<UserEvent> local,
  Iterable<UserEvent> remote,
) {
  final out = {for (final e in local) e.id: e};
  for (final r in remote) {
    final l = out[r.id];
    if (l == null || r.updatedAt.isAfter(l.updatedAt)) out[r.id] = r;
  }
  return sortedById(out.values);
}

/// Bỏ tombstone có `deletedAt` trước [now] − [ttl] (purge sau sync, D007).
List<UserEvent> purgeTombstones(
  Iterable<UserEvent> events,
  DateTime now, {
  Duration ttl = tombstoneTtl,
}) {
  final cutoff = now.subtract(ttl);
  return sortedById(
    events.where((e) {
      final d = e.deletedAt;
      return d == null || !d.isBefore(cutoff);
    }),
  );
}

/// Hai danh sách có cùng tập sự kiện (so theo id và nội dung)?
bool sameEvents(Iterable<UserEvent> a, Iterable<UserEvent> b) {
  final ma = {for (final e in a) e.id: e};
  final mb = {for (final e in b) e.id: e};
  if (ma.length != mb.length) return false;
  for (final entry in ma.entries) {
    if (mb[entry.key] != entry.value) return false;
  }
  return true;
}

/// Sắp theo id để so sánh / ghi file ổn định.
List<UserEvent> sortedById(Iterable<UserEvent> events) =>
    events.toList()..sort((a, b) => a.id.compareTo(b.id));
