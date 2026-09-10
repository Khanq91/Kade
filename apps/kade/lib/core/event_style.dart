// Cách phân biệt sự kiện trên UI (D021): kind → màu (sự kiện app), màu tự
// chọn (sự kiện cá nhân); type → nhãn ÂL/DL.
import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';

import '../data/models/user_event.dart';
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

/// Bảng màu sự kiện cá nhân; `UserEvent.colorIndex` là chỉ số trong bảng.
const List<Color> userEventColors = [
  Color(0xFF6A1B9A), // tím
  Color(0xFF00838F), // xanh ngọc
  Color(0xFF2E7D32), // xanh lá
  Color(0xFFAD1457), // hồng đậm
  Color(0xFF4527A0), // chàm
  Color(0xFF00695C), // lục lam
  Color(0xFF9E9D24), // ô liu
  Color(0xFF5D4037), // nâu
];

/// Màu của sự kiện cá nhân (chỉ số ngoài bảng → quay vòng).
Color userEventColor(UserEvent e) =>
    userEventColors[e.colorIndex % userEventColors.length];

/// "ÂL" / "DL" theo [CalendarType].
String typeTag(CalendarType type) =>
    type == CalendarType.lunar ? Strings.lunarTag : Strings.solarTag;

/// Nhãn nhỏ "ÂL"/"DL" nền [color].
class TypeTag extends StatelessWidget {
  const TypeTag({super.key, required this.type, required this.color});

  final CalendarType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        typeTag(type),
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

/// Nhãn của sự kiện app: màu theo kind.
class EventTag extends StatelessWidget {
  const EventTag({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) =>
      TypeTag(type: event.type, color: kindColor(event.kind));
}

/// Nhãn của sự kiện cá nhân: màu tự chọn.
class UserEventTag extends StatelessWidget {
  const UserEventTag({super.key, required this.event});

  final UserEvent event;

  @override
  Widget build(BuildContext context) =>
      TypeTag(type: event.type, color: userEventColor(event));
}
