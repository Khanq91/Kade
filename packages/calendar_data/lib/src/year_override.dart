// YearOverride — nghỉ bù / làm bù theo năm, từ Google Sheet qua Apps Script
// (plan §2.3, D008). Cùng format cho remote, cache Hive và asset fallback:
// { "version": 3, "updatedAt": "2026-11-20T…", "years": { "2027": { "off": [...], "work": [...] } } }
import 'dart:convert';

/// Ngày nghỉ thêm / ngày làm bù của một năm dương. Ngày là `DateTime.utc` 0h.
class YearOverride {
  /// Tạo từ hai tập ngày (0h UTC).
  const YearOverride({this.off = const {}, this.work = const {}});

  /// Ngày nghỉ thêm (nghỉ bù, nghỉ Tết kéo dài, ...).
  final Set<DateTime> off;

  /// Ngày làm bù (đi làm dù rơi vào lễ / cuối tuần).
  final Set<DateTime> work;
}

/// Toàn bộ override theo năm + metadata phiên bản.
class YearOverrides {
  /// Tạo trực tiếp; thường dùng [YearOverrides.fromJson].
  const YearOverrides({
    this.version = 0,
    this.updatedAt,
    this.years = const {},
  });

  /// Không có override nào.
  static const empty = YearOverrides();

  /// Phiên bản do nguồn cấp (Apps Script: epoch ms lần sửa Sheet). Lớn hơn = mới hơn.
  final int version;

  /// Thời điểm nguồn cập nhật, nếu có.
  final DateTime? updatedAt;

  /// Override theo năm dương.
  final Map<int, YearOverride> years;

  /// Override của [year], hoặc `null` nếu năm đó không có dòng nào.
  YearOverride? forYear(int year) => years[year];

  /// Parse JSON đã decode. Bỏ qua năm / ngày không hợp lệ và các key lạ (`_note`).
  factory YearOverrides.fromJson(Map<String, dynamic> json) {
    final years = <int, YearOverride>{};
    final rawYears = json['years'];
    if (rawYears is Map) {
      for (final entry in rawYears.entries) {
        final year = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (year == null || value is! Map) continue;
        years[year] = YearOverride(
          off: _dates(value['off']),
          work: _dates(value['work']),
        );
      }
    }
    return YearOverrides(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      years: years,
    );
  }

  /// Parse chuỗi JSON (nội dung asset / cache / response).
  factory YearOverrides.fromJsonString(String source) =>
      YearOverrides.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Ngược của [YearOverrides.fromJson] (dùng để cache).
  Map<String, dynamic> toJson() => {
    'version': version,
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    'years': {
      for (final e in years.entries)
        '${e.key}': {
          'off': e.value.off.map(_iso).toList()..sort(),
          'work': e.value.work.map(_iso).toList()..sort(),
        },
    },
  };
}

final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// "2027-02-05" → DateTime.utc(2027, 2, 5); chuỗi khác → null.
DateTime? parseIsoDate(String s) {
  final m = _isoDate.firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final date = DateTime.utc(y, mo, d);
  return (date.year == y && date.month == mo && date.day == d) ? date : null;
}

Set<DateTime> _dates(Object? raw) {
  if (raw is! List) return const {};
  return {for (final v in raw) ?parseIsoDate(v.toString())};
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
