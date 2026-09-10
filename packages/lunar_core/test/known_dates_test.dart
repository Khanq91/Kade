// Kiểm chứng ĐỘC LẬP với fixture: bảng Tết / tháng nhuận đã biết rộng rãi,
// chép nguyên từ docs/reference/README.md (agent không tự thêm dòng).
import 'package:lunar_core/lunar_core.dart';
import 'package:test/test.dart';

/// (năm âm, Tết dương, tháng nhuận hoặc 0).
const knownYears = <(int, String, int)>[
  (1968, '1968-01-29', 7), // TQ ăn Tết 30/1 — lệch 1 ngày
  (1985, '1985-01-21', 2), // TQ ăn Tết 20/2 — lệch cả tháng
  (2007, '2007-02-17', 0), // TQ 18/2 — lệch 1 ngày
  (2014, '2014-01-31', 9),
  (2017, '2017-01-28', 6),
  (2020, '2020-01-25', 4),
  (2023, '2023-01-22', 2),
  (2024, '2024-02-10', 0),
  (2025, '2025-01-29', 6),
  (2026, '2026-02-17', 0),
  (2027, '2027-02-06', 0),
  (2028, '2028-01-26', 5),
  (2029, '2029-02-13', 0),
  (2030, '2030-02-02', 0),
  (2033, '2033-01-31', 11), // "2033 problem", nhuận 11
];

void main() {
  for (final (year, tetIso, leapMonth) in knownYears) {
    test(
      'Tết $year = $tetIso, nhuận ${leapMonth == 0 ? 'không' : leapMonth}',
      () {
        final p = tetIso.split('-').map(int.parse).toList();
        final tet = DateTime.utc(p[0], p[1], p[2]);
        expect(lunarToSolar(LunarDate(day: 1, month: 1, year: year)), tet);
        expect(solarToLunar(tet), LunarDate(day: 1, month: 1, year: year));
        for (var m = 1; m <= 12; m++) {
          final leapFirst = lunarToSolar(
            LunarDate(day: 1, month: m, year: year, isLeapMonth: true),
          );
          if (m == leapMonth) {
            expect(leapFirst, isNotNull, reason: 'phải có tháng $m nhuận');
            expect(solarToLunar(leapFirst!).isLeapMonth, isTrue);
          } else {
            expect(leapFirst, isNull, reason: 'không có tháng $m nhuận');
          }
        }
      },
    );
  }
}
