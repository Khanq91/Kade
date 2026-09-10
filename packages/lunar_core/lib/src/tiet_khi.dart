// 24 tiết khí theo kinh độ Mặt Trời chia 15°, tính tại 0h địa phương (múi giờ 7)
// bằng SunLongitude của reference. Danh sách tên theo Hồ Ngọc Đức (amlich.js
// bản web), bắt đầu từ Xuân phân (0°).
import 'dart:math' as math;

import 'amlich.dart';
import 'solar_lunar.dart';

/// 24 tiết khí, chỉ số i ứng với kinh độ Mặt Trời [15i°, 15(i+1)°); 0 = Xuân phân.
const List<String> tietKhiNames = [
  'Xuân phân',
  'Thanh minh',
  'Cốc vũ',
  'Lập hạ',
  'Tiểu mãn',
  'Mang chủng',
  'Hạ chí',
  'Tiểu thử',
  'Đại thử',
  'Lập thu',
  'Xử thử',
  'Bạch lộ',
  'Thu phân',
  'Hàn lộ',
  'Sương giáng',
  'Lập đông',
  'Tiểu tuyết',
  'Đại tuyết',
  'Đông chí',
  'Tiểu hàn',
  'Đại hàn',
  'Lập xuân',
  'Vũ thủy',
  'Kinh trập',
];

/// Chỉ số tiết khí (0..23) lúc 0h địa phương đầu ngày có số ngày Julius [jd].
int tietKhiIndexAtStartOfDay(int jd, double timeZone) =>
    INT(SunLongitude(jd - 0.5 - timeZone / 24) / math.pi * 12);

/// Tên tiết khí bắt đầu trong ngày [solar] (Mặt Trời vượt mốc 15° trong ngày),
/// hoặc `null` nếu ngày đó không bắt đầu tiết khí nào.
String? tietKhiOf(DateTime solar, {double timeZone = defaultTimeZone}) {
  final jd = jdFromDate(solar.day, solar.month, solar.year);
  final before = tietKhiIndexAtStartOfDay(jd, timeZone);
  final after = tietKhiIndexAtStartOfDay(jd + 1, timeZone);
  return before == after ? null : tietKhiNames[after];
}
