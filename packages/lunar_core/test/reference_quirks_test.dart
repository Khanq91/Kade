// Quirk đã biết của reference (docs/reference/amlich-aa98.js), ghi ở
// .memory/ERRORS.md E005. Port giữ 1:1 theo D009 nên tái hiện đúng quirk này;
// test này sẽ ĐỎ khi user quyết sửa reference (xem DECISIONS) → cập nhật cùng lúc
// với fixture sinh lại.
//
// Bản chất: convertSolar2Lunar ước lượng k = INT((jd - epoch)/29.53) rồi chỉ
// lùi tối đa 1 sóc. Khi sóc thực trễ hơn sóc trung bình và rơi vào ngày hôm
// sau, ngày đang xét bị gán ngày 0 của tháng kế (đúng ra là ngày 30 tháng
// trước). Trong 1900–2100 xảy ra đúng 2 lần — JS gốc chạy bằng node cho cùng
// kết quả.
import 'package:lunar_core/lunar_core.dart';
import 'package:test/test.dart';

/// Ngày dương mà reference (và port) trả lunar day == 0.
final referenceDayZero = <DateTime>{
  DateTime.utc(2054, 5, 7), // JS: 0/4/2054 — kỳ vọng đúng: 30/3/2054
  DateTime.utc(2062, 4, 9), // JS: 0/3/2062 — kỳ vọng đúng: 30/2/2062
};

void main() {
  test('reference trả ngày 0 cho 2054-05-07 (tháng 4) — port tái hiện', () {
    expect(
      solarToLunar(DateTime.utc(2054, 5, 7)),
      const LunarDate(day: 0, month: 4, year: 2054),
    );
    expect(
      solarToLunar(DateTime.utc(2054, 5, 6)),
      const LunarDate(day: 29, month: 3, year: 2054),
    );
    expect(
      solarToLunar(DateTime.utc(2054, 5, 8)),
      const LunarDate(day: 1, month: 4, year: 2054),
    );
  });

  test('reference trả ngày 0 cho 2062-04-09 (tháng 3) — port tái hiện', () {
    expect(
      solarToLunar(DateTime.utc(2062, 4, 9)),
      const LunarDate(day: 0, month: 3, year: 2062),
    );
    expect(
      solarToLunar(DateTime.utc(2062, 4, 8)),
      const LunarDate(day: 29, month: 2, year: 2062),
    );
    expect(
      solarToLunar(DateTime.utc(2062, 4, 10)),
      const LunarDate(day: 1, month: 3, year: 2062),
    );
  });

  test('ngoài 2 ngày trên, không ngày nào 1900–2100 có lunar day 0', () {
    final end = DateTime.utc(2100, 12, 31);
    for (
      var d = DateTime.utc(1900, 1, 1);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      if (referenceDayZero.contains(d)) continue;
      expect(solarToLunar(d).day, greaterThanOrEqualTo(1), reason: '$d');
    }
  });
}
