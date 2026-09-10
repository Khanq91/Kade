import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/formats.dart';
import '../../core/strings.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.convertTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(Strings.solarToLunarTitle, style: text.titleMedium),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickSolar,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          '${weekdayName(_solar.weekday)}, ${formatDate(_solar)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${Strings.lunarResult}: ${formatLunar(info.lunar)}',
                        style: text.titleLarge,
                      ),
                      Text(
                        '${Strings.yearLabel} ${info.canChiYear} · '
                        '${Strings.canChiMonthLabel} ${info.canChiMonth} · '
                        '${Strings.canChiDayLabel} ${info.canChiDay}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(Strings.lunarToSolarTitle, style: text.titleMedium),
                      const SizedBox(height: 8),
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
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(Strings.leapCheckbox),
                        value: _leap,
                        onChanged: (v) => setState(() => _leap = v ?? false),
                      ),
                      FilledButton(
                        onPressed: _convertLunar,
                        child: const Text(Strings.convertButton),
                      ),
                      if (_solarResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '${Strings.solarResult}: $_solarResult',
                            style: text.titleLarge,
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
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
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
