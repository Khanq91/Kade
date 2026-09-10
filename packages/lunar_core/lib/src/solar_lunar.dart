import 'amlich.dart';
import 'lunar_date.dart';
import 'lunar_table.dart';

/// Múi giờ mặc định của lịch Việt Nam (UTC+7). Xem DECISIONS D009.
const double defaultTimeZone = 7;

/// Đổi ngày dương (chỉ dùng năm/tháng/ngày của [solar]) sang âm lịch.
///
/// Múi giờ 7 và ngày trong bảng 1900–2100 → tra bảng; ngoài đó → tính trực tiếp
/// ([solarToLunarComputed]). Hai đường cho cùng kết quả (test/lunar_table_test).
LunarDate solarToLunar(DateTime solar, {double timeZone = defaultTimeZone}) {
  if (timeZone == defaultTimeZone) {
    final fromTable = tableSolarToLunar(
      jdFromDate(solar.day, solar.month, solar.year),
    );
    if (fromTable != null) return fromTable;
  }
  return solarToLunarComputed(solar, timeZone: timeZone);
}

/// Đổi ngày âm sang dương (0h UTC); trả `null` nếu ngày âm không tồn tại
/// (tháng nhuận sai/không có, hoặc ngày 30 của tháng thiếu).
///
/// Múi giờ 7 và năm trong bảng 1900–2100 → tra bảng; ngoài đó → tính trực tiếp
/// ([lunarToSolarComputed]).
DateTime? lunarToSolar(LunarDate lunar, {double timeZone = defaultTimeZone}) {
  if (timeZone == defaultTimeZone && tableCoversLunarYear(lunar.year)) {
    final jd = tableLunarToSolarJd(lunar);
    if (jd == null) return null;
    final (d, m, y) = jdToDate(jd);
    return DateTime.utc(y, m, d);
  }
  return lunarToSolarComputed(lunar, timeZone: timeZone);
}

/// [solarToLunar] tính trực tiếp bằng thuật toán (không tra bảng).
LunarDate solarToLunarComputed(
  DateTime solar, {
  double timeZone = defaultTimeZone,
}) {
  final (day, month, year, leap) = convertSolar2Lunar(
    solar.day,
    solar.month,
    solar.year,
    timeZone,
  );
  return LunarDate(day: day, month: month, year: year, isLeapMonth: leap == 1);
}

/// [lunarToSolar] tính trực tiếp bằng thuật toán (không tra bảng); kiểm tính
/// tồn tại bằng cách đổi ngược lại và so với [lunar].
DateTime? lunarToSolarComputed(
  LunarDate lunar, {
  double timeZone = defaultTimeZone,
}) {
  final (day, month, year) = convertLunar2Solar(
    lunar.day,
    lunar.month,
    lunar.year,
    lunar.isLeapMonth ? 1 : 0,
    timeZone,
  );
  if (day == 0) return null;
  final solar = DateTime.utc(year, month, day);
  if (solarToLunarComputed(solar, timeZone: timeZone) != lunar) return null;
  return solar;
}
