import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/breakpoints.dart';
import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/lunar_utils.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';
import '../../data/month_provider.dart';
import '../../data/settings_provider.dart';
import '../../data/upcoming_provider.dart';
import '../upcoming/upcoming_screen.dart';
import 'month_picker.dart';
import 'today_card.dart';

const _monthHeaderHeight = 140.0;

/// Lưới tháng dương (plan §3.3). Tháng lấy từ route `/YYYY/MM` nên reload giữ
/// tháng. [lunar] (`?lunar=1`, D033): ◀ ▶ nhảy theo tháng âm. Layout theo
/// bề rộng (plan §4.2): ≥ 1024 thêm panel phải (hero hôm nay + Sắp tới),
/// 600–1023 Sắp tới dưới lưới. Phím: ← → đổi tháng, T hôm nay (plan §4.7).
class MonthViewScreen extends ConsumerWidget {
  const MonthViewScreen({
    super.key,
    required this.year,
    required this.month,
    this.lunar = false,
  });

  final int year;
  final int month;

  /// Đang duyệt theo tháng âm.
  final bool lunar;

  void _goMonth(BuildContext context, int y, int m, {bool lunar = false}) =>
      context.go(monthPath(y, m, lunar: lunar));

  void _shift(BuildContext context, int delta) {
    if (lunar) {
      final (y, m) = shiftLunarMonth(year, month, delta);
      _goMonth(context, y, m, lunar: true);
    } else {
      final d = DateTime.utc(year, month + delta);
      _goMonth(context, d.year, d.month);
    }
  }

  Future<void> _pickSolar(BuildContext context) async {
    final r = await showSolarMonthPicker(context, year: year, month: month);
    if (r != null && context.mounted) _goMonth(context, r.$1, r.$2);
  }

  /// Chọn tháng âm → nhảy tới tháng dương chứa mùng 1 của tháng đó, bật
  /// chế độ duyệt theo tháng âm.
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
    if (solar != null) _goMonth(context, solar.year, solar.month, lunar: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(monthProvider((year, month)));
    final today = ref.watch(todayProvider);
    final layout = layoutOf(MediaQuery.sizeOf(context).width);
    final lunarMonths = _lunarMonths(data);
    final calendar = MonthCalendar(
      data: data,
      today: today,
      onShift: (delta) => _shift(context, delta),
    );
    final Widget body = switch (layout) {
      AppLayout.wide => Row(
        children: [
          Expanded(flex: 65, child: calendar),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 35,
            child: Column(
              children: [
                const TodayCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Strings.upcomingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const Expanded(child: UpcomingList(compact: true)),
              ],
            ),
          ),
        ],
      ),
      AppLayout.medium => Column(
        children: [
          Expanded(flex: 3, child: calendar),
          const Divider(height: 1),
          const Expanded(flex: 2, child: UpcomingList(compact: true)),
        ],
      ),
      AppLayout.compact => calendar,
    };
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _shift(context, -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _shift(context, 1),
        const SingleActivator(LogicalKeyboardKey.keyT): () =>
            _goMonth(context, today.year, today.month),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(_monthHeaderHeight),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: _MonthHeader(
                  monthTitle: Strings.monthTitle(month, year),
                  lunarMonths: lunarMonths,
                  onPickMonth: () => _pickSolar(context),
                  onPrev: () => _shift(context, -1),
                  onNext: () => _shift(context, 1),
                  lunarActive: lunar,
                  onToggleLunar: () => _pickLunar(context, data),
                  onToday: () => _goMonth(context, today.year, today.month),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              if (ref.watch(webNoticeProvider)) const _WebNotice(),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header màn Lịch tháng theo thiết kế mới (`.dc.html` §isMonth): nút tròn
/// ◀ ▶ (tap = đổi tháng dương), tiêu đề Baloo 2 (tap = mở picker tháng
/// dương) + dòng tháng âm nhỏ màu `acT` ngay dưới, pill "Tháng âm" (tap =
/// mở picker tháng âm — plan giữ nguyên hành vi cũ, không thêm nút bật/tắt
/// chế độ) + pill "Hôm nay". Chuyển từ 2 `IconButton` + dòng tháng âm cũ
/// trong [MonthCalendar] lên đây (`_lunarMonths(data)` tính 1 lần trong
/// `build()`, không đụng logic tính).
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthTitle,
    required this.lunarMonths,
    required this.onPickMonth,
    required this.onPrev,
    required this.onNext,
    required this.lunarActive,
    required this.onToggleLunar,
    required this.onToday,
  });

