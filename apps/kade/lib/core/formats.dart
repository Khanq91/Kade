// Định dạng ngày giờ đơn giản, không cần package intl.
import 'package:lunar_core/lunar_core.dart';

import 'strings.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// 05/02/2027 (chỉ dùng y/m/d của [d]).
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 05/02/2027 14:30, theo giờ máy.
String formatDateTime(DateTime d) {
  final l = d.toLocal();
  return '${formatDate(l)} ${_two(l.hour)}:${_two(l.minute)}';
}

/// 2027-02-05 (cho route `/d/…`).
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "Thứ Bảy" theo `DateTime.weekday` (1 = Thứ Hai … 7 = Chủ nhật).
String weekdayName(int weekday) => Strings.weekdays[weekday - 1];

/// "1/1" / "15/6 nhuận" (không có năm).
String formatLunarShort(LunarDate l) =>
    '${l.day}/${l.month}${l.isLeapMonth ? ' ${Strings.leap}' : ''}';

/// "1/1/2027" / "15/6 nhuận/2025".
String formatLunar(LunarDate l) => '${formatLunarShort(l)}/${l.year}';

/// Chữ âm lịch trong ô lịch: mùng 1 → "1/M" ("1/MN" nếu tháng nhuận), còn lại chỉ ngày.
String lunarCellText(LunarDate l) {
  if (l.day != 1) return '${l.day}';
  return '1/${l.month}${l.isLeapMonth ? 'N' : ''}';
}

/// Chuẩn hóa về 0h UTC theo y/m/d (D012: so ngày theo y/m/d, không so với `now` local).
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
