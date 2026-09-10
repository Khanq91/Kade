import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../data/today_card.dart';

/// Hero card "hôm nay" ở panel phải web ≥ 1024 (plan §4.3); dữ liệu
/// [TodayCardData] dùng chung với widget Android (bước 17). Tap → DayDetail.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(todayCardProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = d.isOffDay ? scheme.error : scheme.primary;
    return Card(
      margin: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => openDay(context, d.date),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.weekday, style: text.titleMedium?.copyWith(color: accent)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${d.date.day}',
                    style: text.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: d.isOffDay ? scheme.error : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Strings.monthYearLong(d.date.month, d.date.year),
                      style: text.titleLarge,
                    ),
                  ),
                ],
              ),
              Text(
                '${Strings.lunarLabel} ${formatLunarShort(d.lunar)} · '
                '${Strings.yearLabel} ${d.canChiYear}',
                style: text.titleMedium,
              ),
              Text(
                '${Strings.canChiDayLabel} ${d.canChiDay}',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (d.isOffDay)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Chip(
                    label: const Text(Strings.offDay),
                    backgroundColor: scheme.errorContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              for (final e in d.events)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      TypeTag(type: e.type, color: Color(e.color)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
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
