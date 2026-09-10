import 'package:calendar_data/calendar_data.dart';
import 'package:test/test.dart';

void main() {
  group('dữ liệu sự kiện', () {
    test('id duy nhất, kind khớp danh sách, ngày/tháng hợp lệ', () {
      final ids = allEvents.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id trùng');
      expect(
        allEvents.length,
        vnHolidays.length + vnMemorials.length + international.length,
      );
      for (final e in vnHolidays) {
        expect(e.kind, EventKind.vnHoliday, reason: e.id);
      }
      for (final e in vnMemorials) {
        expect(e.kind, EventKind.vnMemorial, reason: e.id);
      }
      for (final e in international) {
        expect(e.kind, EventKind.international, reason: e.id);
      }
      for (final e in allEvents) {
        expect(
          e.id,
          matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
          reason: e.id,
        );
        expect(e.title, isNotEmpty, reason: e.id);
        expect(e.month, inInclusiveRange(1, 12), reason: e.id);
        expect(e.durationDays, greaterThanOrEqualTo(1), reason: e.id);
        if (e.nthWeekday != null) {
          expect(e.type, CalendarType.solar, reason: e.id);
          expect(e.nthWeekday!.n, inInclusiveRange(1, 5), reason: e.id);
          expect(e.nthWeekday!.weekday, inInclusiveRange(1, 7), reason: e.id);
        } else if (e.type == CalendarType.solar) {
          expect(e.day, inInclusiveRange(1, 31), reason: e.id);
          // ngày cố định phải tồn tại ở mọi năm (không dùng 29/2, 31/4...)
          expect(
            DateTime.utc(2027, e.month, e.day).month,
            e.month,
            reason: e.id,
          );
        } else {
          expect(e.day, inInclusiveRange(1, 30), reason: e.id);
        }
      }
    });

    test('danh sách quốc tế đúng plan §2.2 (Năm mới 1/1 nằm ở vnHolidays)', () {
      expect(international.map((e) => e.id), [
        'valentine',
        'ca-thang-tu',
        'trai-dat',
        'ngay-cua-me',
        'quoc-te-thieu-nhi',
        'ngay-cua-cha',
        'nha-giao-quoc-te',
        'halloween',
        'giang-sinh',
      ]);
      expect(vnHolidays.first.id, 'tet-duong-lich');
      expect(vnHolidays.first.month, 1);
      expect(vnHolidays.first.day, 1);
    });

    test(
      'Tết kéo dài 3 ngày, các sự kiện khác 1 ngày; chỉ Giao thừa lệch −1',
      () {
        for (final e in allEvents) {
          expect(e.durationDays, e.id == 'tet' ? 3 : 1, reason: e.id);
          expect(e.offsetDays, e.id == 'giao-thua' ? -1 : 0, reason: e.id);
        }
        expect(vnHolidays.map((e) => e.id), [
          'tet-duong-lich',
          'giao-thua',
          'tet',
          'gio-to',
          'giai-phong',
          'quoc-te-lao-dong',
          'quoc-khanh',
        ]);
        expect(vnMemorials.length, 22);
      },
    );
  });

  group('NthWeekday', () {
    test('Ngày của Mẹ / Cha 2025 và 2027', () {
      final me = international.singleWhere((e) => e.id == 'ngay-cua-me');
      final cha = international.singleWhere((e) => e.id == 'ngay-cua-cha');
      expect(me.nthWeekday!.resolve(2025, 5), DateTime.utc(2025, 5, 11));
      expect(cha.nthWeekday!.resolve(2025, 6), DateTime.utc(2025, 6, 15));
      expect(me.nthWeekday!.resolve(2027, 5), DateTime.utc(2027, 5, 9));
      expect(cha.nthWeekday!.resolve(2027, 6), DateTime.utc(2027, 6, 20));
    });

    test('luôn đúng thứ, đúng tháng, đúng lần thứ n (1900–2100)', () {
      for (var y = 1900; y <= 2100; y++) {
        for (var m = 1; m <= 12; m++) {
          for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
            for (var n = 1; n <= 5; n++) {
              final d = NthWeekday(weekday: wd, n: n).resolve(y, m);
              if (d == null) {
                expect(n, 5, reason: '$y/$m thứ $wd lần $n phải tồn tại');
                continue;
              }
              expect(d.weekday, wd);
              expect(d.month, m);
              expect((d.day - 1) ~/ 7 + 1, n);
            }
          }
        }
      }
    });

    test('lần thứ 5 không tồn tại → null', () {
      // Tháng 2/2027 có 4 Chủ nhật (7, 14, 21, 28).
      expect(
        const NthWeekday(weekday: DateTime.sunday, n: 5).resolve(2027, 2),
        isNull,
      );
    });
  });
}
