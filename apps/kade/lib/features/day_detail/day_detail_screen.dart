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
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';
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
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _back(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    _RoundIconButton(
                      tooltip: asDialog ? Strings.close : Strings.back,
                      icon: asDialog ? Icons.close : Icons.arrow_back,
                      onPressed: () => _back(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          formatDate(date),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    _RoundIconButton(
                      tooltip: Strings.prevDay,
                      icon: Icons.chevron_left,
                      onPressed: () => _shift(context, -1),
                      color: k?.acT,
                    ),
                    const SizedBox(width: 6),
                    _RoundIconButton(
                      tooltip: Strings.nextDay,
                      icon: Icons.chevron_right,
                      onPressed: () => _shift(context, 1),
                      color: k?.acT,
                    ),
                  ],
                ),
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  children: [
                    _HeroCard(
                      weekday: weekdayName(date.weekday),
                      dateLine: '${weekdayName(date.weekday)}, ${formatDate(date)}',
                      dayNum: '${date.day}',
                      monthYear: Strings.monthYearLong(date.month, date.year),
                      lunarShort: formatLunarShort(lunar),
                      lunarMonthName: Strings.lunarMonthLabel(
                        lunar.month,
                        lunar.isLeapMonth,
                      ),
                      canChiYear: info.canChiYear,
                    ),
                    if (cell.isOffDay) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: k?.off ?? scheme.errorContainer,
                            borderRadius: BorderRadius.circular(
                              kadePillRadius,
                            ),
                          ),
                          child: Text(
                            Strings.offDay,
                            style: TextStyle(
                              fontFamily: kadeBodyFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: k?.offT ?? scheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: k?.sf ?? scheme.surface,
                        borderRadius: BorderRadius.circular(kadeCardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: k?.sh ?? Colors.black12,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
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
                                : (k?.mu ?? scheme.onSurfaceVariant),
                          ),
                          _InfoRow(
                            Strings.gioHoangDaoLabel,
                            info.gioHoangDao.join(', '),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
                      child: Text(
                        Strings.eventsTitle,
                        style: TextStyle(
                          fontFamily: kadeDisplayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: k?.tx ?? scheme.onSurface,
                        ),
                      ),
                    ),
                    if (cell.appEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          Strings.noEvents,
                          style: TextStyle(
                            fontFamily: kadeBodyFont,
                            color: k?.mu ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final kind in EventKind.values)
                        if (cell.appEvents.any((e) => e.kind == kind)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
                            child: Text(
                              kindLabel(kind),
                              style: TextStyle(
                                fontFamily: kadeBodyFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                color: kindColor(kind),
                              ),
                            ),
                          ),
                          for (final e in cell.appEvents.where(
                            (e) => e.kind == kind,
                          ))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _EventRow(
                                tag: EventTag(event: e),
                                title: e.title,
                                subtitle: e.description,
                              ),
                            ),
                        ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Strings.personalEvents,
                            style: TextStyle(
                              fontFamily: kadeDisplayFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: k?.tx ?? scheme.onSurface,
                            ),
                          ),
                        ),
                        _AddEventButton(
                          onPressed: () => context.push(
                            '/events/new?date=${isoDate(date)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (cell.userEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          Strings.noUserEvents,
                          style: TextStyle(
                            fontFamily: kadeBodyFont,
                            color: k?.mu ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final e in cell.userEvents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _EventRow(
                            tag: UserEventTag(event: e),
                            title: e.title,
                            subtitle: e.note ?? formatUserEventWhen(e),
                            onTap: () => context.push('/events/${e.id}'),
                          ),
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

/// Nút tròn (back/prev/next) nền `sf`, bóng nhẹ. Private trong file này —
/// giống style dùng ở màn Lịch tháng nhưng định nghĩa riêng (Phase 3 không
/// import xuyên feature).
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: k?.sf ?? scheme.surfaceContainer,
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: k?.sh,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: color ?? k?.tx ?? scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero 2 cột: dương (trái) / âm (phải) — `.dc.html` §isDay `day.heroStyle`.
/// [weekday] và [dateLine] tách riêng vì test đọc đúng dòng
/// `"$weekday, $formatDate"` (`Thứ Bảy, 06/02/2027`) làm 1 khối.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.weekday,
    required this.dateLine,
    required this.dayNum,
    required this.monthYear,
    required this.lunarShort,
    required this.lunarMonthName,
    required this.canChiYear,
  });

  final String weekday;
  final String dateLine;
  final String dayNum;
  final String monthYear;
  final String lunarShort;
  final String lunarMonthName;
  final String canChiYear;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: k?.ac1 ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(kadeCardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLine,
                  style: TextStyle(
                    fontFamily: kadeBodyFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: k?.acT ?? scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontFamily: kadeDisplayFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 52,
                    height: 1,
                    color: k?.tx ?? scheme.onSurface,
                  ),
                ),
                Text(
                  monthYear,
                  style: TextStyle(
                    fontFamily: kadeBodyFont,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: k?.mu ?? scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Strings.lunarLabel} $lunarShort · ${Strings.yearLabel} $canChiYear',
                style: TextStyle(
                  fontFamily: kadeBodyFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.7,
                  color: k?.acT ?? scheme.primary,
                ),
              ),
              Text(
                lunarShort,
                style: TextStyle(
                  fontFamily: kadeDisplayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: k?.acT ?? scheme.primary,
                ),
              ),
              Text(
                lunarMonthName,
                style: TextStyle(
                  fontFamily: kadeBodyFont,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: k?.mu ?? scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 1 dòng sự kiện (app hoặc cá nhân): tag trái, tiêu đề + phụ đề, ▶ nếu
/// [onTap] (sự kiện cá nhân, bấm để sửa) — `.dc.html` §isDay `e`/`u`.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.tag,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final Widget tag;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: k?.sf ?? scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: k?.sh ?? Colors.black12,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          tag,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: kadeBodyFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: k?.tx ?? scheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: kadeBodyFont,
                      fontSize: 12,
                      color: k?.mu ?? scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 18,
              color: k?.mu ?? scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Nút pill "+ Thêm sự kiện" nền `ac` — `.dc.html` §isDay `newEventHere`.
class _AddEventButton extends StatelessWidget {
  const _AddEventButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: k?.ac ?? scheme.primary,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: k?.on ?? scheme.onPrimary),
              const SizedBox(width: 4),
              Text(
                Strings.addEvent,
                style: TextStyle(
                  fontFamily: kadeBodyFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: k?.on ?? scheme.onPrimary,
                ),
              ),
            ],
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
