import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../data/month_provider.dart';

/// Chi tiết một ngày (plan §3.4). Sự kiện cá nhân + "+ Thêm sự kiện": bước 7.
/// [asDialog]: đang nằm trong dialog (≥ 1024, bước 14) → nút Đóng thay Quay
/// lại. Esc đóng (plan §4.7).
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.date, this.asDialog = false});

  /// Ngày dương, 0h UTC.
  final DateTime date;

  final bool asDialog;

  /// Đổi ngày ±1 giữ nguyên cách hiện (dialog/trang) — có gì bên dưới thì vẫn
  /// là "mở từ trong app".
  void _shift(BuildContext context, int days) => context.pushReplacement(
    dayPath(date.add(Duration(days: days))),
    extra: context.canPop() ? dayDetailFromApp : null,
  );

  /// Mở từ MonthView → pop; mở thẳng bằng URL → về tháng chứa ngày.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(monthPath(date.year, date.month));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(dayCellProvider(date));
    final info = cell.info;
    final lunar = info.lunar;
    final dayChi = chi.indexOf(info.canChiDay.split(' ').last);
    final than = thanOfDay(chiIndexOfMonth(lunar.month), dayChi);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _back(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: asDialog ? Strings.close : Strings.back,
              icon: asDialog ? const Icon(Icons.close) : const BackButtonIcon(),
              onPressed: () => _back(context),
            ),
            title: Text(formatDate(date)),
            actions: [
              IconButton(
                tooltip: Strings.prevDay,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(context, -1),
              ),
              IconButton(
                tooltip: Strings.nextDay,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(context, 1),
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
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${weekdayName(date.weekday)}, ${formatDate(date)}',
                      style: text.headlineSmall,
                    ),
                    Text(
                      '${Strings.lunarLabel} ${formatLunarShort(lunar)} · '
                      '${Strings.yearLabel} ${info.canChiYear}',
                      style: text.titleMedium,
                    ),
                    if (cell.isOffDay)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: const Text(Strings.offDay),
                          backgroundColor: scheme.errorContainer,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InfoRow(
                              Strings.canChiMonthLabel,
                              '${info.canChiMonth} '
                              '(${Strings.lunarMonthLabel(lunar.month, lunar.isLeapMonth)})',
                            ),
                            _InfoRow(Strings.canChiDayLabel, info.canChiDay),
                            if (info.tietKhi != null)
                              _InfoRow(Strings.tietKhiLabel, info.tietKhi!),
                            _InfoRow(
                              info.isHoangDao
                                  ? Strings.hoangDaoDay
                                  : Strings.hacDaoDay,
                              than,
                              labelColor: info.isHoangDao
                                  ? const Color(0xFF2E7D32)
                                  : scheme.onSurfaceVariant,
                            ),
                            _InfoRow(
                              Strings.gioHoangDaoLabel,
                              info.gioHoangDao.join(', '),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(Strings.eventsTitle, style: text.titleMedium),
                    if (cell.appEvents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(Strings.noEvents),
                      )
                    else
                      for (final kind in EventKind.values)
                        if (cell.appEvents.any((e) => e.kind == kind)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              kindLabel(kind),
                              style: text.labelLarge?.copyWith(
                                color: kindColor(kind),
                              ),
                            ),
                          ),
                          for (final e in cell.appEvents.where(
                            (e) => e.kind == kind,
                          ))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: EventTag(event: e),
                              title: Text(e.title),
                              subtitle: e.description == null
                                  ? null
                                  : Text(e.description!),
                            ),
                        ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Strings.personalEvents,
                            style: text.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/events/new?date=${isoDate(date)}'),
                          icon: const Icon(Icons.add),
                          label: const Text(Strings.addEvent),
                        ),
                      ],
                    ),
                    if (cell.userEvents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(Strings.noUserEvents),
                      )
                    else
                      for (final e in cell.userEvents)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserEventTag(event: e),
                          title: Text(e.title),
                          subtitle: Text(e.note ?? formatUserEventWhen(e)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/events/${e.id}'),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.labelColor});

  final String label;
  final String value;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                color:
                    labelColor ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
  }
}
