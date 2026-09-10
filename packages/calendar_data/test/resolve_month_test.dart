// Verify Phase 1 bước 4 theo plan §6: resolveMonth 2/2027 (Tết 2027-02-06,
// override nghỉ 05–09/02 từ assets/overrides.json).
import 'dart:io';

import 'package:calendar_data/calendar_data.dart';
import 'package:lunar_core/lunar_core.dart';
import 'package:test/test.dart';

const assetPath = '../../assets/overrides.json';

List<String> idsOn(Map<DateTime, DayEvents> m, int y, int mo, int d) =>
    m[DateTime.utc(y, mo, d)]!.appEvents.map((e) => e.id).toList();

void main() {
  final overrides = YearOverrides.fromJsonString(
    File(assetPath).readAsStringSync(),
  );

  group('resolveMonth 2/2027', () {
    final m = resolveMonth(2027, 2, overrides: overrides);

    test('đủ 28 ngày, key là 0h UTC', () {
      expect(m.length, 28);
      expect(m.keys.first, DateTime.utc(2027, 2, 1));
      expect(m.keys.last, DateTime.utc(2027, 2, 28));
      for (final e in m.entries) {
        expect(e.value.date, e.key);
      }
    });

    test('Tết 06/02 kéo 3 ngày (mùng 1–3), không lan sang 05 và 09', () {
      expect(
        solarToLunar(DateTime.utc(2027, 2, 6)),
        const LunarDate(day: 1, month: 1, year: 2027),
      );
      expect(idsOn(m, 2027, 2, 5), isNot(contains('tet')));
      expect(idsOn(m, 2027, 2, 6), contains('tet'));
      expect(idsOn(m, 2027, 2, 7), contains('tet'));
      expect(idsOn(m, 2027, 2, 8), contains('tet'));
      expect(idsOn(m, 2027, 2, 9), isNot(contains('tet')));
    });

    test('ngày nghỉ: 05–09/02 (override off + Tết), ngoài đó không', () {
      for (var d = 5; d <= 9; d++) {
        expect(m[DateTime.utc(2027, 2, d)]!.isOffDay, isTrue, reason: '$d/2');
      }
      for (final d in [1, 2, 3, 4, 10, 11, 14, 20, 28]) {
        expect(m[DateTime.utc(2027, 2, d)]!.isOffDay, isFalse, reason: '$d/2');
      }
    });

    test('kỷ niệm / quốc tế / âm trong tháng', () {
      expect(idsOn(m, 2027, 2, 3), ['thanh-lap-dang']);
      expect(idsOn(m, 2027, 2, 14), ['valentine']);
      expect(idsOn(m, 2027, 2, 20), [
        'ram-thang-gieng',
      ]); // 15/1 âm = 06/02 + 14
      expect(idsOn(m, 2027, 2, 27), ['thay-thuoc']);
      expect(idsOn(m, 2027, 2, 1), isEmpty);
    });

    test('Chủ nhật không tự động là ngày nghỉ', () {
      expect(DateTime.utc(2027, 2, 14).weekday, DateTime.sunday);
      expect(m[DateTime.utc(2027, 2, 14)]!.isOffDay, isFalse);
    });
  });

  group('override', () {
    test('work thắng lễ; off thêm ngày nghỉ', () {
      final o = YearOverrides(
        years: {
          2027: YearOverride(
            off: {DateTime.utc(2027, 2, 10)},
            work: {DateTime.utc(2027, 2, 8)},
          ),
        },
      );
      final m = resolveMonth(2027, 2, overrides: o);
      expect(idsOn(m, 2027, 2, 8), contains('tet'));
      expect(m[DateTime.utc(2027, 2, 8)]!.isOffDay, isFalse);
      expect(m[DateTime.utc(2027, 2, 10)]!.isOffDay, isTrue);
      expect(m[DateTime.utc(2027, 2, 6)]!.isOffDay, isTrue);
    });

    test('không có override → chỉ vnHoliday là ngày nghỉ', () {
      final m = resolveMonth(2027, 4);
      expect(m[DateTime.utc(2027, 4, 30)]!.isOffDay, isTrue);
      expect(m[DateTime.utc(2027, 4, 22)]!.isOffDay, isFalse); // Ngày Trái Đất
      expect(idsOn(m, 2027, 4, 22), ['trai-dat']);
      expect(idsOn(m, 2027, 4, 1), ['ca-thang-tu']);
    });
  });

  group('lễ VN nghỉ', () {
    test('Giỗ Tổ 10/3 âm 2027 và 30/4, 1/5, 2/9, 1/1 là ngày nghỉ', () {
      final gioTo = lunarToSolar(
        const LunarDate(day: 10, month: 3, year: 2027),
      )!;
      final m = resolveMonth(gioTo.year, gioTo.month);
      expect(idsOn(m, gioTo.year, gioTo.month, gioTo.day), ['gio-to']);
      expect(m[gioTo]!.isOffDay, isTrue);

      expect(resolveMonth(2027, 5)[DateTime.utc(2027, 5, 1)]!.isOffDay, isTrue);
      expect(resolveMonth(2027, 9)[DateTime.utc(2027, 9, 2)]!.isOffDay, isTrue);
      expect(resolveMonth(2027, 1)[DateTime.utc(2027, 1, 1)]!.isOffDay, isTrue);
      expect(idsOn(resolveMonth(2027, 1), 2027, 1, 1), ['tet-duong-lich']);
    });

    test('Tết 2014 (31/01) lan sang tháng 2: mùng 2, 3 = 01, 02/02', () {
      expect(
        solarToLunar(DateTime.utc(2014, 1, 31)),
        const LunarDate(day: 1, month: 1, year: 2014),
      );
      final feb = resolveMonth(2014, 2);
      expect(idsOn(feb, 2014, 2, 1), contains('tet'));
      expect(idsOn(feb, 2014, 2, 2), contains('tet'));
      expect(idsOn(feb, 2014, 2, 3), isNot(contains('tet')));
      expect(feb[DateTime.utc(2014, 2, 2)]!.isOffDay, isTrue);
    });
  });

  group('sự kiện âm và tháng nhuận', () {
    test('2028 nhuận tháng 5: Đoan Ngọ chỉ 1 lần, ở tháng 5 chính', () {
      final hits = <DateTime>[];
      for (var mo = 1; mo <= 12; mo++) {
        for (final e in resolveMonth(2028, mo).entries) {
          if (e.value.appEvents.any((x) => x.id == 'doan-ngo')) hits.add(e.key);
        }
      }
      expect(hits.length, 1);
      final l = solarToLunar(hits.single);
      expect(l, const LunarDate(day: 5, month: 5, year: 2028));
      expect(
        lunarToSolar(
          const LunarDate(day: 5, month: 5, year: 2028, isLeapMonth: true),
        ),
        isNotNull,
        reason: '2028 phải có tháng 5 nhuận để test có ý nghĩa',
      );
    });

    test('mỗi sự kiện âm 1 ngày xuất hiện đúng 1 lần trong năm âm 2027', () {
      final tet = lunarToSolar(const LunarDate(day: 1, month: 1, year: 2027))!;
      final tetNext = lunarToSolar(
        const LunarDate(day: 1, month: 1, year: 2028),
      )!;
      final count = <String, int>{};
      for (
        var d = tet;
        d.isBefore(tetNext);
        d = d.add(const Duration(days: 1))
      ) {
        for (final e in eventsOn(d)) {
          if (e.type == CalendarType.lunar) {
            count[e.id] = (count[e.id] ?? 0) + 1;
          }
        }
      }
      for (final e in allEvents.where((e) => e.type == CalendarType.lunar)) {
        expect(count[e.id], e.durationDays, reason: e.id);
      }
    });
  });

  group('eventsOn', () {
    test('thứ tự: nghỉ → kỷ niệm → quốc tế; nhận DateTime local', () {
      final custom = [
        ...international.where((e) => e.id == 'quoc-te-thieu-nhi'),
        Event(
          id: 'x',
          title: 'X',
          kind: EventKind.vnMemorial,
          type: CalendarType.solar,
          month: 6,
          day: 1,
        ),
      ];
      expect(
        eventsOn(DateTime(2027, 6, 1, 15, 30), events: custom).map((e) => e.id),
        ['quoc-te-thieu-nhi', 'x'],
      );
      expect(eventsOn(DateTime.utc(2027, 6, 1)).map((e) => e.id), [
        'quoc-te-thieu-nhi',
      ]);
    });

    test('sự kiện nhiều ngày vắt qua năm mới', () {
      const cuoiNam = Event(
        id: 'cuoi-nam',
        title: 'Cuối năm',
        kind: EventKind.international,
        type: CalendarType.solar,
        month: 12,
        day: 31,
        durationDays: 2,
      );
      final jan = resolveMonth(2028, 1, events: const [cuoiNam]);
      expect(idsOn(jan, 2028, 1, 1), ['cuoi-nam']);
      expect(idsOn(jan, 2028, 1, 2), isEmpty);
      final dec = resolveMonth(2027, 12, events: const [cuoiNam]);
      expect(idsOn(dec, 2027, 12, 31), ['cuoi-nam']);
      expect(idsOn(dec, 2027, 12, 30), isEmpty);
    });

    test('Ngày của Mẹ / Cha rơi đúng Chủ nhật', () {
      final may = resolveMonth(2027, 5);
      expect(idsOn(may, 2027, 5, 9), ['ngay-cua-me']);
      expect(idsOn(may, 2027, 5, 2), isNot(contains('ngay-cua-me')));
      final jun = resolveMonth(2027, 6);
      expect(idsOn(jun, 2027, 6, 20), ['ngay-cua-cha']);
    });
  });
}
