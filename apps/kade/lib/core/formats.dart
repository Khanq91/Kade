/// Định dạng ngày giờ đơn giản, không cần package intl.
String _two(int n) => n.toString().padLeft(2, '0');

/// 05/02/2027 (chỉ dùng y/m/d của [d]).
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 05/02/2027 14:30, theo giờ máy.
String formatDateTime(DateTime d) {
  final l = d.toLocal();
  return '${formatDate(l)} ${_two(l.hour)}:${_two(l.minute)}';
}
