import 'package:calendar_data/calendar_data.dart' show EventKind;

/// 4 lớp sự kiện bật/tắt ở "Sắp tới" (plan §3.6): 3 kind của sự kiện app + cá nhân.
enum EventLayer { vnHoliday, vnMemorial, international, personal }

/// Lớp của sự kiện app theo [EventKind].
EventLayer layerOfKind(EventKind kind) => switch (kind) {
  EventKind.vnHoliday => EventLayer.vnHoliday,
  EventKind.vnMemorial => EventLayer.vnMemorial,
  EventKind.international => EventLayer.international,
};
