import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/formats.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';

/// Đổi ngày (plan §3.7): dương → âm qua date picker; âm → dương qua d/m/y + nhuận.
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, this.initialDate});

  /// Ngày dương ban đầu (mặc định hôm nay); test truyền vào.
  final DateTime? initialDate;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late DateTime _solar = dateOnly(widget.initialDate ?? DateTime.now());
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  bool _leap = false;
  String? _solarResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Điền sẵn ô âm lịch bằng ngày âm của ngày dương ban đầu.
    final l = solarToLunar(_solar);
    _day.text = '${l.day}';
    _month.text = '${l.month}';
    _year.text = '${l.year}';
    _leap = l.isLeapMonth;
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pickSolar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_solar.year, _solar.month, _solar.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: Strings.pickSolarDate,
    );
    if (picked != null) setState(() => _solar = dateOnly(picked));
  }

  void _convertLunar() {
    final d = int.tryParse(_day.text.trim());
    final m = int.tryParse(_month.text.trim());
    final y = int.tryParse(_year.text.trim());
    setState(() {
      _solarResult = null;
      _error = null;
      if (d == null || m == null || y == null) {
        _error = Strings.invalidInput;
        return;
      }
      if (d < 1 || d > 30 || m < 1 || m > 12) {
        _error = Strings.invalidInput;
        return;
      }
      final solar = lunarToSolar(
        LunarDate(day: d, month: m, year: y, isLeapMonth: _leap),
      );
      if (solar != null) {
        _solarResult = '${weekdayName(solar.weekday)}, ${formatDate(solar)}';
        return;
      }
      final hasLeap =
          lunarToSolar(
            LunarDate(day: 1, month: m, year: y, isLeapMonth: true),
          ) !=
          null;
      _error = _leap && !hasLeap
          ? Strings.noLeapMonth(m, y)
          : Strings.lunarDateMissing(d, m, y, _leap);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = dayInfo(_solar);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<KadeColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.convertTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                color: colors.sf,
                elevation: 1,
                shadowColor: colors.sh,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Strings.solarToLunarTitle,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: colors.bg,
                        shape: StadiumBorder(
                          side: BorderSide(color: colors.line, width: 1.5),
                        ),
                        child: InkWell(
                          onTap: _pickSolar,
                          customBorder: const StadiumBorder(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 17,
                                  color: colors.acT,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${weekdayName(_solar.weekday)}, ${formatDate(_solar)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodyMedium,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 17,
                                  color: colors.mu,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${Strings.lunarResult}: ',
                              style: text.bodySmall?.copyWith(color: colors.mu),
                            ),
                            TextSpan(
                              text: formatLunar(info.lunar),
                              style: text.headlineMedium?.copyWith(
                                fontFamily: kadeDisplayFont,
                                fontWeight: FontWeight.w700,
                                color: colors.acT,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${Strings.yearLabel} ${info.canChiYear} · '
                        '${Strings.canChiMonthLabel} ${info.canChiMonth} · '
                        '${Strings.canChiDayLabel} ${info.canChiDay}',
                        style: text.bodySmall?.copyWith(color: colors.mu),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: colors.sf,
                elevation: 1,
                shadowColor: colors.sh,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Strings.lunarToSolarTitle,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              key: const ValueKey('lunar-day'),
                              controller: _day,
                              label: Strings.dayField,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumberField(
                              key: const ValueKey('lunar-month'),
                              controller: _month,
                              label: Strings.monthField,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _NumberField(
                              key: const ValueKey('lunar-year'),
                              controller: _year,
                              label: Strings.yearField,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => setState(() => _leap = !_leap),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _leap,
                              onChanged: (v) =>
                                  setState(() => _leap = v ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              side: BorderSide(color: colors.line, width: 1.5),
                              activeColor: colors.ac,
                              checkColor: colors.on,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text(Strings.leapCheckbox),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _convertLunar,
                          child: const Text(Strings.convertButton),
                        ),
                      ),
                      if (_solarResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${Strings.solarResult}: ',
                                  style: text.bodySmall?.copyWith(
                                    color: colors.mu,
                                  ),
                                ),
                                TextSpan(
                                  text: _solarResult!,
                                  style: text.headlineSmall?.copyWith(
                                    fontFamily: kadeDisplayFont,
                                    fontWeight: FontWeight.w700,
                                    color: colors.acT,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: text.bodyMedium?.copyWith(
                              color: colors.offT,
                            ),
                          ),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    final text = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: text.bodySmall?.copyWith(color: colors.mu),
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kadePillRadius),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kadePillRadius),
          borderSide: BorderSide(color: colors.ac, width: 1.5),
        ),
      ),
    );
  }
}
