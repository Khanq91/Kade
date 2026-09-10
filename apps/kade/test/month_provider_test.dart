import 'package:calendar_data/calendar_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/month_provider.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:lunar_core/lunar_core.dart';

import 'test_app.dart';

void main() {
  Future<ProviderContainer> container() async {
    final c = ProviderContainer.test(overrides: await testOverrides());
    await c.read(remoteConfigProvider.future);
    return c;
  }

  test(
    '2/2027 với overrides asset: sự kiện, ngày nghỉ, DayInfo đúng',
    () async {
      final c = await container();
      final m = c.read(monthProvider((2027, 2)));

      List<String> ids(int d) =>
          m[DateTime.utc(2027, 2, d)]!.appEvents.map((e) => e.id).toList();
      bool off(int d) => m[DateTime.utc(2027, 2, d)]!.isOffDay;

      expect(m.days.length, 28);
      expect(ids(5), ['giao-thua']);
      expect(off(5), isTrue);
      for (final d in [6, 7, 8]) {
        expect(ids(d), ['tet'], reason: 'ngày $d');
        expect(off(d), isTrue, reason: 'ngày $d');
      }
      // 09/02 không có lễ, nghỉ nhờ override `off` của asset.
      expect(ids(9), isEmpty);
      expect(off(9), isTrue);
      expect(ids(14), ['valentine']);
      expect(off(14), isFalse);
      expect(ids(20), ['ram-thang-gieng']);
      expect(off(20), isFalse);

      final tet = m[DateTime.utc(2027, 2, 6)]!;
      expect(tet.info.lunar, const LunarDate(day: 1, month: 1, year: 2027));
      expect(tet.info.canChiYear, 'Đinh Mùi');
      expect(tet.date, DateTime.utc(2027, 2, 6));
      expect(tet.userEvents, isEmpty);
    },
  );

  test('cache theo (year, month); overrides đổi → tính lại', () async {
    final c = await container();

    final a = c.read(monthProvider((2027, 2)));
    expect(identical(c.read(monthProvider((2027, 2))), a), isTrue);
    expect(a[DateTime.utc(2027, 2, 9)]!.isOffDay, isTrue);

    final notifier = c.read(remoteConfigProvider.notifier) as FakeRemoteConfig;
    notifier.replace(YearOverrides.empty);
    await Future<void>.delayed(Duration.zero);

    final b = c.read(monthProvider((2027, 2)));
    expect(identical(a, b), isFalse);
    expect(b[DateTime.utc(2027, 2, 9)]!.isOffDay, isFalse);
    expect(b[DateTime.utc(2027, 2, 6)]!.isOffDay, isTrue); // Tết vẫn nghỉ
  });

  test('dayCellProvider lấy qua cache tháng', () async {
    final c = await container();
    final cell = c.read(dayCellProvider(DateTime.utc(2027, 2, 5)));
    expect(cell.appEvents.single.id, 'giao-thua');
    expect(cell.info.lunar, const LunarDate(day: 29, month: 12, year: 2026));
    expect(
      identical(
        cell,
        c.read(monthProvider((2027, 2)))[DateTime.utc(2027, 2, 5)],
      ),
      isTrue,
    );
  });

  test(
    'sự kiện cá nhân vào DayCell.userEvents; thêm/sửa/xóa → cache tính lại',
    () async {
      final c = await container();
      final before = c.read(monthProvider((2027, 2)));
      final notifier = c.read(userEventsProvider.notifier);

      final e = await notifier.create(
        title: 'Giỗ ông',
        type: CalendarType.lunar,
        day: 1,
        month: 1,
      );
      expect(e.id, isNotEmpty);
      expect(e.createdAt, e.updatedAt);
      final after = c.read(monthProvider((2027, 2)));
      expect(identical(before, after), isFalse);
      expect(
        after[DateTime.utc(2027, 2, 6)]!.userEvents.single.title,
        'Giỗ ông',
      );
      expect(after[DateTime.utc(2027, 2, 7)]!.userEvents, isEmpty);

      await notifier.update(e.copyWith(durationDays: 2, title: 'Giỗ bà'));
      final edited = c.read(monthProvider((2027, 2)));
      expect(
        edited[DateTime.utc(2027, 2, 7)]!.userEvents.single.title,
        'Giỗ bà',
      );
      final stored = c.read(userEventsProvider).single;
      expect(stored.updatedAt.isBefore(stored.createdAt), isFalse);

      await notifier.remove(e.id);
      final removed = c.read(monthProvider((2027, 2)));
      expect(removed[DateTime.utc(2027, 2, 6)]!.userEvents, isEmpty);
      // Tombstone còn trong danh sách đầy đủ, mất khỏi danh sách hiệu lực.
      expect(c.read(userEventsProvider).single.isDeleted, isTrue);
      expect(c.read(activeUserEventsProvider), isEmpty);
      expect(c.read(userEventByIdProvider(e.id)), isNull);
    },
  );

  test('activeUserEventsProvider sắp theo tháng/ngày/tên', () async {
    final c = await container();
    final n = c.read(userEventsProvider.notifier);
    await n.create(title: 'b', type: CalendarType.solar, day: 5, month: 3);
    await n.create(title: 'a', type: CalendarType.solar, day: 5, month: 3);
    await n.create(title: 'c', type: CalendarType.lunar, day: 20, month: 1);
    expect(c.read(activeUserEventsProvider).map((e) => e.title), [
      'c',
      'a',
      'b',
    ]);
    expect(
      c.read(activeUserEventsProvider).first.leapRule,
      LeapMonthRule.firstMonth,
    );
  });
}
