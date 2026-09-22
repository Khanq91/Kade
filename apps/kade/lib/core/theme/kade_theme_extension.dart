// ThemeExtension bọc [KadeColorSet] để mọi widget lấy đúng màu pastel qua
// `Theme.of(context).extension<KadeColors>()!` — thay cho đọc trực tiếp
// `ColorScheme` mặc định ở những chỗ cần đúng màu thiết kế (surface, accent,
// off-day...). Redesign Phase 0 (REDESIGN_PLAN.md §2.1, D039).
import 'package:flutter/material.dart';

import 'kade_palette.dart';

/// Toàn bộ màu pastel của theme đang chọn. Field đúng tên/nghĩa với
/// [KadeColorSet] — xem doc comment ở đó cho từng field.
@immutable
class KadeColors extends ThemeExtension<KadeColors> {
  const KadeColors({
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

  /// Dựng từ 1 [KadeColorSet] (light hoặc dark của 1 [KadePalette]).
  factory KadeColors.fromSet(KadeColorSet set) => KadeColors(
    bg: set.bg,
    sf: set.sf,
    sf2: set.sf2,
    tx: set.tx,
    mu: set.mu,
    ac: set.ac,
    acT: set.acT,
    ac1: set.ac1,
    ac2: set.ac2,
    on: set.on,
    b: set.b,
    bT: set.bT,
    b1: set.b1,
    off: set.off,
    offT: set.offT,
    sun: set.sun,
    line: set.line,
    sh: set.sh,
  );

  final Color bg;
  final Color sf;
  final Color sf2;
  final Color tx;
  final Color mu;
  final Color ac;
  final Color acT;
  final Color ac1;
  final Color ac2;
  final Color on;
  final Color b;
  final Color bT;
  final Color b1;
  final Color off;
  final Color offT;
  final Color sun;
  final Color line;
  final Color sh;

  @override
  KadeColors copyWith({
    Color? bg,
    Color? sf,
    Color? sf2,
    Color? tx,
    Color? mu,
    Color? ac,
    Color? acT,
    Color? ac1,
    Color? ac2,
    Color? on,
    Color? b,
    Color? bT,
    Color? b1,
    Color? off,
    Color? offT,
    Color? sun,
    Color? line,
    Color? sh,
  }) => KadeColors(
    bg: bg ?? this.bg,
    sf: sf ?? this.sf,
    sf2: sf2 ?? this.sf2,
    tx: tx ?? this.tx,
    mu: mu ?? this.mu,
    ac: ac ?? this.ac,
    acT: acT ?? this.acT,
    ac1: ac1 ?? this.ac1,
    ac2: ac2 ?? this.ac2,
    on: on ?? this.on,
    b: b ?? this.b,
    bT: bT ?? this.bT,
    b1: b1 ?? this.b1,
    off: off ?? this.off,
    offT: offT ?? this.offT,
    sun: sun ?? this.sun,
    line: line ?? this.line,
    sh: sh ?? this.sh,
  );

  @override
  KadeColors lerp(ThemeExtension<KadeColors>? other, double t) {
    if (other is! KadeColors) return this;
    return KadeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      sf: Color.lerp(sf, other.sf, t)!,
      sf2: Color.lerp(sf2, other.sf2, t)!,
      tx: Color.lerp(tx, other.tx, t)!,
      mu: Color.lerp(mu, other.mu, t)!,
      ac: Color.lerp(ac, other.ac, t)!,
      acT: Color.lerp(acT, other.acT, t)!,
      ac1: Color.lerp(ac1, other.ac1, t)!,
      ac2: Color.lerp(ac2, other.ac2, t)!,
      on: Color.lerp(on, other.on, t)!,
      b: Color.lerp(b, other.b, t)!,
      bT: Color.lerp(bT, other.bT, t)!,
      b1: Color.lerp(b1, other.b1, t)!,
      off: Color.lerp(off, other.off, t)!,
      offT: Color.lerp(offT, other.offT, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      line: Color.lerp(line, other.line, t)!,
      sh: Color.lerp(sh, other.sh, t)!,
    );
  }
}