  final String monthTitle;
  final String lunarMonths;
  final VoidCallback onPickMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool lunarActive;
  final VoidCallback onToggleLunar;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RoundIconButton(
              tooltip: Strings.prevMonth,
              icon: Icons.chevron_left,
              onPressed: onPrev,
            ),
            Expanded(
              child: TextButton(
                onPressed: onPickMonth,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      lunarMonths,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kadeBodyFont,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                        color: k?.acT,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _RoundIconButton(
              tooltip: Strings.nextMonth,
              icon: Icons.chevron_right,
              onPressed: onNext,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PillButton(
                label: Strings.lunarMonthButton,
                onPressed: onToggleLunar,
                selected: lunarActive,
                selectedColor: k?.ac2,
                foregroundColor: k?.acT,
              ),
              const SizedBox(width: 8),
              _PillButton(
                label: Strings.today,
                onPressed: onToday,
                selected: true,
                selectedColor: k?.ac,
                foregroundColor: k?.on,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Nút tròn (back/prev/next) nền `sf`, bóng nhẹ. Private trong file này —
/// các phase sau (Chi tiết ngày, Giao diện, Sự kiện của tôi) định nghĩa
/// widget tương tự riêng theo cùng phong cách nếu cần (không import từ đây).
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

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
            child: Icon(icon, size: 22, color: k?.acT ?? scheme.primary),
          ),
        ),
      ),
    );
  }
}

/// Nút pill bo tròn hoàn toàn (999px) dùng cho "Tháng âm"/"Hôm nay" và các
/// nút hành động nhỏ theo thiết kế mới.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.selected,
    this.selectedColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final Color? selectedColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? (selectedColor ?? k?.ac) : (k?.sf ?? scheme.surface);
    final fg = selected
        ? (foregroundColor ?? k?.on)
        : (k?.acT ?? scheme.primary);
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      elevation: selected ? 0 : 1,
      shadowColor: k?.sh,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kadeBodyFont,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cảnh báo một lần trên web (plan §4.4): dữ liệu nằm trong trình duyệt.
class _WebNotice extends ConsumerWidget {
  const _WebNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(webNoticeProvider.notifier);
    return MaterialBanner(
      key: const ValueKey('web-notice'),
      leading: const Icon(Icons.info_outline),
      content: const Text(Strings.webStorageNotice),
      actions: [
        TextButton(
          key: const ValueKey('web-notice-sync'),
          onPressed: () {
            notifier.dismiss();
            context.go('/settings');
          },
          child: const Text(Strings.enableSync),
        ),
        TextButton(
          key: const ValueKey('web-notice-ok'),
          onPressed: notifier.dismiss,
          child: const Text(Strings.gotIt),
        ),
      ],
    );
  }
}

/// Phần lịch: header thứ, lưới ô ngày, chú giải; vuốt trái/phải đổi tháng
/// (◀ ▶ và dòng tháng âm chuyển lên `_MonthHeader` trong AppBar — Phase 1).
/// Public để test tìm chú giải trong đúng phần này (panel Sắp tới nằm ngoài).
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.data,
    required this.today,
    required this.onShift,
  });

  final MonthData data;
  final DateTime today;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) onShift(1);
        if (v > 200) onShift(-1);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _WeekdayHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _MonthGrid(data: data, today: today),
                ),
              ),
              const _Legend(),
            ],
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
    final k = Theme.of(context).extension<KadeColors>();
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
                  fontFamily: kadeBodyFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: i == 6
                      ? (k?.sun ?? scheme.error)
                      : (k?.mu ?? scheme.onSurfaceVariant),
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
      onTap: () => openDay(context, cell.date),
    );
  }
}

