// Test CẤU TRÚC cho can chi / tiết khí / hoàng đạo / DayInfo: chu kỳ, tính nhất
// quán nội bộ, định dạng. Giá trị cụ thể (ngày X là can chi gì, tiết khí gì)
// chờ user đối chiếu lịch vạn niên rồi mới thêm test cố định (phase0-step2).
import 'package:lunar_core/lunar_core.dart';
import 'package:lunar_core/src/amlich.dart';
import 'package:test/test.dart';

void main() {
  group('can chi', () {
    test('năm: chu kỳ 60, 60 năm liên tiếp không trùng', () {
      for (var y = 1900; y <= 2100; y++) {
        expect(canChiYear(y), canChiYear(y + 60), reason: '$y');
      }
      expect({for (var y = 2000; y < 2060; y++) canChiYear(y)}.length, 60);
    });

    test('tháng: chi cố định theo số tháng (Giêng = Dần, 11 = Tý, 12 = Sửu)', () {
      for (var y = 1900; y <= 2100; y++) {
        expect(canChiMonth(1, y), endsWith(' Dần'));
        expect(canChiMonth(11, y), endsWith(' Tý'));
        expect(canChiMonth(12, y), endsWith(' Sửu'));
        // 12 tháng liên tiếp có can tăng 1 mỗi tháng; tháng Giêng năm sau = +12 ≡ +2.
        for (var m = 1; m < 12; m++) {
          final a = can.indexOf(canChiMonth(m, y).split(' ')[0]);
          final b = can.indexOf(canChiMonth(m + 1, y).split(' ')[0]);
          expect(b, (a + 1) % 10, reason: 'tháng $m/$y');
        }
        final dec = can.indexOf(canChiMonth(12, y).split(' ')[0]);
        final jan = can.indexOf(canChiMonth(1, y + 1).split(' ')[0]);
        expect(jan, (dec + 1) % 10, reason: 'Chạp $y → Giêng ${y + 1}');
      }
    });

    test('ngày: chu kỳ 60, ngày kế tiếp can +1 và chi +1', () {
      final first = jdFromDate(1, 1, 1900);
      final last = jdFromDate(31, 12, 2100);
      for (var jd = first; jd <= last; jd++) {
        expect(canChiDay(jd), canChiDay(jd + 60), reason: 'jd $jd');
        final a = canChiDay(jd).split(' ');
        final b = canChiDay(jd + 1).split(' ');
        expect(
          can.indexOf(b[0]),
          (can.indexOf(a[0]) + 1) % 10,
          reason: 'jd $jd',
        );
        expect(
          chi.indexOf(b[1]),
          (chi.indexOf(a[1]) + 1) % 12,
          reason: 'jd $jd',
        );
        expect(chiIndexOfDay(jd), chi.indexOf(a[1]));
      }
    });

    test(
      'giờ: 12 giờ trong ngày chi Tý→Hợi, can tăng 1; giờ Tý hôm sau can +2',
      () {
        for (var jd = 2451545; jd < 2451545 + 60; jd++) {
          for (var h = 0; h < 12; h++) {
            final p = canChiHour(jd, h).split(' ');
            expect(p[1], chi[h]);
            if (h > 0) {
              final prev = can.indexOf(canChiHour(jd, h - 1).split(' ')[0]);
              expect(can.indexOf(p[0]), (prev + 1) % 10);
            }
          }
          final ty0 = can.indexOf(canChiHour(jd, 0).split(' ')[0]);
          final ty1 = can.indexOf(canChiHour(jd + 1, 0).split(' ')[0]);
          expect(ty1, (ty0 + 2) % 10);
        }
      },
    );
  });

  group('tiết khí', () {
    test('24 tên, ngày bắt đầu cách nhau 14–16 ngày, tên đi theo vòng 24', () {
      expect(tietKhiNames.length, 24);
      expect(tietKhiNames.toSet().length, 24);
      String? prev;
      DateTime? prevDate;
      var count = 0;
      final end = DateTime.utc(2100, 12, 31);
      for (
        var d = DateTime.utc(1900, 1, 1);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))
      ) {
        final t = tietKhiOf(d);
        if (t == null) continue;
        count++;
        if (prev != null) {
          expect(
            tietKhiNames.indexOf(t),
            (tietKhiNames.indexOf(prev) + 1) % 24,
            reason: '$prevDate $prev → $d $t',
          );
          expect(
            d.difference(prevDate!).inDays,
            inInclusiveRange(14, 16),
            reason: '$prevDate → $d',
          );
        }
        prev = t;
        prevDate = d;
      }
      expect(count, inInclusiveRange(24 * 201 - 1, 24 * 201 + 1));
    });

    test(
      'mỗi năm dương có đúng 1 Đông chí, 1 Hạ chí, 1 Xuân phân, 1 Thu phân',
      () {
        for (var y = 1900; y <= 2100; y++) {
          final names = <String>[];
          for (
            var d = DateTime.utc(y, 1, 1);
            d.year == y;
            d = d.add(const Duration(days: 1))
          ) {
            final t = tietKhiOf(d);
            if (t != null) names.add(t);
          }
          for (final n in ['Đông chí', 'Hạ chí', 'Xuân phân', 'Thu phân']) {
            expect(names.where((x) => x == n).length, 1, reason: '$n $y');
          }
        }
      },
    );
  });

  group('hoàng đạo', () {
    test(
      'bảng giờ và bảng ngày: 12 dòng × 12 ký tự, mỗi dòng đúng 6 hoàng đạo',
      () {
        for (final table in [gioHoangDaoTable, ngayHoangDaoTable]) {
          expect(table.length, 12);
          for (final row in table) {
            expect(row.length, 12);
            expect(row.split('').where((c) => c == '1').length, 6);
            expect(row, matches(RegExp(r'^[01]{12}$')));
          }
        }
      },
    );

    test(
      'bảng ngày khớp vòng 12 thần (Thanh Long khởi Tý ở tháng Dần, +2/tháng)',
      () {
        expect(thanNames.length, 12);
        expect(thanIsHoangDao.where((x) => x).length, 6);
        expect(thanhLongChi(2), 0); // tháng Dần (Giêng) → Tý
        expect(thanhLongChi(8), 0); // tháng Thân (7) → Tý
        for (var m = 0; m < 12; m++) {
          for (var d = 0; d < 12; d++) {
            final than = thanOfDay(m, d);
            expect(
              isNgayHoangDao(m, d),
              thanIsHoangDao[thanNames.indexOf(than)],
              reason: 'tháng chi ${chi[m]}, ngày chi ${chi[d]} = $than',
            );
          }
          expect(thanOfDay(m, thanhLongChi(m)), 'Thanh Long');
        }
      },
    );

    test('gioHoangDao: 6 mục dạng "Chi (a-b)", chi tăng dần', () {
      final re = RegExp(r'^(\S+) \((\d+)-(\d+)\)$');
      for (var c = 0; c < 12; c++) {
        final g = gioHoangDao(c);
        expect(g.length, 6);
        var lastChi = -1;
        for (final s in g) {
          final m = re.firstMatch(s)!;
          final ci = chi.indexOf(m.group(1)!);
          expect(ci, greaterThan(lastChi));
          lastChi = ci;
          expect(int.parse(m.group(2)!), (ci * 2 + 23) % 24);
          expect(int.parse(m.group(3)!), (ci * 2 + 1) % 24);
        }
      }
    });
  });

  group('dayInfo', () {
    test('nhất quán với các hàm thành phần, mọi ngày 2020–2030', () {
      final end = DateTime.utc(2030, 12, 31);
      for (
        var d = DateTime.utc(2020, 1, 1);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))
      ) {
        final i = dayInfo(d);
        final jd = jdFromDate(d.day, d.month, d.year);
        expect(i.solar, d);
        expect(i.lunar, solarToLunar(d));
        expect(i.canChiYear, canChiYear(i.lunar.year));
        expect(i.canChiMonth, canChiMonth(i.lunar.month, i.lunar.year));
        expect(i.canChiDay, canChiDay(jd));
        expect(i.tietKhi, tietKhiOf(d));
        expect(i.gioHoangDao, gioHoangDao(chiIndexOfDay(jd)));
        expect(
          i.isHoangDao,
          isNgayHoangDao(chiIndexOfMonth(i.lunar.month), chiIndexOfDay(jd)),
        );
        if (i.lunar.day == 1 && i.lunar.month == 1) {
          expect(i.canChiMonth, endsWith(' Dần'));
        }
      }
    });

    test('nhận DateTime local có giờ: chỉ dùng y/m/d', () {
      final local = DateTime(2025, 1, 29, 23, 59);
      expect(dayInfo(local).solar, DateTime.utc(2025, 1, 29));
      expect(dayInfo(local).lunar, solarToLunar(DateTime.utc(2025, 1, 29)));
    });
  });
}
