import 'package:calendar_data/calendar_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/data/month_provider.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:lunar_core/lunar_core.dart';

import 'test_app.dart';

void main() {
  test(
    '2/2027 với overrides asset: sự kiện, ngày nghỉ, DayInfo đúng',
    () async {
      final container = ProviderContainer.test(overrides: fakeRemoteConfig());
      await container.read(remoteConfigProvider.future);
      final m = container.read(monthProvider((2027, 2)));

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
    },
  );

  test('cache theo (year, month); overrides đổi → tính lại', () async {
    final container = ProviderContainer.test(overrides: fakeRemoteConfig());
    await container.read(remoteConfigProvider.future);

    final a = container.read(monthProvider((2027, 2)));
    expect(identical(container.read(monthProvider((2027, 2))), a), isTrue);
    expect(a[DateTime.utc(2027, 2, 9)]!.isOffDay, isTrue);

    final notifier =
        container.read(remoteConfigProvider.notifier) as FakeRemoteConfig;
    notifier.replace(YearOverrides.empty);
    await Future<void>.delayed(Duration.zero);

    final b = container.read(monthProvider((2027, 2)));
    expect(identical(a, b), isFalse);
    expect(b[DateTime.utc(2027, 2, 9)]!.isOffDay, isFalse);
    expect(b[DateTime.utc(2027, 2, 6)]!.isOffDay, isTrue); // Tết vẫn nghỉ
  });

  test('dayCellProvider lấy qua cache tháng', () async {
    final container = ProviderContainer.test(overrides: fakeRemoteConfig());
    await container.read(remoteConfigProvider.future);
    final cell = container.read(dayCellProvider(DateTime.utc(2027, 2, 5)));
    expect(cell.appEvents.single.id, 'giao-thua');
    expect(cell.info.lunar, const LunarDate(day: 29, month: 12, year: 2026));
    expect(
      identical(
        cell,
        container.read(monthProvider((2027, 2)))[DateTime.utc(2027, 2, 5)],
      ),
      isTrue,
    );
  });
}
