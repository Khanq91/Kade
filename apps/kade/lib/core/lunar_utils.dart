// Tiện ích âm lịch nhỏ dùng chung UI + logic sự kiện (không đụng lunar_core).
import 'package:lunar_core/lunar_core.dart';

/// Tháng nhuận của năm âm [lunarYear], hoặc `null` nếu năm không nhuận.
int? leapMonthOf(int lunarYear) {
  for (var m = 1; m <= 12; m++) {
    final d = LunarDate(day: 1, month: m, year: lunarYear, isLeapMonth: true);
    if (lunarToSolar(d) != null) return m;
  }
  return null;
}
