// Cách phân biệt sự kiện app trên UI (D021): kind → màu, type → nhãn ÂL/DL.
import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';

import 'strings.dart';

/// Màu theo [EventKind]: nghỉ lễ đỏ, kỷ niệm cam, quốc tế xanh.
Color kindColor(EventKind kind) => switch (kind) {
  EventKind.vnHoliday => const Color(0xFFC62828),
  EventKind.vnMemorial => const Color(0xFFEF6C00),
  EventKind.international => const Color(0xFF1565C0),
};

/// Tên nhóm theo [EventKind].
String kindLabel(EventKind kind) => switch (kind) {
  EventKind.vnHoliday => Strings.kindHoliday,
  EventKind.vnMemorial => Strings.kindMemorial,
  EventKind.international => Strings.kindInternational,
};

/// "ÂL" / "DL" theo [CalendarType].
String typeTag(CalendarType type) =>
    type == CalendarType.lunar ? Strings.lunarTag : Strings.solarTag;

/// Nhãn nhỏ "ÂL"/"DL" nền màu theo kind của [event].
class EventTag extends StatelessWidget {
  const EventTag({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: kindColor(event.kind),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        typeTag(event.type),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
