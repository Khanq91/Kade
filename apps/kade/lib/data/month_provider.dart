// resolveMonth cấp app (plan §3.2): calendar_data.resolveMonth (sự kiện app +
// ngày nghỉ theo overrides của remote config) + lunar_core.dayInfo cho từng ô.
// Cache theo (year, month) nhờ Provider.family; tính lại khi overrides đổi.
import 'package:calendar_data/calendar_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunar_core/lunar_core.dart';

import 'remote/remote_config_provider.dart';

/// Một ô lịch (plan §2.6): [DayInfo] của engine + sự kiện app + ngày nghỉ.
class DayCell {
  const DayCell({
    required this.info,
    required this.appEvents,
    required this.isOffDay,
  });

  /// Ngày dương, 0h UTC.
  DateTime get date => info.solar;

  /// Âm lịch, can chi, tiết khí, hoàng đạo của ngày.
  final DayInfo info;

  /// Sự kiện app rơi vào ngày này (D020).
  final List<Event> appEvents;

  // `List<UserEvent> userEvents` (đã lọc deletedAt == null) thêm ở bước 7 (D020);
  // khi đó [monthProvider] watch thêm provider sự kiện cá nhân để invalidate cache.

  /// Ngày nghỉ (override `off` / lễ `vnHoliday`, trừ override `work`).
  final bool isOffDay;
}

/// Tháng dương đã resolve; key của [days] là `DateTime.utc(year, month, d)`.
class MonthData {
  const MonthData({
    required this.year,
    required this.month,
    required this.days,
  });

  final int year;
  final int month;
  final Map<DateTime, DayCell> days;

  /// Ô của ngày [d] (chỉ dùng y/m/d), `null` nếu không thuộc tháng này.
  DayCell? operator [](DateTime d) =>
      days[DateTime.utc(d.year, d.month, d.day)];
}

/// Gộp `resolveMonth` + `dayInfo` cho mọi ngày của tháng [year]/[month].
MonthData buildMonth(int year, int month, YearOverrides overrides) {
  final resolved = resolveMonth(year, month, overrides: overrides);
  return MonthData(
    year: year,
    month: month,
    days: {
      for (final e in resolved.entries)
        e.key: DayCell(
          info: dayInfo(e.key),
          appEvents: e.value.appEvents,
          isOffDay: e.value.isOffDay,
        ),
    },
  );
}

/// Overrides đang dùng; rỗng khi remote config chưa load xong. Chỉ đổi khi
/// object overrides đổi (không đổi khi `checking`/`lastResult` đổi).
final overridesProvider = Provider<YearOverrides>((ref) {
  final overrides = ref.watch(
    remoteConfigProvider.select((s) => s.value?.overrides),
  );
  return overrides ?? YearOverrides.empty;
});

/// Tháng đã resolve, cache theo `(year, month)`; tính lại khi [overridesProvider] đổi.
final monthProvider = Provider.family<MonthData, (int year, int month)>((
  ref,
  ym,
) {
  final overrides = ref.watch(overridesProvider);
  return buildMonth(ym.$1, ym.$2, overrides);
});

/// Ô lịch của một ngày, lấy qua cache tháng.
final dayCellProvider = Provider.family<DayCell, DateTime>(
  (ref, d) => ref.watch(monthProvider((d.year, d.month)))[d]!,
);
