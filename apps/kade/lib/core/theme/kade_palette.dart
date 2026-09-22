// Bộ màu pastel Kade — port 1-1 từ
// `plan/new-ui/Kade Android app design/themes.js` (KHÔNG tự sáng tác thêm
// màu). 6 palette × sáng/tối; tên field giữ đúng như file gốc để đối chiếu
// dễ: bg, sf, sf2, tx, mu, ac, acT, ac1, ac2, on, b, bT, b1, off, offT, sun,
// line, sh. Redesign Phase 0 (REDESIGN_PLAN.md §2.1, D039).
import 'package:flutter/material.dart';

/// Một bộ 18 màu của 1 biến thể sáng hoặc tối trong 1 [KadePalette]. Ý
/// nghĩa từng field (theo cách `themes.js` dùng trong CSS gốc):
class KadeColorSet {
  const KadeColorSet({
    required this.bg,
    required this.sf,
    required this.sf2,
    required this.tx,
    required this.mu,
    required this.ac,
    required this.acT,
    required this.ac1,
    required this.ac2,
    required this.on,
    required this.b,
    required this.bT,
    required this.b1,
    required this.off,
    required this.offT,
    required this.sun,
    required this.line,
    required this.sh,
  });

  /// Nền trang (Scaffold).
  final Color bg;

  /// Nền thẻ/card.
  final Color sf;

  /// Nền phụ (chip, ô nổi nhẹ, `surfaceContainerHighest`).
  final Color sf2;

  /// Chữ chính.
  final Color tx;

  /// Chữ mờ (phụ đề, `onSurfaceVariant`).
  final Color mu;

  /// Accent chính (thương hiệu, `primary`).
  final Color ac;

  /// Chữ/số nổi bật trên nền accent nhạt (ac1/ac2) — ví dụ số âm lịch to.
  final Color acT;

  /// Nền accent nhạt (`primaryContainer`).
  final Color ac1;

  /// Nền accent đậm hơn ac1 (dùng cho trạng thái nhấn/chọn).
  final Color ac2;

  /// Chữ trên nền accent đậm ([ac]), thường trắng.
  final Color on;

  /// Accent phụ (màu bổ trợ — ví dụ ngày/giờ hoàng đạo, `secondary`).
  final Color b;

  /// Chữ trên nền accent phụ nhạt ([b1]).
  final Color bT;

  /// Nền accent phụ nhạt (`secondaryContainer`).
  final Color b1;

  /// Nền ô ngày nghỉ lễ.
  final Color off;

  /// Chữ/nhãn ngày nghỉ lễ, Chủ nhật đỏ (`error`-ish).
  final Color offT;

  /// Màu số Chủ nhật.
  final Color sun;

  /// Viền/đường kẻ (`outline`).
  final Color line;

  /// Màu bóng (shadow) của card, đã gồm alpha.
  final Color sh;
}

