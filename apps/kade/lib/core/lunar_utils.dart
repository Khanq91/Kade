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

/// Mùng 1 của các tháng âm rơi trong tháng dương [year]/[month]: 0 (tháng 2
/// đôi khi), 1 hoặc 2 tháng, theo thứ tự thời gian.
List<LunarDate> lunarMonthsStartingIn(int year, int month) {
  final days = DateTime.utc(year, month + 1, 0).day;
  return [
    for (var d = 1; d <= days; d++)
      if (solarToLunar(DateTime.utc(year, month, d)) case final l
          when l.day == 1)
        l,
  ];
}

/// Mùng 1 của tháng âm liền trước ([delta] −1) / liền sau (+1) tháng chứa [m]
/// (kể cả tháng nhuận), đi qua ngày dương nên không cần biết độ dài tháng.
LunarDate adjacentLunarMonth(LunarDate m, int delta) {
  final first = lunarToSolar(
    LunarDate(day: 1, month: m.month, year: m.year, isLeapMonth: m.isLeapMonth),
  )!;
  // Tháng âm dài 29–30 ngày: +31 ngày chắc chắn rơi vào tháng kế (mùng 2–3),
  // −1 ngày là ngày cuối tháng trước.
  final probe = delta > 0
      ? first.add(const Duration(days: 31))
      : first.subtract(const Duration(days: 1));
  final l = solarToLunar(probe);
  return LunarDate(
    day: 1,
    month: l.month,
    year: l.year,
    isLeapMonth: l.isLeapMonth,
  );
}

/// Đang duyệt theo tháng âm ở tháng dương [year]/[month] (`?lunar=1`, D033):
/// tháng dương chứa mùng 1 của tháng âm kề trước/sau. Sau = tháng kế của tháng
/// âm có mùng 1 muộn nhất trong tháng dương; trước = tháng liền trước của tháng
/// âm có mùng 1 sớm nhất. Tháng dương không có mùng 1 nào → tháng âm chứa ngày
/// 1 (bắt đầu ở tháng dương trước): sau = tháng kế của nó, trước = chính nó.
(int year, int month) shiftLunarMonth(int year, int month, int delta) {
  final firsts = lunarMonthsStartingIn(year, month);
  final LunarDate target;
  if (firsts.isEmpty) {
    final l = solarToLunar(DateTime.utc(year, month, 1));
    final current = LunarDate(
      day: 1,
      month: l.month,
      year: l.year,
      isLeapMonth: l.isLeapMonth,
    );
    target = delta > 0 ? adjacentLunarMonth(current, 1) : current;
  } else {
    target = adjacentLunarMonth(delta > 0 ? firsts.last : firsts.first, delta);
  }
  final s = lunarToSolar(target)!;
  return (s.year, s.month);
}
