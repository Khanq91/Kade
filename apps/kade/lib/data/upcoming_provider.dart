// "Sắp tới" (plan §3.6): quét 60 ngày từ hôm nay qua cache tháng, gom theo ngày,
// lọc theo lớp đang bật. Sự kiện nhiều ngày chỉ liệt kê ở ngày bắt đầu (hoặc ở
// "Hôm nay" nếu đang diễn ra).
import 'package:calendar_data/calendar_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formats.dart';
import 'models/event_layer.dart';
import 'models/user_event.dart';
import 'month_provider.dart';
import 'settings_provider.dart';

/// Hôm nay (0h UTC theo y/m/d máy); tính lúc tạo provider, test override.
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

/// Số ngày quét, kể cả hôm nay.
const upcomingWindowDays = 60;

/// Một dòng "Sắp tới": đúng một trong [appEvent] / [userEvent] khác null.
class UpcomingItem {
  const UpcomingItem({required this.date, this.appEvent, this.userEvent})
    : assert((appEvent == null) != (userEvent == null));

  /// Ngày dương diễn ra (ngày bắt đầu, hoặc hôm nay nếu đang diễn ra).
  final DateTime date;
  final Event? appEvent;
  final UserEvent? userEvent;

  String get title => appEvent?.title ?? userEvent!.title;
  CalendarType get type => appEvent?.type ?? userEvent!.type;
  int get durationDays => appEvent?.durationDays ?? userEvent!.durationDays;
  EventLayer get layer =>
      appEvent != null ? layerOfKind(appEvent!.kind) : EventLayer.personal;
}

/// Các sự kiện của một ngày trong cửa sổ; [daysFromToday] 0 = hôm nay.
class UpcomingDay {
  const UpcomingDay({
    required this.cell,
    required this.daysFromToday,
    required this.items,
  });

  final DayCell cell;
  final int daysFromToday;
  final List<UpcomingItem> items;

  DateTime get date => cell.date;
}

/// Ngày có sự kiện trong [upcomingWindowDays] ngày tới, theo lớp đang bật.
final upcomingProvider = Provider<List<UpcomingDay>>((ref) {
  final today = ref.watch(todayProvider);
  final layers = ref.watch(layersProvider);
  DayCell cellOf(DateTime d) => ref.watch(monthProvider((d.year, d.month)))[d]!;

  final result = <UpcomingDay>[];
  for (var i = 0; i < upcomingWindowDays; i++) {
    final d = today.add(Duration(days: i));
    final cell = cellOf(d);
    final prev = cellOf(d.subtract(const Duration(days: 1)));
    final items = <UpcomingItem>[
      for (final e in cell.appEvents)
        if (layers.contains(layerOfKind(e.kind)) &&
            (i == 0 || !prev.appEvents.contains(e)))
          UpcomingItem(date: d, appEvent: e),
      if (layers.contains(EventLayer.personal))
        for (final e in cell.userEvents)
          if (i == 0 || !prev.userEvents.any((x) => x.id == e.id))
            UpcomingItem(date: d, userEvent: e),
    ];
    if (items.isNotEmpty) {
      result.add(UpcomingDay(cell: cell, daysFromToday: i, items: items));
    }
  }
  return result;
});
