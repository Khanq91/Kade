// Tra bảng const 1900–2100 (table_1900_2100.dart, sinh từ runtime). Dùng khi
// múi giờ = 7 và năm nằm trong bảng; ngoài đó solar_lunar.dart tính trực tiếp.
import 'lunar_date.dart';
import 'table_1900_2100.dart';

/// Bảng có phủ năm âm [year] không.
bool tableCoversLunarYear(int year) =>
    year >= lunarTableFirstYear && year <= lunarTableLastYear;

/// Số tháng trong năm âm có tháng nhuận [leap] (0 = không nhuận).
int _monthCount(int leap) => leap == 0 ? 12 : 13;

/// Số ngày của tháng thứ [k] (0-based, tính cả nhuận) trong entry [e].
int _monthLength((int, int, int) e, int k) => ((e.$3 >> k) & 1) == 1 ? 30 : 29;

/// Chỉ số tháng (0-based) trong năm cho (tháng, nhuận); `null` nếu không tồn tại.
int? _monthIndex(int leap, int month, bool isLeap) {
  if (month < 1 || month > 12) return null;
  if (isLeap) return month == leap ? leap : null;
  return (leap != 0 && month > leap) ? month : month - 1;
}

/// Ngày âm của ngày JD [jd] theo bảng; `null` nếu [jd] ngoài phạm vi bảng.
LunarDate? tableSolarToLunar(int jd) {
  if (jd < lunarYearTable.first.$1) return null;
  var lo = 0;
  var hi = lunarYearTable.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (lunarYearTable[mid].$1 <= jd) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  final e = lunarYearTable[lo];
  final leap = e.$2;
  var offset = jd - e.$1;
  for (var k = 0; k < _monthCount(leap); k++) {
    final len = _monthLength(e, k);
    if (offset < len) {
      final isLeap = leap != 0 && k == leap;
      final month = isLeap ? leap : ((leap != 0 && k > leap) ? k : k + 1);
      return LunarDate(
        day: offset + 1,
        month: month,
        year: lunarTableFirstYear + lo,
        isLeapMonth: isLeap,
      );
    }
    offset -= len;
  }
  return null; // sau ngày cuối của năm cuối bảng
}

/// JD của ngày âm [l] theo bảng; `null` nếu năm ngoài bảng hoặc ngày không tồn tại.
int? tableLunarToSolarJd(LunarDate l) {
  if (!tableCoversLunarYear(l.year)) return null;
  final e = lunarYearTable[l.year - lunarTableFirstYear];
  final k = _monthIndex(e.$2, l.month, l.isLeapMonth);
  if (k == null) return null;
  if (l.day < 1 || l.day > _monthLength(e, k)) return null;
  var jd = e.$1;
  for (var i = 0; i < k; i++) {
    jd += _monthLength(e, i);
  }
  return jd + l.day - 1;
}
