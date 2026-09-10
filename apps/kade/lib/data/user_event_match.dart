// Khớp sự kiện cá nhân với một ngày dương (plan §3.2, D005). Pure Dart.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:lunar_core/lunar_core.dart';

import '../core/lunar_utils.dart';
import 'models/user_event.dart';

/// Sự kiện cá nhân rơi vào ngày [date] (chỉ dùng y/m/d), bỏ tombstone, giữ
/// thứ tự trong [events]. Ngày d thuộc sự kiện nếu có k trong
/// `0..durationDays-1` sao cho `d − k` là ngày neo.
List<UserEvent> userEventsOn(DateTime date, List<UserEvent> events) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final lunarCache = <int, LunarDate>{}; // key = k
  return [
    for (final e in events)
      if (!e.isDeleted && _matches(e, d, lunarCache)) e,
  ];
}

bool _matches(UserEvent e, DateTime d, Map<int, LunarDate> lunarCache) {
  for (var k = 0; k < e.durationDays; k++) {
    final anchor = d.subtract(Duration(days: k));
    if (e.type == CalendarType.solar) {
      if (anchor.day == e.day &&
          anchor.month == e.month &&
          (e.year == null || anchor.year == e.year)) {
        return true;
      }
    } else {
      final l = lunarCache[k] ??= solarToLunar(anchor);
      if (lunarMatches(e, l)) return true;
    }
  }
  return false;
}

/// Ngày âm [l] có phải ngày neo của sự kiện ÂM [e] không, theo `leapRule`:
/// tháng nhuận chỉ khớp khi rule là `secondMonth`/`both`; tháng chính khớp
/// trừ khi rule là `secondMonth` VÀ năm đó có tháng nhuận cùng số.
bool lunarMatches(UserEvent e, LunarDate l) {
  if (l.day != e.day || l.month != e.month) return false;
  if (e.year != null && l.year != e.year) return false;
  if (l.isLeapMonth) return e.leapRule != LeapMonthRule.firstMonth;
  return e.leapRule != LeapMonthRule.secondMonth ||
      leapMonthOf(l.year) != l.month;
}
