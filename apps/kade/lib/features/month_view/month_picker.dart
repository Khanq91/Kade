// Picker tháng/năm dương và tháng âm cho MonthView (plan §3.3).
import 'package:flutter/material.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/strings.dart';

/// Dialog chọn tháng/năm dương → `(year, month)`, hoặc `null` nếu hủy.
Future<(int, int)?> showSolarMonthPicker(
  BuildContext context, {
  required int year,
  required int month,
}) => showDialog<(int, int)>(
  context: context,
  builder: (_) => _SolarMonthPicker(year: year, month: month),
);

/// Dialog chọn tháng âm (kể cả tháng nhuận nếu năm có), hoặc `null` nếu hủy.
Future<({int year, int month, bool isLeap})?> showLunarMonthPicker(
  BuildContext context, {
  required int year,
  required int month,
}) => showDialog<({int year, int month, bool isLeap})>(
  context: context,
  builder: (_) => _LunarMonthPicker(year: year, month: month),
);

/// Tháng nhuận của năm âm [lunarYear], hoặc `null` nếu năm không nhuận.
int? leapMonthOf(int lunarYear) {
  for (var m = 1; m <= 12; m++) {
    final d = LunarDate(day: 1, month: m, year: lunarYear, isLeapMonth: true);
    if (lunarToSolar(d) != null) return m;
  }
  return null;
}

class _SolarMonthPicker extends StatefulWidget {
  const _SolarMonthPicker({required this.year, required this.month});

  final int year;
  final int month;

  @override
  State<_SolarMonthPicker> createState() => _SolarMonthPickerState();
}

class _SolarMonthPickerState extends State<_SolarMonthPicker> {
  late int _year = widget.year;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.pickMonth),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _YearStepper(
              label: '$_year',
              onChanged: (y) => setState(() => _year = y),
              year: _year,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  ChoiceChip(
                    label: Text('$m'),
                    selected: _year == widget.year && m == widget.month,
                    onSelected: (_) => Navigator.pop(context, (_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
      ],
    );
  }
}

class _LunarMonthPicker extends StatefulWidget {
  const _LunarMonthPicker({required this.year, required this.month});

  final int year;
  final int month;

  @override
  State<_LunarMonthPicker> createState() => _LunarMonthPickerState();
}

class _LunarMonthPickerState extends State<_LunarMonthPicker> {
  late int _year = widget.year;

  @override
  Widget build(BuildContext context) {
    final leap = leapMonthOf(_year);
    // 12 tháng chính; tháng nhuận (nếu có) chèn ngay sau tháng chính cùng số.
    final months = <(int, bool)>[
      for (var m = 1; m <= 12; m++) ...[(m, false), if (m == leap) (m, true)],
    ];
    return AlertDialog(
      title: const Text(Strings.pickLunarMonth),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _YearStepper(
              label: '$_year · ${canChiYear(_year)}',
              onChanged: (y) => setState(() => _year = y),
              year: _year,
            ),
            if (leap == null)
              Text(
                Strings.noLeapMonthThisYear,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (m, isLeap) in months)
                  ChoiceChip(
                    label: Text(Strings.lunarMonthLabel(m, isLeap)),
                    selected:
                        _year == widget.year && m == widget.month && !isLeap,
                    onSelected: (_) => Navigator.pop(context, (
                      year: _year,
                      month: m,
                      isLeap: isLeap,
                    )),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
      ],
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({
    required this.year,
    required this.label,
    required this.onChanged,
  });

  final int year;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: Strings.prevYear,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(year - 1),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: Strings.nextYear,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(year + 1),
        ),
      ],
    );
  }
}