/// Một ô ngày: số dương, số âm (mùng 1 dạng "1/M"), nền nghỉ, viền hôm nay,
/// nhãn ÂL/DL màu theo kind (D021). Public để test đọc [cell].
///
/// Thiết kế mới (`.dc.html` §isMonth `c.style`, Phase 1): mỗi ô là 1 thẻ bo
/// góc riêng biệt (nền `sf`/`off`/`ac` tùy trạng thái, bóng nhẹ) thay vì ô
/// liền nhau trong suốt như bản cũ — [Container] đầu tiên bên trong
/// [InkWell] vẫn là nơi tô nền/bo góc (test `month_view_test.dart` đọc
/// đúng widget này). Cơ chế `LayoutBuilder` quyết định hiện/ẩn tên sự kiện
/// theo `constraints.maxWidth`, và `EventTag`/`UserEventTag` trong ô, giữ
/// nguyên 100% theo yêu cầu plan §3 — chỉ đổi style bọc ngoài.
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
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final lunar = cell.info.lunar;
    final isSunday = cell.date.weekday == DateTime.sunday;
    final Color tileBg = isToday
        ? (k?.ac ?? scheme.primary)
        : cell.isOffDay
        ? (k?.off ?? scheme.errorContainer)
        : (k?.sf ?? scheme.surface);
    final Color dayColor = isToday
        ? (k?.on ?? scheme.onPrimary)
        : cell.isOffDay
        ? (k?.offT ?? scheme.error)
        : isSunday
        ? (k?.sun ?? scheme.error)
        : (k?.tx ?? scheme.onSurface);
    final Color lunarColor = isToday
        ? (k?.on ?? scheme.onPrimary)
        : lunar.day == 1
        ? (k?.acT ?? scheme.primary)
        : (k?.mu ?? scheme.onSurfaceVariant);
    final events = cell.appEvents;
    final userEvents = cell.userEvents;
    // Tên hiện trong ô: sự kiện app trước, không có thì sự kiện cá nhân.
    final (String? firstTitle, Color? firstColor) = events.isNotEmpty
        ? (events.first.title, kindColor(events.first.kind))
        : userEvents.isNotEmpty
        ? (userEvents.first.title, userEventColor(userEvents.first))
        : (null, null);
    final tags = <Widget>[
      for (final e in events) EventTag(event: e),
      for (final e in userEvents) UserEventTag(event: e),
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kadeDayTileRadius),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(kadeDayTileRadius),
            boxShadow: [
              BoxShadow(
                color: k?.sh ?? Colors.black12,
                blurRadius: isToday ? 12 : 2,
                offset: Offset(0, isToday ? 4 : 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cell.date.day}',
                      style: TextStyle(
                        fontFamily: kadeDisplayFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dayColor,
                      ),
                    ),
                    Text(
                      lunarCellText(lunar),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: kadeBodyFont,
                        fontSize: 10.5,
                        fontWeight: lunar.day == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: lunarColor,
                      ),
                    ),
                    if (tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (constraints.maxWidth >= 96 &&
                                firstTitle != null)
                              Text(
                                firstTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kadeBodyFont,
                                  fontSize: 10,
                                  color: isToday ? dayColor : firstColor,
                                ),
                              ),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: tags.take(3).toList(),
                            ),
                          ],
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final k = Theme.of(context).extension<KadeColors>();
    final scheme = Theme.of(context).colorScheme;
    final dotStyle = TextStyle(
      fontFamily: kadeBodyFont,
      fontWeight: FontWeight.w500,
      fontSize: 10.5,
      color: k?.mu ?? scheme.onSurfaceVariant,
    );
    Widget pill(
      String label, {
      Color? dotColor,
      Color? bg,
      Color? fg,
    }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? k?.sf ?? scheme.surface,
        borderRadius: BorderRadius.circular(kadePillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: fg != null ? dotStyle.copyWith(color: fg) : dotStyle,
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          pill(Strings.kindHoliday, dotColor: kindColor(EventKind.vnHoliday)),
          pill(
            Strings.kindMemorial,
            dotColor: kindColor(EventKind.vnMemorial),
          ),
          pill(
            Strings.kindInternational,
            dotColor: kindColor(EventKind.international),
          ),
          pill(
            Strings.offDay,
            bg: k?.off ?? scheme.errorContainer,
            fg: k?.offT ?? scheme.error,
          ),
          Text(Strings.tagLegend, style: dotStyle),
        ],
      ),
    );
  }
}
