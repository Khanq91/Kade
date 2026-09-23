import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';
import '../../data/models/event_layer.dart';
import '../../data/settings_provider.dart';
import '../../data/upcoming_provider.dart';

/// "Sắp tới" (plan §3.6): 4 chip lớp + danh sách 60 ngày gom theo ngày.
class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.upcomingTitle),
        titleTextStyle: TextStyle(
          fontFamily: kadeDisplayFont,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: const UpcomingList(),
        ),
      ),
    );
  }
}

/// Danh sách "Sắp tới": chip lớp + các ngày gom nhóm. [compact] (nhúng vào
/// lịch tháng ≥ 600, bước 14): không chip, dòng gọn không phụ đề — giữ
/// nguyên style tối giản cũ, thiết kế mới (`.dc.html` §isUpcoming) chỉ áp
/// cho màn Sắp tới độc lập (!compact).
class UpcomingList extends ConsumerWidget {
  const UpcomingList({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(upcomingProvider);
    final layers = ref.watch(layersProvider);
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final l in EventLayer.values)
                  FilterChip(
                    avatar: Icon(Icons.circle, size: 8, color: layerColor(l)),
                    label: Text(layerLabel(l)),
                    labelStyle: TextStyle(
                      fontFamily: kadeBodyFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: layers.contains(l)
                          ? (k?.tx ?? scheme.onSurface)
                          : (k?.mu ?? scheme.onSurfaceVariant),
                    ),
                    selected: layers.contains(l),
                    showCheckmark: false,
                    selectedColor: k?.sf ?? scheme.surface,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: layers.contains(l)
                          ? Colors.transparent
                          : (k?.line ?? scheme.outlineVariant),
                      width: 1.5,
                    ),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        ref.read(layersProvider.notifier).toggle(l),
                  ),
              ],
            ),
          ),
        Expanded(
          child: days.isEmpty
              ? Center(
                  child: Text(
                    Strings.noUpcoming,
                    style: TextStyle(
                      fontFamily: kadeBodyFont,
                      color: k?.mu ?? scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 10,
                    0,
                    compact ? 16 : 10,
                    16,
                  ),
                  children: [
                    for (final day in days)
                      if (compact)
                        _CompactDayGroup(day: day, text: text)
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _UpcomingDayCard(day: day),
                        ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Nhóm ngày ở dạng gọn (bản cũ, dùng trong panel Lịch tháng ≥ 600).
class _CompactDayGroup extends StatelessWidget {
  const _CompactDayGroup({required this.day, required this.text});

  final UpcomingDay day;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            '${relativeDayLabel(day.daysFromToday)} · '
            '${weekdayName(day.date.weekday)}, ${formatDate(day.date)} · '
            '${formatLunarShort(day.cell.info.lunar)} ${Strings.lunarTag}',
            style: text.labelLarge?.copyWith(
              color: day.daysFromToday == 0
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ),
        for (final item in day.items)
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: TypeTag(
              type: item.type,
              color: item.appEvent != null
                  ? kindColor(item.appEvent!.kind)
                  : userEventColor(item.userEvent!),
            ),
            title: Text(item.title),
            onTap: () => openDay(context, day.date),
          ),
      ],
    );
  }
}

/// 1 ngày trong "Sắp tới" (`.dc.html` §isUpcoming `d`): badge số ngày +
/// tháng viết tắt (nền `ac` nếu hôm nay, `ac1` nếu không), nhãn tương đối
/// đậm + dòng phụ (thứ, ngày, âm lịch), rồi tới danh sách sự kiện trong
/// ngày đó.
class _UpcomingDayCard extends StatelessWidget {
  const _UpcomingDayCard({required this.day});

  final UpcomingDay day;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final isToday = day.daysFromToday == 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: k?.sf ?? scheme.surface,
        borderRadius: BorderRadius.circular(kadeCardRadius - 2),
        boxShadow: [
          BoxShadow(
            color: k?.sh ?? Colors.black12,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? (k?.ac ?? scheme.primary)
                        : (k?.ac1 ?? scheme.primaryContainer),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${day.date.day}',
                        style: TextStyle(
                          fontFamily: kadeDisplayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1,
                          color: isToday
                              ? (k?.on ?? scheme.onPrimary)
                              : (k?.acT ?? scheme.primary),
                        ),
                      ),
                      Text(
                        Strings.monthShort(day.date.month),
                        style: TextStyle(
                          fontFamily: kadeBodyFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          letterSpacing: 0.5,
                          height: 1,
                          color: isToday
                              ? (k?.on ?? scheme.onPrimary)
                              : (k?.acT ?? scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relativeDayLabel(day.daysFromToday),
                        style: TextStyle(
                          fontFamily: kadeBodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isToday
                              ? (k?.acT ?? scheme.primary)
                              : (k?.tx ?? scheme.onSurface),
                        ),
                      ),
                      Text(
                        '${weekdayName(day.date.weekday)}, ${formatDate(day.date)} · '
                        '${formatLunarShort(day.cell.info.lunar)} ${Strings.lunarTag}',
                        style: TextStyle(
                          fontFamily: kadeBodyFont,
                          fontSize: 12,
                          color: k?.mu ?? scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final item in day.items)
            _UpcomingItemRow(
              item: item,
              onTap: () => openDay(context, day.date),
            ),
        ],
      ),
    );
  }
}

class _UpcomingItemRow extends StatelessWidget {
  const _UpcomingItemRow({required this.item, required this.onTap});

  final UpcomingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              TypeTag(
                type: item.type,
                color: item.appEvent != null
                    ? kindColor(item.appEvent!.kind)
                    : userEventColor(item.userEvent!),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: kadeBodyFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: k?.tx ?? scheme.onSurface,
                      ),
                    ),
                    Text(
                      [
                        layerLabel(item.layer),
                        if (item.durationDays > 1)
                          Strings.daysCount(item.durationDays),
                      ].join(' · '),
                      style: TextStyle(
                        fontFamily: kadeBodyFont,
                        fontSize: 12,
                        color: k?.mu ?? scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Hôm nay" / "Ngày mai" / "Còn N ngày".
String relativeDayLabel(int daysFromToday) => switch (daysFromToday) {
  0 => Strings.today,
  1 => Strings.tomorrow,
  _ => Strings.inDays(daysFromToday),
};
