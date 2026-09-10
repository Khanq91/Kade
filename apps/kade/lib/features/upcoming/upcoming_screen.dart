import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../data/models/event_layer.dart';
import '../../data/settings_provider.dart';
import '../../data/upcoming_provider.dart';

/// "Sắp tới" (plan §3.6): 4 chip lớp + danh sách 60 ngày gom theo ngày.
class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.upcomingTitle)),
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
/// lịch tháng ≥ 600, bước 14): không chip, dòng gọn không phụ đề.
class UpcomingList extends ConsumerWidget {
  const UpcomingList({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(upcomingProvider);
    final layers = ref.watch(layersProvider);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final l in EventLayer.values)
                  FilterChip(
                    avatar: Icon(Icons.circle, size: 12, color: layerColor(l)),
                    label: Text(layerLabel(l)),
                    selected: layers.contains(l),
                    onSelected: (_) =>
                        ref.read(layersProvider.notifier).toggle(l),
                  ),
              ],
            ),
          ),
        Expanded(
          child: days.isEmpty
              ? const Center(child: Text(Strings.noUpcoming))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final day in days) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          compact ? 10 : 16,
                          16,
                          compact ? 0 : 4,
                        ),
                        child: Text(
                          '${relativeDayLabel(day.daysFromToday)} · '
                          '${weekdayName(day.date.weekday)}, ${formatDate(day.date)} · '
                          '${formatLunarShort(day.cell.info.lunar)} ${Strings.lunarTag}',
                          style: (compact ? text.labelLarge : text.titleSmall)
                              ?.copyWith(
                                color: day.daysFromToday == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                      ),
                      for (final item in day.items)
                        ListTile(
                          dense: true,
                          visualDensity: compact
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                          leading: TypeTag(
                            type: item.type,
                            color: item.appEvent != null
                                ? kindColor(item.appEvent!.kind)
                                : userEventColor(item.userEvent!),
                          ),
                          title: Text(item.title),
                          subtitle: compact
                              ? null
                              : Text(
                                  [
                                    layerLabel(item.layer),
                                    if (item.durationDays > 1)
                                      Strings.daysCount(item.durationDays),
                                  ].join(' · '),
                                ),
                          onTap: () => openDay(context, day.date),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// "Hôm nay" / "Ngày mai" / "Còn N ngày".
String relativeDayLabel(int daysFromToday) => switch (daysFromToday) {
  0 => Strings.today,
  1 => Strings.tomorrow,
  _ => Strings.inDays(daysFromToday),
};
