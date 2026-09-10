// Model UserEvent (JSON) + khớp ngày (plan §3.2, D005). Pure Dart.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/lunar_utils.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/user_event_match.dart';
import 'package:lunar_core/lunar_core.dart';

final _t0 = DateTime.utc(2026, 9, 10, 8);

UserEvent ev({
  CalendarType type = CalendarType.lunar,
  required int day,
  required int month,
  int? year,
  LeapMonthRule rule = LeapMonthRule.firstMonth,
  int duration = 1,
  bool deleted = false,
}) => UserEvent(
  id: 'e-$day-$month',
  title: 'test',
  type: type,
  day: day,
  month: month,
  year: year,
  durationDays: duration,
  leapRule: rule,
  createdAt: _t0,
  updatedAt: _t0,
  deletedAt: deleted ? _t0 : null,
);

List<String> on(DateTime d, List<UserEvent> es) =>
    userEventsOn(d, es).map((e) => e.id).toList();

void main() {
  test('JSON round trip, enum theo tên, null giữ nguyên', () {
    final e = ev(day: 15, month: 8, rule: LeapMonthRule.both, duration: 2);
    final json = e.toJson();
    expect(json['type'], 'lunar');
    expect(json['leapRule'], 'both');
    expect(json['year'], isNull);
    expect(json['deletedAt'], isNull);
    expect(json['createdAt'], _t0.toIso8601String());
    expect(UserEvent.fromJson(json), e);

    final full = e.copyWith(
      year: 2027,
      note: 'ghi chú',
      remindBeforeDays: 3,
      colorIndex: 5,
      deletedAt: _t0,
    );
    expect(UserEvent.fromJson(full.toJson()), full);
    expect(full.isDeleted, isTrue);
    expect(full.isYearly, isFalse);
  });

  group('âm lịch 15/6 hàng năm, năm 2025 nhuận tháng 6', () {
    // Không bịa ngày: lấy từ engine.
    final chinh = lunarToSolar(const LunarDate(day: 15, month: 6, year: 2025))!;
    final nhuan = lunarToSolar(
      const LunarDate(day: 15, month: 6, year: 2025, isLeapMonth: true),
    )!;

    test('engine: 2025 nhuận tháng 6, hai ngày khác nhau', () {
      expect(leapMonthOf(2025), 6);
      expect(chinh, isNot(nhuan));
    });

    test('firstMonth (mặc định) → chỉ tháng chính', () {
      final e = ev(day: 15, month: 6);
      expect(on(chinh, [e]), ['e-15-6']);
      expect(on(nhuan, [e]), isEmpty);
    });

    test('secondMonth → chỉ tháng nhuận', () {
      final e = ev(day: 15, month: 6, rule: LeapMonthRule.secondMonth);
      expect(on(chinh, [e]), isEmpty);
      expect(on(nhuan, [e]), ['e-15-6']);
    });

    test('both → cả hai', () {
      final e = ev(day: 15, month: 6, rule: LeapMonthRule.both);
      expect(on(chinh, [e]), ['e-15-6']);
      expect(on(nhuan, [e]), ['e-15-6']);
    });
  });

  test('năm không nhuận tháng 6: secondMonth vẫn khớp tháng chính', () {
    final year = [2026, 2027].firstWhere((y) => leapMonthOf(y) != 6);
    final chinh = lunarToSolar(LunarDate(day: 15, month: 6, year: year))!;
    final e = ev(day: 15, month: 6, rule: LeapMonthRule.secondMonth);
    expect(on(chinh, [e]), ['e-15-6']);
  });

  test('âm lịch một lần (có year) chỉ khớp năm đó', () {
    final e = ev(day: 1, month: 1, year: 2027);
    expect(on(DateTime.utc(2027, 2, 6), [e]), ['e-1-1']); // Tết Đinh Mùi
    final tet2028 = lunarToSolar(
      const LunarDate(day: 1, month: 1, year: 2028),
    )!;
    expect(on(tet2028, [e]), isEmpty);
  });

  test('dương lịch hàng năm, 3 ngày vắt qua tháng', () {
    final e = ev(type: CalendarType.solar, day: 30, month: 1, duration: 3);
    expect(on(DateTime.utc(2027, 1, 30), [e]), ['e-30-1']);
    expect(on(DateTime.utc(2027, 1, 31), [e]), ['e-30-1']);
    expect(on(DateTime.utc(2027, 2, 1), [e]), ['e-30-1']);
    expect(on(DateTime.utc(2027, 2, 2), [e]), isEmpty);
    expect(on(DateTime.utc(2030, 1, 30), [e]), ['e-30-1']);
  });

  test('dương lịch một lần', () {
    final e = ev(type: CalendarType.solar, day: 6, month: 2, year: 2027);
    expect(on(DateTime.utc(2027, 2, 6), [e]), ['e-6-2']);
    expect(on(DateTime.utc(2028, 2, 6), [e]), isEmpty);
  });

  test('tombstone bị bỏ; giữ thứ tự danh sách', () {
    final a = ev(type: CalendarType.solar, day: 6, month: 2);
    final b = ev(day: 1, month: 1);
    final gone = ev(
      type: CalendarType.solar,
      day: 6,
      month: 2,
      deleted: true,
    ).copyWith(id: 'gone');
    expect(on(DateTime.utc(2027, 2, 6), [gone, b, a]), ['e-1-1', 'e-6-2']);
  });
}
