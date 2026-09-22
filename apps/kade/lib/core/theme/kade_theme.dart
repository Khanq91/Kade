// Dựng ThemeData đầy đủ từ 1 KadePalette: ColorScheme (seed theo `ac`),
// TextTheme 2 font (Baloo 2 cho số/tiêu đề to, Be Vietnam Pro cho phần còn
// lại), KadeColors extension, và bo góc mặc định cho Card/Button theo
// phong cách thiết kế mới (số cụ thể lấy từ CSS trong `.dc.html`: card
// 22–24px, nút pill 999px). Redesign Phase 0 (REDESIGN_PLAN.md §2.1, D039).
//
// CHƯA đụng NavigationBar/NavigationRail theme — đó là việc của Phase 2
// (REDESIGN_PLAN.md §4), sẽ thêm vào hàm này ở phase sau.
import 'package:flutter/material.dart';

import 'kade_palette.dart';
import 'kade_theme_extension.dart';

/// Tên 2 font family đã khai trong `pubspec.yaml` (assets/fonts/).
const kadeDisplayFont = 'Baloo 2';
const kadeBodyFont = 'Be Vietnam Pro';

/// Bo góc mặc định của card theo thiết kế mới (`.dc.html`: 22–24px).
const kadeCardRadius = 24.0;

/// Bo góc nút dạng pill theo thiết kế mới (`.dc.html`: 999px).
const kadePillRadius = 999.0;

/// Dựng [ThemeData] đầy đủ cho 1 [KadePalette] ở biến thể sáng ([dark]
/// false) hoặc tối ([dark] true).
ThemeData buildKadeTheme(KadePalette palette, {required bool dark}) {
  final KadeColorSet set = dark ? palette.dark : palette.light;
  final brightness = dark ? Brightness.dark : Brightness.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: set.ac,
  );

  final colorScheme = base.colorScheme.copyWith(
    primary: set.ac,
    onPrimary: set.on,
    primaryContainer: set.ac1,
    onPrimaryContainer: set.acT,
    secondary: set.b,
    onSecondary: set.on,
    secondaryContainer: set.b1,
    onSecondaryContainer: set.bT,
    surface: set.bg,
    onSurface: set.tx,
    surfaceContainerHighest: set.sf2,
    surfaceContainer: set.sf,
    onSurfaceVariant: set.mu,
    outline: set.line,
    outlineVariant: set.line,
    error: set.offT,
    onError: set.on,
    errorContainer: set.off,
    onErrorContainer: set.offT,
    shadow: set.sh,
  );

  final pillShape = const StadiumBorder();
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kadeCardRadius),
    side: BorderSide(color: set.line, width: 1),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: set.bg,
    textTheme: _buildTextTheme(base.textTheme, set),
    extensions: <ThemeExtension<dynamic>>[KadeColors.fromSet(set)],
    appBarTheme: AppBarTheme(
      backgroundColor: set.bg,
      foregroundColor: set.tx,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kadeDisplayFont,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: set.tx,
      ),
    ),
    cardTheme: CardThemeData(
      color: set.sf,
      elevation: 0,
      shadowColor: set.sh,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: set.sf,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kadeCardRadius),
      ),
    ),
    dividerTheme: DividerThemeData(color: set.line, space: 1, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: set.ac,
        foregroundColor: set.on,
        shape: pillShape,
        textStyle: const TextStyle(
          fontFamily: kadeBodyFont,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: set.ac,
        foregroundColor: set.on,
        elevation: 0,
        shape: pillShape,
        textStyle: const TextStyle(
          fontFamily: kadeBodyFont,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: set.acT,
        side: BorderSide(color: set.ac),
        shape: pillShape,
        textStyle: const TextStyle(
          fontFamily: kadeBodyFont,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: set.acT,
        shape: pillShape,
        textStyle: const TextStyle(
          fontFamily: kadeBodyFont,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: set.tx,
      contentTextStyle: TextStyle(fontFamily: kadeBodyFont, color: set.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: set.sf2,
      labelStyle: TextStyle(fontFamily: kadeBodyFont, color: set.tx),
      shape: pillShape,
      side: BorderSide.none,
    ),
  );
}

/// Áp 2 font theo §2.2: Baloo 2 (weight 600–800) cho display/headline (số
/// ngày to, tiêu đề tháng); Be Vietnam Pro (weight 400–600) cho phần còn
/// lại. Giữ nguyên size/letterSpacing mặc định của Material 3, chỉ đổi
/// family/weight/color.
TextTheme _buildTextTheme(TextTheme base, KadeColorSet set) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w800,
      color: set.tx,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w800,
      color: set.tx,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w700,
      color: set.tx,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w700,
      color: set.tx,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w700,
      color: set.tx,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: kadeDisplayFont,
      fontWeight: FontWeight.w600,
      color: set.tx,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: kadeBodyFont,
      fontWeight: FontWeight.w600,
      color: set.tx,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: kadeBodyFont,
      fontWeight: FontWeight.w600,
      color: set.tx,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: kadeBodyFont,
      fontWeight: FontWeight.w500,
      color: set.tx,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: kadeBodyFont,
      color: set.tx,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: kadeBodyFont,
      color: set.tx,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: kadeBodyFont,
      color: set.mu,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontFamily: kadeBodyFont,
      fontWeight: FontWeight.w600,
      color: set.tx,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontFamily: kadeBodyFont,
      color: set.mu,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontFamily: kadeBodyFont,
      color: set.mu,
    ),
  );
}
