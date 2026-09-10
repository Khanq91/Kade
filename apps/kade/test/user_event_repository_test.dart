// UserEventRepository trên Hive thật (file trong thư mục temp). Test thuần
// (không testWidgets) nên IO chạy bình thường (E009 chỉ dính FakeAsync).
import 'dart:io';

import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/models/user_event.dart';

void main() {
  late Directory tmp;
  late Box<String> box;
  final t0 = DateTime.utc(2026, 9, 10, 8);

  UserEvent ev(String id, {DateTime? deletedAt}) => UserEvent(
    id: id,
    title: 'Giỗ $id',
    type: CalendarType.lunar,
    day: 15,
    month: 8,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: deletedAt,
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('kade_events_');
    Hive.init(tmp.path);
    box = await Hive.openBox<String>('user_events');
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('put/get/all; đóng rồi mở lại vẫn còn (reload)', () async {
    final repo = UserEventRepository(box);
    expect(repo.all(), isEmpty);
    await repo.put(ev('a'));
    await repo.put(ev('b'));
    expect(repo.all().map((e) => e.id), unorderedEquals(['a', 'b']));
    expect(repo.get('a'), ev('a'));
    expect(repo.get('zzz'), isNull);

    await box.close();
    box = await Hive.openBox<String>('user_events');
    final reopened = UserEventRepository(box);
    expect(reopened.all().map((e) => e.id), unorderedEquals(['a', 'b']));
    expect(reopened.get('b'), ev('b'));
  });

  test('ghi đè theo id; tombstone giữ lại trong all()', () async {
    final repo = UserEventRepository(box);
    await repo.put(ev('a'));
    await repo.put(ev('a', deletedAt: t0));
    expect(repo.all().length, 1);
    expect(repo.get('a')!.isDeleted, isTrue);

    await repo.putAll([ev('b'), ev('c')]);
    expect(repo.all().length, 3);
  });
}
