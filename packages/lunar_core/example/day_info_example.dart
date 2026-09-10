// In DayInfo của một số ngày để user đối chiếu với lịch vạn niên (phase0-step2).
// Chạy trong packages/lunar_core:  dart run example/day_info_example.dart
// ignore_for_file: avoid_print
import 'package:lunar_core/lunar_core.dart';
import 'package:lunar_core/src/amlich.dart';

const weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String two(int n) => n.toString().padLeft(2, '0');
String fmt(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

void main() {
  final days = [
    DateTime.utc(2000, 1, 1),
    DateTime.utc(1985, 1, 21),
    DateTime.utc(2024, 2, 10),
    DateTime.utc(2024, 12, 21),
    DateTime.utc(2025, 1, 29),
    DateTime.utc(2025, 2, 3),
    DateTime.utc(2025, 7, 25),
    DateTime.utc(2026, 2, 17),
    DateTime.utc(2026, 9, 10),
    DateTime.utc(2033, 12, 22),
  ];
  for (final d in days) {
    final i = dayInfo(d);
    final jd = jdFromDate(d.day, d.month, d.year);
    final l = i.lunar;
    final than = thanOfDay(chiIndexOfMonth(l.month), chiIndexOfDay(jd));
    print('=== ${fmt(d)} (${weekdays[d.weekday - 1]}), JD $jd');
    print(
      '  Âm lịch : ${l.day}/${l.month}${l.isLeapMonth ? ' nhuận' : ''}/${l.year}',
    );
    print(
      '  Năm ${i.canChiYear} | Tháng ${i.canChiMonth} | Ngày ${i.canChiDay} | Giờ Tý: ${canChiHour(jd, 0)}',
    );
    print('  Tiết khí: ${i.tietKhi ?? '(không bắt đầu tiết khí)'}');
    print('  Giờ HĐ  : ${i.gioHoangDao.join(', ')}');
    print('  Ngày    : ${i.isHoangDao ? 'HOÀNG ĐẠO' : 'hắc đạo'} ($than)');
  }

  print('\n=== Ngày bắt đầu tiết khí năm 2025 ===');
  for (
    var d = DateTime.utc(2025, 1, 1);
    d.year == 2025;
    d = d.add(const Duration(days: 1))
  ) {
    final t = tietKhiOf(d);
    if (t != null) print('  ${fmt(d)}  $t');
  }
}
