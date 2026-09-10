/// Loại sự kiện app (plan §2.2).
enum EventKind {
  /// Lễ VN được nghỉ chính thức → ngày nghỉ (trừ khi override `work`).
  vnHoliday,

  /// Lễ / ngày kỷ niệm VN, không nghỉ.
  vnMemorial,

  /// Ngày quốc tế phổ biến.
  international,
}

/// Lịch dùng để xác định ngày của sự kiện.
enum CalendarType { solar, lunar }

/// Quy tắc "thứ [weekday] lần thứ [n] trong tháng" (D006: Ngày của Mẹ = Chủ nhật
/// thứ 2 tháng 5, Ngày của Cha = Chủ nhật thứ 3 tháng 6). Chỉ dùng cho lịch dương.
class NthWeekday {
  /// [weekday] theo `DateTime.monday`..`DateTime.sunday`, [n] từ 1 đến 5.
  const NthWeekday({required this.weekday, required this.n});

  /// Thứ trong tuần, `DateTime.monday` (1) … `DateTime.sunday` (7).
  final int weekday;

  /// Lần thứ mấy trong tháng, 1–5.
  final int n;

  /// Ngày (0h UTC) khớp quy tắc trong [year]/[month]; `null` nếu tháng không có lần thứ [n].
  DateTime? resolve(int year, int month) {
    final first = DateTime.utc(year, month, 1);
    final day = 1 + (weekday - first.weekday + 7) % 7 + 7 * (n - 1);
    final d = DateTime.utc(year, month, day);
    return d.month == month ? d : null;
  }
}

/// Sự kiện app (read-only), plan §2.2 + `nthWeekday` (D006).
class Event {
  /// [day] bị bỏ qua khi có [nthWeekday]; [nthWeekday] chỉ hợp lệ với lịch dương.
  const Event({
    required this.id,
    required this.title,
    required this.kind,
    required this.type,
    required this.month,
    this.day = 0,
    this.durationDays = 1,
    this.description,
    this.nthWeekday,
  }) : assert(nthWeekday == null || type == CalendarType.solar),
       assert(nthWeekday != null || day >= 1),
       assert(durationDays >= 1);

  /// Định danh ổn định, kebab-case, ví dụ "tet", "gio-to".
  final String id;

  /// Tên hiển thị (tiếng Việt).
  final String title;

  /// Nhóm sự kiện.
  final EventKind kind;

  /// Âm hay dương.
  final CalendarType type;

  /// Ngày trong tháng (1–31 dương, 1–30 âm); 0 nếu dùng [nthWeekday].
  final int day;

  /// Tháng 1–12 (âm: tháng chính, không áp cho tháng nhuận).
  final int month;

  /// Số ngày kéo dài, mặc định 1 (Tết = 3).
  final int durationDays;

  /// Ghi chú ngắn, tùy chọn.
  final String? description;

  /// Quy tắc "thứ X lần thứ N trong tháng" thay cho [day] (chỉ lịch dương).
  final NthWeekday? nthWeekday;

  /// `true` nếu sự kiện DƯƠNG bắt đầu đúng ngày [date] (chỉ dùng y/m/d).
  /// Sự kiện âm không dùng hàm này (xem `eventsOn`).
  bool startsOnSolar(DateTime date) {
    if (type != CalendarType.solar || date.month != month) return false;
    final rule = nthWeekday;
    if (rule == null) return date.day == day;
    final start = rule.resolve(date.year, date.month);
    return start != null && start.day == date.day;
  }

  @override
  String toString() => 'Event($id)';
}
