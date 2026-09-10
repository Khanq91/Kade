// buildReminders (plan §3.8, bước 16): giỗ 15/7 âm nhắc trước 3 ngày → đúng
// ngày dương 08:00; nghỉ lễ mặc định 7 ngày chỉ ngày đầu; bỏ mốc đã qua /
// ngoài 90 ngày / tombstone; sắp theo fireAt; leapRule both → 2 lần; id ổn định.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/formats.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/reminders.dart';
import 'package:lunar_core/lunar_core.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  UserEvent ev(
    String id, {
    required int day,
    required int month,
    CalendarType type = CalendarType.lunar,
    int? remind,
    int? year,
    int duration = 1,
    LeapMonthRule rule = LeapMonthRule.firstMonth,
    DateTime? deletedAt,
  }) => UserEvent(
    id: id,
    title: id,
    type: type,
    day: day,
    month: month,
    year: year,
    durationDays: duration,
    leapRule: rule,
    remindBeforeDays: remind,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: deletedAt,
  );

  test('giỗ 15/7 âm hàng năm, nhắc trước 3 ngày → đúng ngày dương, 08:00', () {
    final now = DateTime(2026, 8, 1, 12);
    final gio = lunarToSolar(const LunarDate(day: 15, month: 7, year: 2026))!;
    final list = buildReminders(
      events: [ev('gio', day: 15, month: 7, remind: 3)],
      now: now,
      holidayRemindDays: 0,
    );
    final r = list.single;
    expect(r.date, gio);
    expect(r.fireAt, DateTime(gio.year, gio.month, gio.day - 3, 8));
    expect(r.title, 'gio');
    expect(r.body, startsWith(Strings.inDays(3)));
    expect(r.body, contains(formatDate(gio)));
    expect(r.body, contains('15/7 ${Strings.lunarTag}'));
    expect(r.payload, '/d/${isoDate(gio)}');
    expect(r.id, greaterThan(0));
  });

  test(
    'nghỉ lễ: 7 ngày, chỉ ngày đầu của Tết, Giao thừa riêng, lễ đã qua bỏ',
    () {
      final now = DateTime(2027, 1, 20, 9);
      final list = buildReminders(
        events: const [],
        now: now,
        holidayRemindDays: 7,
      );
      final byTitle = {for (final r in list) r.title: r};
      expect(byTitle['Giao thừa']!.date, DateTime.utc(2027, 2, 5));
      expect(byTitle['Giao thừa']!.fireAt, DateTime(2027, 1, 29, 8));
      expect(byTitle['Tết Nguyên đán']!.date, DateTime.utc(2027, 2, 6));
      expect(byTitle['Tết Nguyên đán']!.fireAt, DateTime(2027, 1, 30, 8));
      expect(list.where((r) => r.title == 'Tết Nguyên đán').length, 1);
      expect(list.any((r) => r.date == DateTime.utc(2027, 1, 1)), isFalse);
      // Giỗ Tổ 10/3 âm 2027 trong 90 ngày.
      final gioTo = lunarToSolar(
        const LunarDate(day: 10, month: 3, year: 2027),
      )!;
      expect(list.any((r) => r.date == gioTo), isTrue);
      expect(byTitle['Giao thừa']!.body, startsWith(Strings.inDays(7)));
    },
  );

  test('holidayRemindDays 0 → không nhắc lễ', () {
    final list = buildReminders(
      events: const [],
      now: DateTime(2027, 1, 20),
      holidayRemindDays: 0,
    );
    expect(list, isEmpty);
  });

  test('bỏ mốc đã qua, ngoài 90 ngày, tombstone; sắp theo fireAt', () {
    final now = DateTime(2027, 1, 20, 12);
    final list = buildReminders(
      events: [
        // 22/01 nhắc trước 3 → 19/01 08:00 đã qua.
        ev('qua', day: 22, month: 1, type: CalendarType.solar, remind: 3),
        // 21/01 đúng ngày → 21/01 08:00 còn tới.
        ev('mai', day: 21, month: 1, type: CalendarType.solar, remind: 0),
        // Hôm nay 08:00 < 12:00 → đã qua.
        ev('nay', day: 20, month: 1, type: CalendarType.solar, remind: 0),
        // 30/04 = ngày thứ 100 → ngoài cửa sổ.
        ev('xa', day: 30, month: 4, type: CalendarType.solar, remind: 1),
        // 01/03 nhắc trước 7 → 22/02.
        ev('thang3', day: 1, month: 3, type: CalendarType.solar, remind: 7),
        ev(
          'xoa',
          day: 1,
          month: 2,
          type: CalendarType.solar,
          remind: 1,
          deletedAt: t0,
        ),
        ev('khongnhac', day: 1, month: 2, type: CalendarType.solar),
      ],
      now: now,
      holidayRemindDays: 0,
    );
    expect(list.map((r) => r.title), ['mai', 'thang3']);
    expect(list.first.fireAt, DateTime(2027, 1, 21, 8));
    expect(list.first.body, startsWith(Strings.today));
    expect(list.last.fireAt, DateTime(2027, 2, 22, 8));
  });

  test(
    'sự kiện nhiều ngày chỉ nhắc ngày đầu; leapRule both → 2 lần (2025 nhuận 6)',
    () {
      final now = DateTime(2025, 6, 1);
      final chinh = lunarToSolar(
        const LunarDate(day: 15, month: 6, year: 2025),
      )!;
      final nhuan = lunarToSolar(
        const LunarDate(day: 15, month: 6, year: 2025, isLeapMonth: true),
      )!;
      final list = buildReminders(
        events: [
          ev(
            'both',
            day: 15,
            month: 6,
            remind: 1,
            duration: 3,
            rule: LeapMonthRule.both,
          ),
        ],
        now: now,
        holidayRemindDays: 0,
      );
      expect(list.map((r) => r.date), [chinh, nhuan]);
      expect(
        list.first.fireAt,
        DateTime(chinh.year, chinh.month, chinh.day - 1, 8),
      );
    },
  );

  test('reminderId ổn định, dương, khác nhau theo sự kiện và ngày', () {
    final d1 = DateTime.utc(2027, 2, 6);
    final d2 = DateTime.utc(2027, 2, 7);
    expect(reminderId('a', d1), reminderId('a', d1));
    expect(reminderId('a', d1), isNot(reminderId('a', d2)));
    expect(reminderId('a', d1), isNot(reminderId('b', d1)));
    expect(reminderId('a', d1), greaterThan(0));
    expect(reminderId('a', d1), lessThanOrEqualTo(0x7fffffff));
  });
}
