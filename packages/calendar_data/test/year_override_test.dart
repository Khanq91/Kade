import 'dart:io';

import 'package:calendar_data/calendar_data.dart';
import 'package:test/test.dart';

/// Asset fallback ở root repo (chuyển vào apps/kade khi làm bước 5/6).
const assetPath = '../../assets/overrides.json';

void main() {
  test('parse asset overrides.json (fallback)', () {
    final o = YearOverrides.fromJsonString(File(assetPath).readAsStringSync());
    expect(o.version, 0);
    expect(o.updatedAt, DateTime.utc(2026, 9, 9));
    expect(o.years.keys, [2027]);
    final y = o.forYear(2027)!;
    expect(y.off, {
      DateTime.utc(2027, 2, 5),
      DateTime.utc(2027, 2, 6),
      DateTime.utc(2027, 2, 7),
      DateTime.utc(2027, 2, 8),
      DateTime.utc(2027, 2, 9),
    });
    expect(y.work, isEmpty);
    expect(o.forYear(2026), isNull);
  });

  test('parse output Apps Script: version epoch ms (số thực từ JS) → int', () {
    final o = YearOverrides.fromJsonString('''
      {"version": 1726000000000.0, "updatedAt": "2026-09-09T10:00:00.000Z",
       "years": {"2027": {"off": ["2027-02-05"], "work": ["2027-02-13"]}}}
    ''');
    expect(o.version, 1726000000000);
    expect(o.updatedAt, DateTime.utc(2026, 9, 9, 10));
    expect(o.forYear(2027)!.off, {DateTime.utc(2027, 2, 5)});
    expect(o.forYear(2027)!.work, {DateTime.utc(2027, 2, 13)});
  });

  test('bỏ qua key lạ, năm/ngày không hợp lệ; thiếu years → rỗng', () {
    final o = YearOverrides.fromJsonString('''
      {"version": 2, "_note": "x",
       "years": {"abc": {"off": ["2027-01-01"]},
                 "2027": {"off": ["2027-02-30", "05/02/2027", "2027-02-05", 7], "work": "no"},
                 "2028": "bad"}}
    ''');
    expect(o.years.keys, [2027]);
    expect(o.forYear(2027)!.off, {DateTime.utc(2027, 2, 5)});
    expect(o.forYear(2027)!.work, isEmpty);

    expect(YearOverrides.fromJsonString('{}').years, isEmpty);
    expect(YearOverrides.fromJsonString('{}').version, 0);
    expect(YearOverrides.empty.forYear(2027), isNull);
  });

  test('toJson → fromJson giữ nguyên dữ liệu, ngày được sort', () {
    final o = YearOverrides(
      version: 5,
      updatedAt: DateTime.utc(2026, 11, 20),
      years: {
        2027: YearOverride(
          off: {DateTime.utc(2027, 2, 9), DateTime.utc(2027, 2, 5)},
          work: {DateTime.utc(2027, 2, 13)},
        ),
      },
    );
    final json = o.toJson();
    expect((json['years'] as Map)['2027'], {
      'off': ['2027-02-05', '2027-02-09'],
      'work': ['2027-02-13'],
    });
    final back = YearOverrides.fromJson(json);
    expect(back.version, 5);
    expect(back.updatedAt, o.updatedAt);
    expect(back.forYear(2027)!.off, o.forYear(2027)!.off);
    expect(back.forYear(2027)!.work, o.forYear(2027)!.work);
  });

  test('parseIsoDate', () {
    expect(parseIsoDate('2027-02-05'), DateTime.utc(2027, 2, 5));
    expect(parseIsoDate(' 2027-02-05 '), DateTime.utc(2027, 2, 5));
    expect(parseIsoDate('2027-2-5'), isNull);
    expect(parseIsoDate('2027-02-30'), isNull);
    expect(parseIsoDate('2027-13-01'), isNull);
    expect(parseIsoDate('2027-02-05T00:00:00Z'), isNull);
  });
}
