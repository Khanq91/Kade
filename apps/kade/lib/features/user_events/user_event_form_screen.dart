import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar_core/lunar_core.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/lunar_utils.dart';
import '../../core/strings.dart';
import '../../data/models/user_event.dart';
import '../../data/reminder_scheduler.dart';
import '../../data/settings_provider.dart';
import '../../data/user_events_provider.dart';

/// Nhãn lựa chọn nhắc: null → "Không nhắc", 0 → "Đúng ngày", n → "n ngày trước".
String remindLabel(int? days) => switch (days) {
  null => Strings.remindNone,
  0 => Strings.remindSameDay,
  _ => Strings.remindDaysBefore(days),
};

/// Form tạo / sửa sự kiện cá nhân (plan §3.5). [existing] null = tạo mới;
/// [initialDate] điền sẵn ngày khi mở từ DayDetail. Nhắc trước N ngày: bước 16.
class UserEventFormScreen extends ConsumerStatefulWidget {
  const UserEventFormScreen({super.key, this.existing, this.initialDate});

  final UserEvent? existing;
  final DateTime? initialDate;

  @override
  ConsumerState<UserEventFormScreen> createState() =>
      _UserEventFormScreenState();
}

class _UserEventFormScreenState extends ConsumerState<UserEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _duration = TextEditingController(text: '1');
  final _note = TextEditingController();
  CalendarType _type = CalendarType.solar;
  bool _yearly = true;
  LeapMonthRule _leapRule = LeapMonthRule.firstMonth;
  int _color = 0;
  int? _remind;
  String? _dateError;

  /// Lựa chọn "Nhắc trước": null = không nhắc, 0 = đúng ngày, N ngày trước.
  static const remindOptions = [null, 0, 1, 3, 7, 14];

  UserEvent? get _existing => widget.existing;

  /// Ngày gốc để điền sẵn khi tạo mới (đổi âm/dương sẽ điền lại từ ngày này).
  DateTime get _baseDate => dateOnly(widget.initialDate ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _title.text = e.title;
      _type = e.type;
      _day.text = '${e.day}';
      _month.text = '${e.month}';
      _year.text = e.year == null ? '' : '${e.year}';
      _yearly = e.isYearly;
      _leapRule = e.leapRule;
      _duration.text = '${e.durationDays}';
      _note.text = e.note ?? '';
      _color = e.colorIndex;
      _remind = e.remindBeforeDays;
    } else {
      _fillFromDate(_baseDate);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _day, _month, _year, _duration, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFromDate(DateTime d) {
    if (_type == CalendarType.solar) {
      _day.text = '${d.day}';
      _month.text = '${d.month}';
      _year.text = '${d.year}';
    } else {
      final l = solarToLunar(d);
      _day.text = '${l.day}';
      _month.text = '${l.month}';
      _year.text = '${l.year}';
      _leapRule = l.isLeapMonth
          ? LeapMonthRule.secondMonth
          : LeapMonthRule.firstMonth;
    }
  }

  void _setType(CalendarType t) {
    setState(() {
      _type = t;
      if (_existing == null) _fillFromDate(_baseDate);
    });
  }

  /// Kiểm tra ngày; trả lỗi hoặc null.
  String? _validateDate(int? d, int? m, int? y, int? dur) {
    if (d == null || m == null || dur == null) return Strings.invalidEventDate;
    final maxDay = _type == CalendarType.lunar ? 30 : 31;
    if (m < 1 || m > 12 || d < 1 || d > maxDay || dur < 1) {
      return Strings.invalidEventDate;
    }
    if (_yearly) return null;
    if (y == null) return Strings.invalidEventDate;
    final bool exists;
    if (_type == CalendarType.solar) {
      exists = DateTime.utc(y, m, d).day == d;
    } else {
      final leap =
          _leapRule == LeapMonthRule.secondMonth && leapMonthOf(y) == m;
      exists =
          lunarToSolar(
            LunarDate(day: d, month: m, year: y, isLeapMonth: leap),
          ) !=
          null;
    }
    return exists ? null : Strings.eventDateMissing;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final d = int.tryParse(_day.text.trim());
    final m = int.tryParse(_month.text.trim());
    final y = _yearly ? null : int.tryParse(_year.text.trim());
    final dur = int.tryParse(_duration.text.trim());
    final error = _validateDate(d, m, y, dur);
    setState(() => _dateError = error);
    if (error != null) return;

    final notifier = ref.read(userEventsProvider.notifier);
    final title = _title.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final e = _existing;
    if (e == null) {
      await notifier.create(
        title: title,
        type: _type,
        day: d!,
        month: m!,
        year: y,
        durationDays: dur!,
        leapRule: _leapRule,
        remindBeforeDays: _remind,
        note: note,
        colorIndex: _color,
      );
    } else {
      await notifier.update(
        e.copyWith(
          title: title,
          type: _type,
          day: d!,
          month: m!,
          year: y,
          durationDays: dur!,
          leapRule: _leapRule,
          remindBeforeDays: _remind,
          note: note,
          colorIndex: _color,
        ),
      );
    }
    if (!mounted) return;
    // Xin quyền thông báo khi user bật nhắc (plan §5.4), không lúc mở app.
    if (_remind != null) {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await ref.read(reminderSchedulerProvider).requestPermission();
      if (!ok) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(Strings.notificationsDenied)),
          );
      }
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final e = _existing!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.deleteEventTitle),
        content: Text(Strings.deleteEventBody(e.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(Strings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(userEventsProvider.notifier).remove(e.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLunar = _type == CalendarType.lunar;
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? Strings.newEvent : Strings.editEvent),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: Strings.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  key: const ValueKey('ev-title'),
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: Strings.titleField,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? Strings.titleRequired : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<CalendarType>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarType.solar,
                      label: Text(Strings.solarType),
                    ),
                    ButtonSegment(
                      value: CalendarType.lunar,
                      label: Text(Strings.lunarType),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => _setType(s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        key: const ValueKey('ev-day'),
                        controller: _day,
                        label: Strings.dayField,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumberField(
                        key: const ValueKey('ev-month'),
                        controller: _month,
                        label: Strings.monthField,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _NumberField(
                        key: const ValueKey('ev-year'),
                        controller: _year,
                        label: Strings.yearField,
                        enabled: !_yearly,
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(Strings.yearly),
                  value: _yearly,
                  onChanged: (v) => setState(() => _yearly = v ?? true),
                ),
                if (isLunar) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(Strings.leapRuleLabel, style: text.bodyMedium),
                  ),
                  SegmentedButton<LeapMonthRule>(
                    segments: [
                      const ButtonSegment(
                        value: LeapMonthRule.firstMonth,
                        label: Text(Strings.leapFirst),
                      ),
                      const ButtonSegment(
                        value: LeapMonthRule.secondMonth,
                        label: Text(Strings.leapSecond),
                      ),
                      if (_yearly)
                        const ButtonSegment(
                          value: LeapMonthRule.both,
                          label: Text(Strings.leapBoth),
                        ),
                    ],
                    selected: {
                      if (!_yearly && _leapRule == LeapMonthRule.both)
                        LeapMonthRule.firstMonth
                      else
                        _leapRule,
                    },
                    onSelectionChanged: (s) =>
                        setState(() => _leapRule = s.first),
                  ),
                ],
                const SizedBox(height: 12),
                _NumberField(
                  key: const ValueKey('ev-duration'),
                  controller: _duration,
                  label: Strings.durationField,
                ),
                const SizedBox(height: 12),
                // Nhắc trước N ngày lúc 08:00 (bước 16; chỉ Android).
                DropdownButtonFormField<int>(
                  key: const ValueKey('ev-remind'),
                  initialValue: _remind ?? -1,
                  decoration: InputDecoration(
                    labelText: Strings.remindField,
                    helperText: ref.watch(platformIsWebProvider)
                        ? Strings.remindWebHint
                        : null,
                  ),
                  items: [
                    for (final o in remindOptions)
                      DropdownMenuItem(
                        value: o ?? -1,
                        child: Text(remindLabel(o)),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _remind = v == null || v < 0 ? null : v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('ev-note'),
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: Strings.noteField,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 16),
                Text(Strings.colorLabel, style: text.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < userEventColors.length; i++)
                      InkWell(
                        key: ValueKey('ev-color-$i'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _color = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: userEventColors[i],
                            shape: BoxShape.circle,
                          ),
                          child: i == _color
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _dateError!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('ev-save'),
                  onPressed: _save,
                  child: const Text(Strings.save),
                ),
              ],
            ),
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

/// Route `/events/:id`: tìm sự kiện rồi mở form sửa; không có → về danh sách.
class UserEventEditScreen extends ConsumerWidget {
  const UserEventEditScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(userEventByIdProvider(id));
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Strings.editEvent)),
        body: const Center(child: Text(Strings.noUserEvents)),
      );
    }
    // Key theo id để đổi sự kiện thì form khởi tạo lại.
    return UserEventFormScreen(key: ValueKey(e.id), existing: e);
  }
}
