// Test từng hàm port theo giá trị của chính reference
// (docs/reference/amlich-aa98.js chạy bằng node) và tính nhất quán nội bộ.
import 'package:lunar_core/src/amlich.dart';
import 'package:test/test.dart';

void main() {
  test('INT làm tròn xuống như Math.floor', () {
    expect(INT(3.2), 3);
    expect(INT(-3.2), -4);
    expect(INT(5), 5);
  });

  test(
    'jdFromDate(1,1,2000) == 2451545 (chú thích NewMoon: 2451545.125 là 1/1/2000 15:00 UTC)',
    () {
      expect(jdFromDate(1, 1, 2000), 2451545);
      expect(jdToDate(2451545), (1, 1, 2000));
    },
  );

  test('NewMoon(2), NewMoon(-2) khớp JS gốc chạy bằng node (ERRORS E006)', () {
    // Chú thích trong JS ghi 2415079.9758617813 / 2414961.935157746 nhưng chính
    // hàm JS trả các giá trị dưới đây (node v24, toPrecision(17)).
    expect(NewMoon(2), closeTo(2415079.9761049072, 1e-9));
    expect(NewMoon(-2), closeTo(2414961.9343954599, 1e-9));
  });

  test('jdFromDate ↔ jdToDate hai chiều, mọi ngày 1900–2100', () {
    final first = jdFromDate(1, 1, 1900);
    final last = jdFromDate(31, 12, 2100);
    expect(last - first + 1, 73414); // 201 năm, 49 năm nhuận
    for (var jd = first; jd <= last; jd++) {
      final (d, m, y) = jdToDate(jd);
      expect(jdFromDate(d, m, y), jd, reason: 'jd $jd → $d/$m/$y');
    }
  });

  test('jdFromDate ↔ jdToDate hai chiều quanh mốc đổi lịch 2299161', () {
    for (var jd = 2299100; jd <= 2299200; jd++) {
      final (d, m, y) = jdToDate(jd);
      expect(jdFromDate(d, m, y), jd, reason: 'jd $jd → $d/$m/$y');
    }
  });

  test('getSunLongitude trả 0..11, getNewMoonDay tăng 29–30 ngày mỗi k', () {
    for (var k = -1300; k <= 2500; k += 97) {
      final nm = getNewMoonDay(k, 7);
      final next = getNewMoonDay(k + 1, 7);
      expect(next - nm, inInclusiveRange(29, 30), reason: 'k=$k');
      expect(getSunLongitude(nm, 7), inInclusiveRange(0, 11), reason: 'k=$k');
    }
  });
}
