// Dữ liệu "hôm nay" dùng chung cho hero card web (plan §4.3) và widget Android
// (plan §5.2, bước 17): chỉ dữ liệu + toJson, không widget.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunar_core/lunar_core.dart' show LunarDate;

import '../core/event_style.dart';
import '../core/formats.dart';
import 'models/event_layer.dart';
import 'month_provider.dart';
import 'upcoming_provider.dart';

/// Một sự kiện rút gọn trên card/widget.
@immutable
class CardEvent {
  const CardEvent({
    required this.title,
    required this.type,
    required this.layer,
    required this.color,
  });

  final String title;
  final CalendarType type;
  final EventLayer layer;

  /// Màu ARGB (kind hoặc màu tự chọn).
  final int color;

  Map<String, Object?> toJson() => {
    'title': title,
    'type': type.name,
    'layer': layer.name,
    'color': color,
  };
}

/// Một ngày cho card/widget: dương, âm, can chi, nghỉ, ≤ [maxEvents] sự kiện
/// (sự kiện app trước, cá nhân sau).
@immutable
class TodayCardData {
  const TodayCardData({
    required this.date,
    required this.lunar,
    required this.canChiDay,
    required this.canChiYear,
    required this.isOffDay,
    required this.events,
  });

  static const maxEvents = 3;

  factory TodayCardData.fromCell(DayCell cell) => TodayCardData(
    date: cell.date,
    lunar: cell.info.lunar,
    canChiDay: cell.info.canChiDay,
    canChiYear: cell.info.canChiYear,
    isOffDay: cell.isOffDay,
    events: [
      for (final e in cell.appEvents)
        CardEvent(
          title: e.title,
          type: e.type,
          layer: layerOfKind(e.kind),
          color: kindColor(e.kind).toARGB32(),
        ),
      for (final e in cell.userEvents)
        CardEvent(
          title: e.title,
          type: e.type,
          layer: EventLayer.personal,
          color: userEventColor(e).toARGB32(),
        ),
    ].take(maxEvents).toList(),
  );

  /// Ngày dương, 0h UTC.
  final DateTime date;
  final LunarDate lunar;
  final String canChiDay;
  final String canChiYear;
  final bool isOffDay;
  final List<CardEvent> events;

  /// "Thứ Tư".
  String get weekday => weekdayName(date.weekday);

  Map<String, Object?> toJson() => {
    'date': isoDate(date),
    'weekday': weekday,
    'solarDay': date.day,
    'solarMonth': date.month,
    'solarYear': date.year,
    'lunarDay': lunar.day,
    'lunarMonth': lunar.month,
    'lunarYear': lunar.year,
    'isLeapMonth': lunar.isLeapMonth,
    'canChiDay': canChiDay,
    'canChiYear': canChiYear,
    'isOffDay': isOffDay,
    'events': [for (final e in events) e.toJson()],
  };
}

/// Card "hôm nay" theo [todayProvider] (tính lại qua ngày, D032) và cache tháng.
final todayCardProvider = Provider<TodayCardData>((ref) {
  final today = ref.watch(todayProvider);
  return TodayCardData.fromCell(ref.watch(dayCellProvider(today)));
});
