// Regression cho patch D014 (ERRORS E005): bản gốc amlich-aa98.js trả lunar
// day 0 cho 2054-05-07 (0/4/2054) và 2062-04-09 (0/3/2062) vì ước lượng k theo
// sóc trung bình rồi chỉ lùi 1 sóc. Sau patch (lùi thêm 1 sóc) hai ngày này là
// ngày 30 của tháng trước; fixture đã sinh lại từ reference đã patch.
import 'package:lunar_core/lunar_core.dart';
import 'package:test/test.dart';

void main() {
  test('2054-05-07 là 30/3/2054 (bản gốc: 0/4/2054)', () {
    expect(
      solarToLunar(DateTime.utc(2054, 5, 7)),
      const LunarDate(day: 30, month: 3, year: 2054),
    );
    expect(
      solarToLunar(DateTime.utc(2054, 5, 8)),
      const LunarDate(day: 1, month: 4, year: 2054),
    );
    expect(
      lunarToSolar(const LunarDate(day: 30, month: 3, year: 2054)),
      DateTime.utc(2054, 5, 7),
    );
  });

  test('2062-04-09 là 30/2/2062 (bản gốc: 0/3/2062)', () {
    expect(
      solarToLunar(DateTime.utc(2062, 4, 9)),
      const LunarDate(day: 30, month: 2, year: 2062),
    );
    expect(
      solarToLunar(DateTime.utc(2062, 4, 10)),
      const LunarDate(day: 1, month: 3, year: 2062),
    );
    expect(
      lunarToSolar(const LunarDate(day: 30, month: 2, year: 2062)),
      DateTime.utc(2062, 4, 9),
    );
  });

  test('mọi ngày 1900–2100: lunar day trong 1..30, month trong 1..12', () {
    final end = DateTime.utc(2100, 12, 31);
    for (
      var d = DateTime.utc(1900, 1, 1);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      final l = solarToLunar(d);
      expect(l.day, inInclusiveRange(1, 30), reason: '$d');
      expect(l.month, inInclusiveRange(1, 12), reason: '$d');
    }
  });
}
