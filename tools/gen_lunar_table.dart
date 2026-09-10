// Sinh packages/lunar_core/lib/src/table_1900_2100.dart (const) từ thuật toán
// runtime (amlich.dart, múi giờ +7). Chạy ở ROOT repo:
//   dart run tools/gen_lunar_table.dart && dart format packages/lunar_core
// Test đối chiếu bảng == runtime: packages/lunar_core/test/lunar_table_test.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:lunar_core/src/amlich.dart';

const firstYear = 1900;
const lastYear = 2100;
const timeZone = 7.0;
const outPath = 'packages/lunar_core/lib/src/table_1900_2100.dart';

/// JD mùng 1 Tết của năm âm [y].
int tetJd(int y) {
  final (d, m, yy) = convertLunar2Solar(1, 1, y, 0, timeZone);
  return jdFromDate(d, m, yy);
}

/// Âm lịch (ngày, tháng, năm, nhuận) của ngày JD [jd].
(int, int, int, int) lunarOf(int jd) {
  final (d, m, y) = jdToDate(jd);
  return convertSolar2Lunar(d, m, y, timeZone);
}

void main() {
  final buf = StringBuffer()
    ..writeln(
      '// GENERATED — không sửa tay. Sinh bởi `dart run tools/gen_lunar_table.dart`',
    )
    ..writeln(
      '// (chạy ở root repo) từ thuật toán runtime trong amlich.dart, múi giờ +7.',
    )
    ..writeln('// Đối chiếu bảng == runtime: test/lunar_table_test.dart.')
    ..writeln()
    ..writeln('/// Năm âm đầu tiên trong bảng.')
    ..writeln('const int lunarTableFirstYear = $firstYear;')
    ..writeln()
    ..writeln('/// Năm âm cuối cùng trong bảng.')
    ..writeln('const int lunarTableLastYear = $lastYear;')
    ..writeln()
    ..writeln('/// Mỗi phần tử là một năm âm kể từ [lunarTableFirstYear]:')
    ..writeln(
      '/// (JD mùng 1 Tết, tháng nhuận hoặc 0, bitmask — bit k = 1 nếu tháng thứ k',
    )
    ..writeln(
      '/// trong năm (0-based, tính cả tháng nhuận) có 30 ngày, ngược lại 29).',
    )
    ..writeln('const List<(int, int, int)> lunarYearTable = [');

  for (var y = firstYear; y <= lastYear; y++) {
    final tet = tetJd(y);
    final next = tetJd(y + 1);
    final lengths = <int>[];
    var leap = 0;
    var expectedMonth = 1;
    var jd = tet;
    while (jd < next) {
      final (ld, lm, ly, ll) = lunarOf(jd);
      if (ld != 1 || ly != y) {
        throw StateError('jd $jd: kỳ vọng mùng 1 năm $y, nhận $ld/$lm/$ly');
      }
      var len = 1;
      while (jd + len < next) {
        final (ld2, lm2, _, ll2) = lunarOf(jd + len);
        if (lm2 != lm || ll2 != ll) break;
        if (ld2 != len + 1) {
          throw StateError('jd ${jd + len}: ngày âm $ld2 != ${len + 1}');
        }
        len++;
      }
      if (len != 29 && len != 30) {
        throw StateError('năm $y tháng $lm dài $len ngày');
      }
      if (ll == 1) {
        if (lm != expectedMonth - 1) {
          throw StateError('năm $y: nhuận $lm sai chỗ');
        }
        leap = lm;
      } else {
        if (lm != expectedMonth) {
          throw StateError('năm $y: tháng $lm, kỳ vọng $expectedMonth');
        }
        expectedMonth++;
      }
      lengths.add(len);
      jd += len;
    }
    if (lengths.length != (leap == 0 ? 12 : 13) || expectedMonth != 13) {
      throw StateError('năm $y: ${lengths.length} tháng, nhuận $leap');
    }
    var bits = 0;
    for (var k = 0; k < lengths.length; k++) {
      if (lengths[k] == 30) bits |= 1 << k;
    }
    final (td, tm, ty) = jdToDate(tet);
    final hex = '0x${bits.toRadixString(16).padLeft(4, '0')}';
    final note = leap == 0 ? 'không nhuận' : 'nhuận $leap';
    buf.writeln(
      '  ($tet, $leap, $hex), // $y: Tết $ty-$tm-$td, $note, ${next - tet} ngày',
    );
  }
  buf.writeln('];');

  File(outPath).writeAsStringSync(buf.toString());
  print('Đã ghi $outPath (${lastYear - firstYear + 1} năm)');
}
