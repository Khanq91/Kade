// Bảng const 1900–2100 (sinh bởi tools/gen_lunar_table.dart) phải cho kết quả
// y hệt thuật toán runtime, mọi ngày và mọi ngày âm (kể cả ngày không tồn tại).
import 'package:lunar_core/lunar_core.dart';
import 'package:lunar_core/src/amlich.dart';
import 'package:lunar_core/src/lunar_table.dart';
import 'package:lunar_core/src/table_1900_2100.dart';
import 'package:test/test.dart';

int yearLength((int, int, int) e) {
  final n = e.$2 == 0 ? 12 : 13;
  var sum = 0;
  for (var k = 0; k < n; k++) {
    sum += ((e.$3 >> k) & 1) == 1 ? 30 : 29;
  }
  return sum;
}

void main() {
  group('cấu trúc bảng', () {
    test('201 năm 1900–2100, nhuận 0..12, bitmask không thừa bit', () {
      expect(lunarTableFirstYear, 1900);
      expect(lunarTableLastYear, 2100);
      expect(lunarYearTable.length, 201);
      for (final e in lunarYearTable) {
        expect(e.$2, inInclusiveRange(0, 12));
        final n = e.$2 == 0 ? 12 : 13;
        expect(e.$3 >> n, 0, reason: 'bit thừa ngoài $n tháng');
        expect(yearLength(e), anyOf(353, 354, 355, 383, 384, 385));
      }
    });

    test(
      'Tết năm sau = Tết năm trước + số ngày trong năm; Tết 1900 khớp runtime',
      () {
        for (var i = 0; i + 1 < lunarYearTable.length; i++) {
          expect(
            lunarYearTable[i + 1].$1 - lunarYearTable[i].$1,
            yearLength(lunarYearTable[i]),
            reason: 'năm ${1900 + i}',
          );
        }
        final (d, m, y) = convertLunar2Solar(1, 1, 1900, 0, 7);
        expect(lunarYearTable.first.$1, jdFromDate(d, m, y));
      },
    );
  });

  test('solarToLunar (bảng) == solarToLunarComputed, mọi ngày 1900–2100', () {
    final tet1900 = lunarYearTable.first.$1;
    final end = DateTime.utc(2100, 12, 31);
    for (
      var d = DateTime.utc(1900, 1, 1);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      final jd = jdFromDate(d.day, d.month, d.year);
      final fromTable = tableSolarToLunar(jd);
      if (jd >= tet1900) {
        expect(fromTable, isNotNull, reason: '$d phải nằm trong bảng');
      } else {
        expect(fromTable, isNull, reason: '$d trước Tết 1900');
      }
      expect(solarToLunar(d), solarToLunarComputed(d), reason: '$d');
    }
  });

  test(
    'lunarToSolar (bảng) == lunarToSolarComputed, mọi (năm, tháng, nhuận, ngày)',
    () {
      for (var y = 1900; y <= 2100; y++) {
        for (var m = 1; m <= 12; m++) {
          for (final leap in [false, true]) {
            for (var day = 1; day <= 30; day++) {
              final l = LunarDate(
                day: day,
                month: m,
                year: y,
                isLeapMonth: leap,
              );
              expect(lunarToSolar(l), lunarToSolarComputed(l), reason: '$l');
            }
          }
        }
      }
    },
  );

  test('ngày âm vô lý → null ở cả hai đường', () {
    for (final l in [
      const LunarDate(day: 0, month: 1, year: 2025),
      const LunarDate(day: 31, month: 1, year: 2025),
      const LunarDate(day: 1, month: 0, year: 2025),
      const LunarDate(day: 1, month: 13, year: 2025),
      const LunarDate(day: 1, month: 5, year: 2025, isLeapMonth: true),
    ]) {
      expect(lunarToSolar(l), isNull, reason: '$l');
    }
  });

  test('ngoài bảng (trước 1900, sau 2100) → tính trực tiếp, vẫn hai chiều', () {
    for (final d in [
      DateTime.utc(1899, 6, 15),
      DateTime.utc(1850, 2, 1),
      DateTime.utc(2101, 3, 1),
      DateTime.utc(2150, 7, 7),
    ]) {
      final l = solarToLunar(d);
      expect(l, solarToLunarComputed(d));
      expect(lunarToSolar(l), d);
    }
    expect(tableCoversLunarYear(1899), isFalse);
    expect(tableCoversLunarYear(2101), isFalse);
    expect(tableSolarToLunar(jdFromDate(1, 1, 1899)), isNull);
  });

  test('múi giờ khác 7 → không tra bảng, dùng tính trực tiếp', () {
    for (final d in [
      DateTime.utc(2025, 1, 29),
      DateTime.utc(2054, 5, 7),
      DateTime.utc(1985, 1, 21),
    ]) {
      expect(
        solarToLunar(d, timeZone: 8),
        solarToLunarComputed(d, timeZone: 8),
      );
      final l = solarToLunar(d, timeZone: 8);
      expect(
        lunarToSolar(l, timeZone: 8),
        lunarToSolarComputed(l, timeZone: 8),
      );
    }
  });
}
