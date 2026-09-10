// Dữ liệu widget Android (plan §5.2): Dart tính sẵn 35 ngày từ hôm nay (mỗi
// ngày = `TodayCardData`, ≤ 3 sự kiện theo lớp đang bật), native chỉ đọc JSON
// `days_json` và chọn ngày == hôm nay theo giờ máy → app không mở cả tháng
// widget vẫn đúng. Pure + provider.
import 'dart:convert';

import 'package:calendar_data/calendar_data.dart' show YearOverrides;
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/event_layer.dart';
import 'models/user_event.dart';
import 'month_provider.dart';
import 'settings_provider.dart';
import 'today_card.dart';
import 'upcoming_provider.dart';
import 'user_events_provider.dart';

/// Số ngày ghi cho widget.
const widgetDays = 35;

/// Key SharedPreferences native đọc (home_widget `saveWidgetData`).
const widgetDaysKey = 'days_json';

/// Gói dữ liệu cho widget: [days] liên tiếp từ ngày đầu.
@immutable
class WidgetData {
  const WidgetData({required this.generatedAt, required this.days});

  final DateTime generatedAt;
  final List<TodayCardData> days;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'days': [for (final d in days) d.toJson()],
  };

  String encode() => jsonEncode(toJson());
}

/// Từ ô lịch của từng ngày, giữ sự kiện thuộc [layers] (≤ 3 mỗi ngày).
WidgetData buildWidgetData(
  List<DayCell> cells, {
  required Set<EventLayer> layers,
  required DateTime generatedAt,
}) => WidgetData(
  generatedAt: generatedAt,
  days: [
    for (final c in cells)
      TodayCardData(
        date: c.date,
        lunar: c.info.lunar,
        canChiDay: c.info.canChiDay,
        canChiYear: c.info.canChiYear,
        isOffDay: c.isOffDay,
        events: TodayCardData.fromCell(
          c,
        ).events.where((e) => layers.contains(e.layer)).toList(),
      ),
  ],
);

/// [widgetDays] ngày từ [today], tính thẳng từ nguồn (`buildMonth` cho 1–2
/// tháng) — không qua cache provider để `WidgetUpdater` đọc ngay sau khi
/// sự kiện đổi vẫn lấy bản mới (E019).
WidgetData computeWidgetData({
  required DateTime today,
  required List<UserEvent> events,
  required YearOverrides overrides,
  required Set<EventLayer> layers,
  required DateTime generatedAt,
}) {
  final months = <(int, int), MonthData>{};
  final cells = [
    for (var i = 0; i < widgetDays; i++)
      if (today.add(Duration(days: i)) case final d)
        months.putIfAbsent(
          (d.year, d.month),
          () => buildMonth(d.year, d.month, overrides, userEvents: events),
        )[d]!,
  ];
  return buildWidgetData(cells, layers: layers, generatedAt: generatedAt);
}

/// [computeWidgetData] theo provider; tính lại khi hôm nay, sự kiện, overrides
/// hay lớp hiển thị đổi.
final widgetDataProvider = Provider<WidgetData>(
  (ref) => computeWidgetData(
    today: ref.watch(todayProvider),
    events: ref.watch(userEventsProvider),
    overrides: ref.watch(overridesProvider),
    layers: ref.watch(layersProvider),
    generatedAt: DateTime.now(),
  ),
);
