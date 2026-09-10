// Merge sync (plan §6 bước 12): 4 case — chỉ local / chỉ remote / cả 2 local
// mới hơn / tombstone thắng — thêm bằng nhau → local, và purge tombstone > 90 ngày.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/sync/merge.dart';

final _t1 = DateTime.utc(2026, 9, 1);
final _t2 = DateTime.utc(2026, 9, 2);

UserEvent _ev(
  String id, {
  String title = 't',
  required DateTime updatedAt,
  DateTime? deletedAt,
}) => UserEvent(
  id: id,
  title: title,
  type: CalendarType.solar,
  day: 1,
  month: 1,
  createdAt: _t1,
  updatedAt: updatedAt,
  deletedAt: deletedAt,
);

void main() {
  test('chỉ local có → giữ local; chỉ remote có → lấy remote', () {
    final a = _ev('a', updatedAt: _t1);
    final b = _ev('b', updatedAt: _t1);
    expect(mergeEvents([a], [b]), [a, b]);
    expect(mergeEvents([], [b]), [b]);
    expect(mergeEvents([a], []), [a]);
  });

  test('cả 2 có: updatedAt lớn hơn thắng, cả hai chiều', () {
    final oldL = _ev('a', title: 'local', updatedAt: _t1);
    final newR = _ev('a', title: 'remote', updatedAt: _t2);
    expect(mergeEvents([oldL], [newR]).single.title, 'remote');
    final newL = _ev('a', title: 'local', updatedAt: _t2);
    final oldR = _ev('a', title: 'remote', updatedAt: _t1);
    expect(mergeEvents([newL], [oldR]).single.title, 'local');
  });

  test('bằng nhau → giữ local', () {
    final l = _ev('a', title: 'local', updatedAt: _t1);
    final r = _ev('a', title: 'remote', updatedAt: _t1);
    expect(mergeEvents([l], [r]).single.title, 'local');
  });

  test('tombstone thắng khi mới hơn; bản sống mới hơn thắng tombstone cũ', () {
    final live = _ev('a', updatedAt: _t1);
    final tomb = _ev('a', updatedAt: _t2, deletedAt: _t2);
    expect(mergeEvents([live], [tomb]).single.isDeleted, isTrue);
    expect(mergeEvents([tomb], [live]).single.isDeleted, isTrue);
    final revived = _ev('a', updatedAt: _t2.add(const Duration(days: 1)));
    expect(mergeEvents([tomb], [revived]).single.isDeleted, isFalse);
  });

  test('purge: tombstone quá 90 ngày bị bỏ, còn lại giữ; sắp theo id', () {
    final now = DateTime.utc(2026, 12, 31);
    final old = _ev(
      'old',
      updatedAt: _t1,
      deletedAt: now.subtract(const Duration(days: 91)),
    );
    final recent = _ev(
      'recent',
      updatedAt: _t1,
      deletedAt: now.subtract(const Duration(days: 89)),
    );
    final live = _ev('a', updatedAt: _t1);
    expect(purgeTombstones([recent, old, live], now), [live, recent]);
  });

  test('sameEvents so theo id + nội dung, không theo thứ tự', () {
    final a = _ev('a', updatedAt: _t1);
    final b = _ev('b', updatedAt: _t1);
    expect(sameEvents([a, b], [b, a]), isTrue);
    expect(sameEvents([a], [a, b]), isFalse);
    expect(sameEvents([a], [a.copyWith(title: 'x')]), isFalse);
  });
}