/// Một bộ màu pastel có thể chọn trong Cài đặt → Giao diện (Phase 6).
class KadePalette {
  const KadePalette({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  /// Khóa lưu trong box settings (key `themeId`), khớp id trong `themes.js`.
  final String id;

  /// Tên hiển thị (màn Giao diện).
  final String name;

  final KadeColorSet light;
  final KadeColorSet dark;
}

/// 6 bộ màu pastel, đúng thứ tự trong `themes.js`. Mặc định của app là
/// `hong` (Hồng phấn — người dùng chốt trong REDESIGN_PLAN.md).
final List<KadePalette> kadePalettes = <KadePalette>[
  const KadePalette(
    id: 'hong',
    name: 'Hồng phấn',
    light: KadeColorSet(
      bg: Color(0xFFFBEEF1),
      sf: Color(0xFFFFFFFF),
      sf2: Color(0xFFFDE4EA),
      tx: Color(0xFF2B1E24),
      mu: Color(0xFF7A6570),
      ac: Color(0xFFD97A93),
      acT: Color(0xFF9B4560),
      ac1: Color(0xFFFCE6EC),
      ac2: Color(0xFFF6C7D4),
      on: Color(0xFFFFFFFF),
      b: Color(0xFF7FA38E),
      bT: Color(0xFF3F6B54),
      b1: Color(0xFFE1EFE7),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFEED3DB),
      sh: Color(0x1A5A283C), // rgba(90,40,60,.10)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF1D171B),
      sf: Color(0xFF2A2127),
      sf2: Color(0xFF372A33),
      tx: Color(0xFFF5E9EE),
      mu: Color(0xFFB39AA6),
      ac: Color(0xFFF0A5B8),
      acT: Color(0xFFF7C6D3),
      ac1: Color(0xFF3E2A34),
      ac2: Color(0xFF573545),
      on: Color(0xFF2B1E24),
      b: Color(0xFF9DC1AE),
      bT: Color(0xFFBFDACB),
      b1: Color(0xFF26332C),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF3F3138),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
  const KadePalette(
    id: 'mint',
    name: 'Xanh mint',
    light: KadeColorSet(
      bg: Color(0xFFEBF6F1),
      sf: Color(0xFFFFFFFF),
      sf2: Color(0xFFDDF1E8),
      tx: Color(0xFF1B2A25),
      mu: Color(0xFF5E7A70),
      ac: Color(0xFF5EB39A),
      acT: Color(0xFF2C7560),
      ac1: Color(0xFFDCF2EA),
      ac2: Color(0xFFBDE6D6),
      on: Color(0xFFFFFFFF),
      b: Color(0xFFE0A56B),
      bT: Color(0xFF8F5A22),
      b1: Color(0xFFFBEBDA),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFCFE5DB),
      sh: Color(0x1A1E503C), // rgba(30,80,60,.10)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF141C19),
      sf: Color(0xFF1E2925),
      sf2: Color(0xFF28362F),
      tx: Color(0xFFE8F3EE),
      mu: Color(0xFF93AEA3),
      ac: Color(0xFF8FD6BE),
      acT: Color(0xFFB4E6D5),
      ac1: Color(0xFF233A32),
      ac2: Color(0xFF2F4E42),
      on: Color(0xFF132A22),
      b: Color(0xFFF0BF8C),
      bT: Color(0xFFF6D4B0),
      b1: Color(0xFF3A2E20),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF2E3D37),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
  const KadePalette(
    id: 'bien',
    name: 'Xanh biển',
    light: KadeColorSet(
      bg: Color(0xFFEDF3FA),
      sf: Color(0xFFFFFFFF),
      sf2: Color(0xFFDFEAF7),
      tx: Color(0xFF1B2533),
      mu: Color(0xFF61728A),
      ac: Color(0xFF6E9BD8),
      acT: Color(0xFF33619F),
      ac1: Color(0xFFE1EBF8),
      ac2: Color(0xFFC4D8F2),
      on: Color(0xFFFFFFFF),
      b: Color(0xFFD9A56A),
      bT: Color(0xFF8A5A1E),
      b1: Color(0xFFFBEBD8),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFD2DFEE),
      sh: Color(0x1A1E3C64), // rgba(30,60,100,.10)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF141920),
      sf: Color(0xFF1D2530),
      sf2: Color(0xFF27313F),
      tx: Color(0xFFE9EFF7),
      mu: Color(0xFF94A5BC),
      ac: Color(0xFF9EC0EE),
      acT: Color(0xFFBFD6F5),
      ac1: Color(0xFF23303F),
      ac2: Color(0xFF2E4158),
      on: Color(0xFF12203A),
      b: Color(0xFFEFC08C),
      bT: Color(0xFFF6D5B1),
      b1: Color(0xFF3A2F20),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF2D3846),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
  const KadePalette(
    id: 'lavender',
    name: 'Tím lavender',
    light: KadeColorSet(
      bg: Color(0xFFF2EFFA),
      sf: Color(0xFFFFFFFF),
      sf2: Color(0xFFE7E1F7),
      tx: Color(0xFF241F33),
      mu: Color(0xFF6F6786),
      ac: Color(0xFF9A88D6),
      acT: Color(0xFF5E4B9E),
      ac1: Color(0xFFEBE6F9),
      ac2: Color(0xFFD7CDF3),
      on: Color(0xFFFFFFFF),
      b: Color(0xFFE5A88F),
      bT: Color(0xFF95552F),
      b1: Color(0xFFFBE8E0),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFDDD6EE),
      sh: Color(0x1A3C2864), // rgba(60,40,100,.10)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF18151F),
      sf: Color(0xFF221E2C),
      sf2: Color(0xFF2D2839),
      tx: Color(0xFFEEEAF7),
      mu: Color(0xFFA79EBD),
      ac: Color(0xFFBBAEEB),
      acT: Color(0xFFD1C8F3),
      ac1: Color(0xFF2C263D),
      ac2: Color(0xFF3C3452),
      on: Color(0xFF1F1838),
      b: Color(0xFFF2BFA9),
      bT: Color(0xFFF7D4C5),
      b1: Color(0xFF3B2C26),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF352F44),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
  const KadePalette(
    id: 'dao',
    name: 'Cam đào',
    light: KadeColorSet(
      bg: Color(0xFFFCF0E8),
      sf: Color(0xFFFFFFFF),
      sf2: Color(0xFFFBE3D6),
      tx: Color(0xFF2E221B),
      mu: Color(0xFF846A5C),
      ac: Color(0xFFE8956E),
      acT: Color(0xFFA5552F),
      ac1: Color(0xFFFCE6DA),
      ac2: Color(0xFFF8CFBA),
      on: Color(0xFFFFFFFF),
      b: Color(0xFF8AA27D),
      bT: Color(0xFF4C6640),
      b1: Color(0xFFE6EEDF),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFF0D7C9),
      sh: Color(0x1A6E3C1E), // rgba(110,60,30,.10)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF1E1714),
      sf: Color(0xFF2A211C),
      sf2: Color(0xFF382B24),
      tx: Color(0xFFF7ECE5),
      mu: Color(0xFFB99E90),
      ac: Color(0xFFF4B597),
      acT: Color(0xFFF8CDB8),
      ac1: Color(0xFF3E2B22),
      ac2: Color(0xFF55392C),
      on: Color(0xFF2E1A10),
      b: Color(0xFFB2C7A4),
      bT: Color(0xFFCDDCC3),
      b1: Color(0xFF2C3527),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF413129),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
  const KadePalette(
    id: 'kem',
    name: 'Kem be ấm',
    light: KadeColorSet(
      bg: Color(0xFFF5EAD8),
      sf: Color(0xFFFFFBF4),
      sf2: Color(0xFFEBDDC5),
      tx: Color(0xFF201E1D),
      mu: Color(0xFF6F665B),
      ac: Color(0xFFCF8B5C),
      acT: Color(0xFF8C491A),
      ac1: Color(0xFFFFF2EB),
      ac2: Color(0xFFFFE1D0),
      on: Color(0xFFFFFFFF),
      b: Color(0xFF7A8A5E),
      bT: Color(0xFF56633F),
      b1: Color(0xFFE1EECC),
      off: Color(0xFFFFE1DC),
      offT: Color(0xFFB23A3A),
      sun: Color(0xFFC4544F),
      line: Color(0xFFDCD3C4),
      sh: Color(0x1F2E2B25), // rgba(46,43,37,.12)
    ),
    dark: KadeColorSet(
      bg: Color(0xFF1C1916),
      sf: Color(0xFF28241F),
      sf2: Color(0xFF352F28),
      tx: Color(0xFFF4ECE0),
      mu: Color(0xFFB4A793),
      ac: Color(0xFFF0B486),
      acT: Color(0xFFF6CBA8),
      ac1: Color(0xFF3A2E23),
      ac2: Color(0xFF4F3D2D),
      on: Color(0xFF2E1E10),
      b: Color(0xFFAEBF92),
      bT: Color(0xFFCCDBB2),
      b1: Color(0xFF2E3322),
      off: Color(0xFF4A2B2B),
      offT: Color(0xFFF3A6A0),
      sun: Color(0xFFF09A96),
      line: Color(0xFF3D362E),
      sh: Color(0x59000000), // rgba(0,0,0,.35)
    ),
  ),
];

/// Tra palette theo [id]; không thấy → palette đầu (`hong`, mặc định).
KadePalette kadePaletteById(String id) =>
    kadePalettes.firstWhere((p) => p.id == id, orElse: () => kadePalettes.first);
