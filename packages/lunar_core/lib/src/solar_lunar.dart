import 'amlich.dart';
import 'lunar_date.dart';

/// Múi giờ mặc định của lịch Việt Nam (UTC+7). Xem DECISIONS D009.
const double defaultTimeZone = 7;

/// Đổi ngày dương (chỉ dùng năm/tháng/ngày của [solar]) sang âm lịch.
LunarDate solarToLunar(DateTime solar, {double timeZone = defaultTimeZone}) {
  final (day, month, year, leap) = convertSolar2Lunar(
    solar.day,
    solar.month,
    solar.year,
    timeZone,
  );
  return LunarDate(day: day, month: month, year: year, isLeapMonth: leap == 1);
}

/// Đổi ngày âm sang dương (0h UTC); trả `null` nếu ngày âm không tồn tại.
///
/// Ngày không tồn tại: tháng nhuận sai/không có, hoặc ngày 30 của tháng thiếu.
/// Kiểm bằng cách đổi ngược lại và so với [lunar].
DateTime? lunarToSolar(LunarDate lunar, {double timeZone = defaultTimeZone}) {
  final (day, month, year) = convertLunar2Solar(
    lunar.day,
    lunar.month,
    lunar.year,
    lunar.isLeapMonth ? 1 : 0,
    timeZone,
  );
  if (day == 0) return null;
  final solar = DateTime.utc(year, month, day);
  if (solarToLunar(solar, timeZone: timeZone) != lunar) return null;
  return solar;
}
