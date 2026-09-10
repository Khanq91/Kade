import 'amlich.dart';
import 'can_chi.dart';
import 'hoang_dao.dart';
import 'lunar_date.dart';
import 'solar_lunar.dart';
import 'tiet_khi.dart';

/// Output engine cho 1 ngày dương (plan §2.1).
class DayInfo {
  /// Tạo trực tiếp; thường dùng [dayInfo] thay vì constructor này.
  const DayInfo({
    required this.solar,
    required this.lunar,
    required this.canChiYear,
    required this.canChiMonth,
    required this.canChiDay,
    required this.tietKhi,
    required this.gioHoangDao,
    required this.isHoangDao,
  });

  /// Ngày dương (0h UTC, chỉ y/m/d có ý nghĩa).
  final DateTime solar;

  /// Ngày âm tương ứng.
  final LunarDate lunar;

  /// Can chi năm âm, ví dụ "Giáp Thìn".
  final String canChiYear;

  /// Can chi tháng âm (tháng nhuận cùng can chi tháng chính), ví dụ "Bính Dần".
  final String canChiMonth;

  /// Can chi ngày, ví dụ "Mậu Ngọ".
  final String canChiDay;

  /// Tên tiết khí nếu ngày này bắt đầu tiết khí, ngược lại `null`.
  final String? tietKhi;

  /// 6 giờ hoàng đạo trong ngày, dạng "Tý (23-1)".
  final List<String> gioHoangDao;

  /// Ngày hoàng đạo (theo chi tháng × chi ngày) hay hắc đạo.
  final bool isHoangDao;
}

/// Tính đủ [DayInfo] cho ngày dương [solar] (chỉ dùng y/m/d), múi giờ mặc định 7.
DayInfo dayInfo(DateTime solar, {double timeZone = defaultTimeZone}) {
  final jd = jdFromDate(solar.day, solar.month, solar.year);
  final lunar = solarToLunar(solar, timeZone: timeZone);
  final dayChi = chiIndexOfDay(jd);
  return DayInfo(
    solar: DateTime.utc(solar.year, solar.month, solar.day),
    lunar: lunar,
    canChiYear: canChiYear(lunar.year),
    canChiMonth: canChiMonth(lunar.month, lunar.year),
    canChiDay: canChiDay(jd),
    tietKhi: tietKhiOf(solar, timeZone: timeZone),
    gioHoangDao: gioHoangDao(dayChi),
    isHoangDao: isNgayHoangDao(chiIndexOfMonth(lunar.month), dayChi),
  );
}
