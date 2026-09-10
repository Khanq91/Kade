// resolveMonth — phần sự kiện app + ngày nghỉ (plan §3.2). Sự kiện cá nhân
// (UserEvent, Hive) do app gộp thêm ở Phase 1 bước 7 (D020).
import 'package:lunar_core/lunar_core.dart';

import 'event.dart';
import 'events.dart';
import 'year_override.dart';

/// Kết quả cho 1 ô lịch (plan §2.6, chưa có `userEvents` — app gộp sau).
class DayEvents {
  /// Tạo trực tiếp; thường lấy từ [resolveMonth].
  const DayEvents({
    required this.date,
    required this.appEvents,
    required this.isOffDay,
  });

  /// Ngày dương, 0h UTC.
  final DateTime date;

  /// Sự kiện app rơi vào ngày này (kể cả ngày thứ 2, 3 của sự kiện nhiều ngày).
  final List<Event> appEvents;

  /// Ngày nghỉ: override `off`, hoặc có lễ `vnHoliday`; override `work` thắng tất cả.
  final bool isOffDay;
}

/// Sự kiện app rơi vào ngày [date] (chỉ dùng y/m/d), theo thứ tự trong [events].
///
/// Sự kiện âm chỉ tính theo tháng chính, không tính tháng nhuận (D020).
List<Event> eventsOn(DateTime date, {List<Event> events = allEvents}) {
  final d = DateTime.utc(date.year, date.month, date.day);
  var maxDuration = 1;
  for (final e in events) {
    if (e.durationDays > maxDuration) maxDuration = e.durationDays;
  }
  // starts[k] = ngày d - k (ngày bắt đầu nếu hôm nay là ngày thứ k+1 của sự kiện).
  final starts = List.generate(
    maxDuration,
    (k) => d.subtract(Duration(days: k)),
  );
  final lunars = <LunarDate?>[for (var k = 0; k < maxDuration; k++) null];
  final result = <Event>[];
  for (final e in events) {
    for (var k = 0; k < e.durationDays; k++) {
      final bool match;
      if (e.type == CalendarType.solar) {
        match = e.startsOnSolar(starts[k]);
      } else {
        final l = lunars[k] ??= solarToLunar(starts[k]);
        match = l.month == e.month && l.day == e.day && !l.isLeapMonth;
      }
      if (match) {
        result.add(e);
        break;
      }
    }
  }
  return result;
}

/// Ngày nghỉ hay không theo plan §3.2:
/// `(off.contains(date) || có vnHoliday) && !work.contains(date)`.
bool isOffDay(DateTime date, List<Event> appEvents, YearOverride? override) {
  if (override != null && override.work.contains(date)) return false;
  if (override != null && override.off.contains(date)) return true;
  return appEvents.any((e) => e.kind == EventKind.vnHoliday);
}

/// Sự kiện app + ngày nghỉ cho mọi ngày của tháng dương [year]/[month].
/// Key là `DateTime.utc(year, month, d)`.
Map<DateTime, DayEvents> resolveMonth(
  int year,
  int month, {
  YearOverrides overrides = YearOverrides.empty,
  List<Event> events = allEvents,
}) {
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  final override = overrides.forYear(year);
  final result = <DateTime, DayEvents>{};
  for (var d = 1; d <= daysInMonth; d++) {
    final date = DateTime.utc(year, month, d);
    final app = eventsOn(date, events: events);
    result[date] = DayEvents(
      date: date,
      appEvents: app,
      isOffDay: isOffDay(date, app, override),
    );
  }
  return result;
}
