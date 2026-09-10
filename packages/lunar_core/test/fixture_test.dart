// Đối chiếu port với fixture sinh từ reference (spec: docs/reference/README.md):
// - mọi năm 1900–2100: lunarToSolar(1/1/y) == tet
// - mọi tháng: mùng 1 == start, số ngày == days, cờ nhuận đúng
// - solarToLunar cho MỌI ngày trong năm trả đúng (tháng, nhuận) — và thêm số
//   ngày == d+1, trừ 2 ngày reference trả ngày 0 (xem reference_quirks_test.dart)
// - hai chiều: lunarToSolar(solarToLunar(d)) == d cho mọi ngày 1900–2100
import 'dart:convert';
import 'dart:io';

import 'package:lunar_core/lunar_core.dart';
import 'package:test/test.dart';

import 'reference_quirks_test.dart' show referenceDayZero;

/// Đường dẫn tính từ packages/lunar_core (cwd khi chạy `dart test`).
const fixturePath = '../../docs/reference/tet_1900_2100.json';

/// "2027-02-06" → DateTime.utc(2027, 2, 6).
DateTime isoDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

void main() {
  final root =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  final years = root['years'] as Map<String, dynamic>;

  test('fixture có đủ 201 năm 1900–2100', () {
    expect(years.keys.map(int.parse).toSet(), {
      for (var y = 1900; y <= 2100; y++) y,
    });
  });

  group('fixture từng năm', () {
    for (final entry in years.entries) {
      final y = int.parse(entry.key);
      final data = entry.value as Map<String, dynamic>;
      test('năm $y', () {
        final tet = isoDate(data['tet'] as String);
        final leapMonth = data['leapMonth'] as int;
        final months = (data['months'] as List).cast<Map<String, dynamic>>();

        expect(
          lunarToSolar(LunarDate(day: 1, month: 1, year: y)),
          tet,
          reason: 'Tết $y',
        );
        expect(solarToLunar(tet), LunarDate(day: 1, month: 1, year: y));
        expect(
          months.where((m) => m['leap'] as bool).length,
          leapMonth == 0 ? 0 : 1,
        );
        expect(isoDate(months.first['start'] as String), tet);

        var totalDays = 0;
        for (var i = 0; i < months.length; i++) {
          final m = months[i];
          final month = m['m'] as int;
          final leap = m['leap'] as bool;
          final days = m['days'] as int;
          final start = isoDate(m['start'] as String);
          final label = 'tháng $month${leap ? ' nhuận' : ''}/$y';
          totalDays += days;
          if (leap) expect(month, leapMonth, reason: label);
          if (i + 1 < months.length) {
            expect(
              isoDate(months[i + 1]['start'] as String),
              start.add(Duration(days: days)),
              reason: 'fixture: tháng sau $label phải liền kề',
            );
          }

          // Fixture ghi `start` = ngày đầu reference gán vào tháng này. Với 2
          // tháng quirk, ngày đó là "ngày 0": mùng 1 thật là ngày kế tiếp, số
          // ngày âm của cả tháng lệch 1 và `days` = số ngày thật + 1.
          final startsWithDayZero = referenceDayZero.contains(start);
          final firstDay = startsWithDayZero
              ? start.add(const Duration(days: 1))
              : start;
          final realDays = startsWithDayZero ? days - 1 : days;
          expect(
            lunarToSolar(
              LunarDate(day: 1, month: month, year: y, isLeapMonth: leap),
            ),
            firstDay,
            reason: 'mùng 1 $label',
          );
          for (var d = 0; d < days; d++) {
            final solar = start.add(Duration(days: d));
            final lunar = solarToLunar(solar);
            expect(
              (lunar.month, lunar.year, lunar.isLeapMonth),
              (month, y, leap),
              reason: 'solarToLunar($solar) trong $label',
            );
            expect(
              lunar.day,
              startsWithDayZero ? d : d + 1,
              reason: 'ngày âm của $solar trong $label',
            );
          }
          if (realDays == 29) {
            expect(
              lunarToSolar(
                LunarDate(day: 30, month: month, year: y, isLeapMonth: leap),
              ),
              isNull,
              reason: '$label thiếu, không có ngày 30',
            );
          }
        }
        expect(totalDays, data['daysInYear'], reason: 'daysInYear $y');

        for (var m = 1; m <= 12; m++) {
          if (m == leapMonth) continue;
          expect(
            lunarToSolar(
              LunarDate(day: 1, month: m, year: y, isLeapMonth: true),
            ),
            isNull,
            reason: 'tháng $m nhuận/$y không tồn tại',
          );
        }
      });
    }
  });

  test('hai chiều: lunarToSolar(solarToLunar(d)) == d, mọi ngày 1900–2100', () {
    final start = DateTime.utc(1900, 1, 1);
    final end = DateTime.utc(2100, 12, 31);
    var count = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final lunar = solarToLunar(d);
      expect(lunarToSolar(lunar), d, reason: '$d → $lunar');
      count++;
    }
    expect(count, end.difference(start).inDays + 1);
  });
}
