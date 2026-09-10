/// Một ngày âm lịch: ngày (1–30), tháng (1–12), năm âm, có phải tháng nhuận không.
class LunarDate {
  /// Tạo ngày âm lịch; không tự kiểm tra tính hợp lệ (dùng `lunarToSolar` để kiểm).
  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });

  /// Ngày âm, 1–30.
  final int day;

  /// Tháng âm, 1–12 (tháng Giêng = 1, tháng Chạp = 12).
  final int month;

  /// Năm âm lịch (đánh số theo năm dương chứa Tết của năm đó).
  final int year;

  /// `true` nếu là tháng nhuận (tháng lặp lại sau tháng chính cùng số).
  final bool isLeapMonth;

  @override
  bool operator ==(Object other) =>
      other is LunarDate &&
      other.day == day &&
      other.month == month &&
      other.year == year &&
      other.isLeapMonth == isLeapMonth;

  @override
  int get hashCode => Object.hash(day, month, year, isLeapMonth);

  @override
  String toString() =>
      'LunarDate($day/$month${isLeapMonth ? ' nhuận' : ''}/$year)';
}
