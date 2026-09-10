// Test GIÁ TRỊ CỐ ĐỊNH cho bước 2 — output `example/day_info_example.dart`
// ngày 2026-09-10, user đã đối chiếu lịch vạn niên và xác nhận (DECISIONS D017).
// Đổi giá trị ở đây = đổi kết quả người dùng thấy → phải có DECISIONS mới.
import 'package:lunar_core/lunar_core.dart';
import 'package:lunar_core/src/amlich.dart';
import 'package:test/test.dart';

typedef Case = ({
  DateTime solar,
  LunarDate lunar,
  String year,
  String month,
  String day,
  String gioTy,
  String? tietKhi,
  List<String> gioHoangDao,
  bool hoangDao,
  String than,
});

final List<Case> cases = [
  (
    solar: DateTime.utc(2000, 1, 1),
    lunar: const LunarDate(day: 25, month: 11, year: 1999),
    year: 'Kỷ Mão',
    month: 'Bính Tý',
    day: 'Mậu Ngọ',
    gioTy: 'Nhâm Tý',
    tietKhi: null,
    gioHoangDao: [
      'Tý (23-1)',
      'Sửu (1-3)',
      'Mão (5-7)',
      'Ngọ (11-13)',
      'Thân (15-17)',
      'Dậu (17-19)',
    ],
    hoangDao: true,
    than: 'Tư Mệnh',
  ),
  (
    solar: DateTime.utc(1985, 1, 21),
    lunar: const LunarDate(day: 1, month: 1, year: 1985),
    year: 'Ất Sửu',
    month: 'Mậu Dần',
    day: 'Canh Thân',
    gioTy: 'Bính Tý',
    tietKhi: null,
    gioHoangDao: [
      'Tý (23-1)',
      'Sửu (1-3)',
      'Thìn (7-9)',
      'Tỵ (9-11)',
      'Mùi (13-15)',
      'Tuất (19-21)',
    ],
    hoangDao: false,
    than: 'Thiên Lao',
  ),
  (
    solar: DateTime.utc(2024, 2, 10),
    lunar: const LunarDate(day: 1, month: 1, year: 2024),
    year: 'Giáp Thìn',
    month: 'Bính Dần',
    day: 'Giáp Thìn',
    gioTy: 'Giáp Tý',
    tietKhi: null,
    gioHoangDao: [
      'Dần (3-5)',
      'Thìn (7-9)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Dậu (17-19)',
      'Hợi (21-23)',
    ],
    hoangDao: true,
    than: 'Kim Quỹ',
  ),
  (
    solar: DateTime.utc(2024, 12, 21),
    lunar: const LunarDate(day: 21, month: 11, year: 2024),
    year: 'Giáp Thìn',
    month: 'Bính Tý',
    day: 'Kỷ Mùi',
    gioTy: 'Giáp Tý',
    tietKhi: 'Đông chí',
    gioHoangDao: [
      'Dần (3-5)',
      'Mão (5-7)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Tuất (19-21)',
      'Hợi (21-23)',
    ],
    hoangDao: false,
    than: 'Câu Trận',
  ),
  (
    solar: DateTime.utc(2025, 1, 29),
    lunar: const LunarDate(day: 1, month: 1, year: 2025),
    year: 'Ất Tỵ',
    month: 'Mậu Dần',
    day: 'Mậu Tuất',
    gioTy: 'Nhâm Tý',
    tietKhi: null,
    gioHoangDao: [
      'Dần (3-5)',
      'Thìn (7-9)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Dậu (17-19)',
      'Hợi (21-23)',
    ],
    hoangDao: true,
    than: 'Tư Mệnh',
  ),
  (
    solar: DateTime.utc(2025, 2, 3),
    lunar: const LunarDate(day: 6, month: 1, year: 2025),
    year: 'Ất Tỵ',
    month: 'Mậu Dần',
    day: 'Quý Mão',
    gioTy: 'Nhâm Tý',
    tietKhi: 'Lập xuân',
    gioHoangDao: [
      'Tý (23-1)',
      'Dần (3-5)',
      'Mão (5-7)',
      'Ngọ (11-13)',
      'Mùi (13-15)',
      'Dậu (17-19)',
    ],
    hoangDao: false,
    than: 'Chu Tước',
  ),
  (
    solar: DateTime.utc(2025, 7, 25),
    lunar: const LunarDate(day: 1, month: 6, year: 2025, isLeapMonth: true),
    year: 'Ất Tỵ',
    month: 'Quý Mùi',
    day: 'Ất Mùi',
    gioTy: 'Bính Tý',
    tietKhi: null,
    gioHoangDao: [
      'Dần (3-5)',
      'Mão (5-7)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Tuất (19-21)',
      'Hợi (21-23)',
    ],
    hoangDao: false,
    than: 'Nguyên Vũ',
  ),
  (
    solar: DateTime.utc(2026, 2, 17),
    lunar: const LunarDate(day: 1, month: 1, year: 2026),
    year: 'Bính Ngọ',
    month: 'Canh Dần',
    day: 'Nhâm Tuất',
    gioTy: 'Canh Tý',
    tietKhi: null,
    gioHoangDao: [
      'Dần (3-5)',
      'Thìn (7-9)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Dậu (17-19)',
      'Hợi (21-23)',
    ],
    hoangDao: true,
    than: 'Tư Mệnh',
  ),
  (
    solar: DateTime.utc(2026, 9, 10),
    lunar: const LunarDate(day: 29, month: 7, year: 2026),
    year: 'Bính Ngọ',
    month: 'Bính Thân',
    day: 'Đinh Hợi',
    gioTy: 'Canh Tý',
    tietKhi: null,
    gioHoangDao: [
      'Sửu (1-3)',
      'Thìn (7-9)',
      'Ngọ (11-13)',
      'Mùi (13-15)',
      'Tuất (19-21)',
      'Hợi (21-23)',
    ],
    hoangDao: false,
    than: 'Câu Trận',
  ),
  (
    solar: DateTime.utc(2033, 12, 22),
    lunar: const LunarDate(day: 1, month: 11, year: 2033, isLeapMonth: true),
    year: 'Quý Sửu',
    month: 'Giáp Tý',
    day: 'Đinh Mùi',
    gioTy: 'Canh Tý',
    tietKhi: null,
    gioHoangDao: [
      'Dần (3-5)',
      'Mão (5-7)',
      'Tỵ (9-11)',
      'Thân (15-17)',
      'Tuất (19-21)',
      'Hợi (21-23)',
    ],
    hoangDao: false,
    than: 'Câu Trận',
  ),
];

