// Nhắc nhở (plan §3.8): tính danh sách thông báo cần đặt trong 90 ngày tới từ
// sự kiện cá nhân có `remindBeforeDays` (âm → dương qua engine, leapRule D005)
// và ngày nghỉ lễ (settings "Nhắc lễ trước N ngày"), lúc 08:00 giờ máy, chỉ
// ngày đầu của sự kiện nhiều ngày. Pure: không Riverpod, không plugin.
import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:lunar_core/lunar_core.dart' show solarToLunar;

import '../core/formats.dart';
import '../core/strings.dart';
import 'models/user_event.dart';
import 'user_event_match.dart';

/// Giờ máy phát thông báo.
const reminderHour = 8;

/// Quét trước bao nhiêu ngày (plan §3.8).
const reminderHorizonDays = 90;

/// Một thông báo cần đặt.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.fireAt,
  });

  /// Ổn định theo (sự kiện, ngày diễn ra), dương 31 bit (int32 Android).
  final int id;
  final String title;
  final String body;

  /// Ngày diễn ra (0h UTC theo y/m/d).
  final DateTime date;

  /// Lúc phát, giờ máy (local).
  final DateTime fireAt;

  /// Route mở khi chạm: `/d/YYYY-MM-DD`.
  String get payload => '/d/${isoDate(date)}';
}

/// Thông báo cho [horizonDays] ngày từ ngày của [now] (giờ máy), bỏ mốc đã
/// qua, sắp theo [Reminder.fireAt]. [holidayRemindDays] 0 = không nhắc lễ.
List<Reminder> buildReminders({
  required List<UserEvent> events,
  required DateTime now,
  required int holidayRemindDays,
  int horizonDays = reminderHorizonDays,
  List<Event> holidays = vnHolidays,
}) {
  final today = dateOnly(now);
  final result = <Reminder>[];
  var prevUser = userEventsOn(today.subtract(const Duration(days: 1)), events);
  var prevApp = eventsOn(
    today.subtract(const Duration(days: 1)),
    events: holidays,
  );
  for (var i = 0; i <= horizonDays; i++) {
    final d = today.add(Duration(days: i));
    final users = userEventsOn(d, events);
    final apps = eventsOn(d, events: holidays);
    for (final e in users) {
      final before = e.remindBeforeDays;
      if (before == null || prevUser.any((x) => x.id == e.id)) continue;
      _add(result, id: e.id, title: e.title, date: d, before: before, now: now);
    }
    if (holidayRemindDays > 0) {
      for (final e in apps) {
        if (prevApp.contains(e)) continue;
        _add(
          result,
          id: e.id,
          title: e.title,
          date: d,
          before: holidayRemindDays,
          now: now,
        );
      }
    }
    prevUser = users;
    prevApp = apps;
  }
  result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return result;
}

void _add(
  List<Reminder> out, {
  required String id,
  required String title,
  required DateTime date,
  required int before,
  required DateTime now,
}) {
  final fireAt = DateTime(
    date.year,
    date.month,
    date.day - before,
    reminderHour,
  );
  if (!fireAt.isAfter(now)) return;
  out.add(
    Reminder(
      id: reminderId(id, date),
      title: title,
      body: reminderBody(before, date),
      date: date,
      fireAt: fireAt,
    ),
  );
}

/// Id thông báo: FNV-1a của "id|YYYY-MM-DD" (ổn định qua các lần chạy —
/// `Object.hash` thì không), giữ 31 bit dương.
int reminderId(String eventId, DateTime date) {
  var h = 0x811c9dc5;
  for (final c in '$eventId|${isoDate(date)}'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// "Còn 3 ngày · Thứ Bảy, 06/02/2027 (1/1 ÂL)" / "Hôm nay · …".
String reminderBody(int before, DateTime date) {
  final lunar = solarToLunar(date);
  final when =
      '${weekdayName(date.weekday)}, ${formatDate(date)} '
      '(${formatLunarShort(lunar)} ${Strings.lunarTag})';
  return '${before == 0 ? Strings.today : Strings.inDays(before)} · $when';
}
