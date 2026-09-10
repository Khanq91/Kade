import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../data/month_provider.dart';
import 'month_picker.dart';

/// Lưới tháng dương (plan §3.3). Tháng lấy từ route `/YYYY/MM` nên reload giữ tháng.
class MonthViewScreen extends ConsumerWidget {
  const MonthViewScreen({super.key, required this.year, required this.month});

  final int year;
  final int month;

  void _goMonth(BuildContext context, int y, int m) =>
      context.go(monthPath(y, m));

  void _shift(BuildContext context, int delta) {
    final d = DateTime.utc(year, month + delta);
    _goMonth(context, d.year, d.month);
  }

  Future<void> _pickSolar(BuildContext context) async {
    final r = await showSolarMonthPicker(context, year: year, month: month);
    if (r != null && context.mounted) _goMonth(context, r.$1, r.$2);
  }

  /// Chọn tháng âm → nhảy tới tháng dương chứa mùng 1 của tháng đó.
  Future<void> _pickLunar(BuildContext context, MonthData data) async {
    final first = data.days.values.first.info.lunar;
    final r = await showLunarMonthPicker(
      context,
      year: first.year,
      month: first.month,
    );
    if (r == null || !context.mounted) return;
    final solar = lunarToSolar(
      LunarDate(day: 1, month: r.month, year: r.year, isLeapMonth: r.isLeap),
    );
    if (solar != null) _goMonth(context, solar.year, solar.month);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(monthProvider((year, month)));
    final today = dateOnly(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () => _pickSolar(context),
          style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
          child: Text(
            Strings.monthTitle(month, year),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _pickLunar(context, data),
            child: const Text(Strings.lunarMonthButton),
          ),
          TextButton(
            onPressed: () => _goMonth(context, today.year, today.month),
            child: const Text(Strings.today),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _shift(context, 1);
          if (v > 200) _shift(context, -1);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: Strings.prevMonth,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _shift(context, -1),
                    ),
                    Expanded(
                      child: Text(
                        _lunarMonths(data),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: Strings.nextMonth,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _shift(context, 1),
                    ),
                  ],
                ),
                const _WeekdayHeader(),
                Expanded(
                  child: _MonthGrid(data: data, today: today),
                ),
                const _Legend(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tháng Chạp Bính Ngọ · Tháng Giêng Đinh Mùi": các tháng âm tháng dương này chạm tới.
String _lunarMonths(MonthData data) {
  final seen = <String>[];
  for (final c in data.days.values) {
    final l = c.info.lunar;
    final t = Strings.lunarMonthTitle(
      l.month,
      l.isLeapMonth,
      c.info.canChiYear,
    );
    if (seen.isEmpty || seen.last != t) seen.add(t);
  }
  return seen.join(' · ');
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                Strings.weekdaysShort[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: i == 6 ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.data, required this.today});

  final MonthData data;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final first = DateTime.utc(data.year, data.month, 1);
    final offset = first.weekday - DateTime.monday;
    final count = data.days.length;
    final rows = ((offset + count) / 7).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _tile(context, r * 7 + c - offset + 1)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, int day) {
    if (day < 1 || day > data.days.length) return const SizedBox.shrink();
    final cell = data.days[DateTime.utc(data.year, data.month, day)]!;
    return DayTile(
      key: ValueKey('day-${isoDate(cell.date)}'),
      cell: cell,
      isToday: cell.date == today,
      onTap: () => context.push(dayPath(cell.date)),
    );
  }
}

/// Một ô ngày: số dương, số âm (mùng 1 dạng "1/M"), nền nghỉ, viền hôm nay,
/// nhãn ÂL/DL màu theo kind (D021). Public để test đọc [cell].
class DayTile extends StatelessWidget {
  const DayTile({
    super.key,
    required this.cell,
    required this.isToday,
    required this.onTap,
  });

  final DayCell cell;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lunar = cell.info.lunar;
    final isSunday = cell.date.weekday == DateTime.sunday;
    final dayColor = cell.isOffDay || isSunday
        ? scheme.error
        : scheme.onSurface;
    final events = cell.appEvents;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
        decoration: BoxDecoration(
          color: cell.isOffDay ? scheme.errorContainer : null,
          border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${cell.date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: dayColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lunarCellText(lunar),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: lunar.day == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: lunar.day == 1
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (events.isNotEmpty)
                Flexible(
                  child: ClipRect(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (constraints.maxWidth >= 96)
                          Text(
                            events.first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: kindColor(events.first.kind),
                            ),
                          ),
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            for (final e in events.take(3)) EventTag(event: e),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          item(kindColor(EventKind.vnHoliday), Strings.kindHoliday),
          item(kindColor(EventKind.vnMemorial), Strings.kindMemorial),
          item(kindColor(EventKind.international), Strings.kindInternational),
          item(scheme.errorContainer, Strings.offDay),
          Text(Strings.tagLegend, style: style),
        ],
      ),
    );
  }
}