/// (tháng, ngày) dương bắt đầu từng tiết khí năm 2025, theo thứ tự trong năm.
const tietKhi2025 = <(int, int, String)>[
  (1, 5, 'Tiểu hàn'),
  (1, 20, 'Đại hàn'),
  (2, 3, 'Lập xuân'),
  (2, 18, 'Vũ thủy'),
  (3, 5, 'Kinh trập'),
  (3, 20, 'Xuân phân'),
  (4, 4, 'Thanh minh'),
  (4, 20, 'Cốc vũ'),
  (5, 5, 'Lập hạ'),
  (5, 21, 'Tiểu mãn'),
  (6, 5, 'Mang chủng'),
  (6, 21, 'Hạ chí'),
  (7, 7, 'Tiểu thử'),
  (7, 22, 'Đại thử'),
  (8, 7, 'Lập thu'),
  (8, 23, 'Xử thử'),
  (9, 7, 'Bạch lộ'),
  (9, 23, 'Thu phân'),
  (10, 8, 'Hàn lộ'),
  (10, 23, 'Sương giáng'),
  (11, 7, 'Lập đông'),
  (11, 22, 'Tiểu tuyết'),
  (12, 7, 'Đại tuyết'),
  (12, 21, 'Đông chí'),
];

void main() {
  group('10 ngày user đã đối chiếu', () {
    for (final c in cases) {
      test(c.solar.toIso8601String().substring(0, 10), () {
        final i = dayInfo(c.solar);
        final jd = jdFromDate(c.solar.day, c.solar.month, c.solar.year);
        expect(i.lunar, c.lunar);
        expect(i.canChiYear, c.year);
        expect(i.canChiMonth, c.month);
        expect(i.canChiDay, c.day);
        expect(canChiHour(jd, 0), c.gioTy);
        expect(i.tietKhi, c.tietKhi);
        expect(i.gioHoangDao, c.gioHoangDao);
        expect(i.isHoangDao, c.hoangDao);
        expect(
          thanOfDay(chiIndexOfMonth(i.lunar.month), chiIndexOfDay(jd)),
          c.than,
        );
      });
    }
  });

  test('24 tiết khí năm 2025 đúng ngày, không có ngày nào khác', () {
    final found = <(int, int, String)>[];
    for (
      var d = DateTime.utc(2025, 1, 1);
      d.year == 2025;
      d = d.add(const Duration(days: 1))
    ) {
      final t = tietKhiOf(d);
      if (t != null) found.add((d.month, d.day, t));
    }
    expect(found, tietKhi2025);
  });
}
