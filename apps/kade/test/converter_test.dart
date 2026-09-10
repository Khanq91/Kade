import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/features/converter/converter_screen.dart';
import 'package:lunar_core/lunar_core.dart';

void main() {
  Widget app({DateTime? initialDate}) => MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ConverterScreen(initialDate: initialDate),
  );

  Future<void> enterLunar(WidgetTester t, String d, String m, String y) async {
    await t.enterText(find.byKey(const ValueKey('lunar-day')), d);
    await t.enterText(find.byKey(const ValueKey('lunar-month')), m);
    await t.enterText(find.byKey(const ValueKey('lunar-year')), y);
  }

  Future<void> convert(WidgetTester t) async {
    await t.tap(find.text(Strings.convertButton));
    await t.pump();
  }

  testWidgets('dương → âm: 06/02/2027 → 1/1/2027, Đinh Mùi', (tester) async {
    await tester.pumpWidget(app(initialDate: DateTime.utc(2027, 2, 6)));
    expect(find.text('Thứ Bảy, 06/02/2027'), findsOneWidget);
    expect(find.text('${Strings.lunarResult}: 1/1/2027'), findsOneWidget);
    expect(
      find.text(
        '${Strings.yearLabel} Đinh Mùi · ${Strings.canChiMonthLabel} Nhâm Dần · '
        '${Strings.canChiDayLabel} Bính Thìn',
      ),
      findsOneWidget,
    );

    // Date picker mở được (locale vi), OK giữ nguyên ngày.
    await tester.tap(find.text('Thứ Bảy, 06/02/2027'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.pickSolarDate), findsOneWidget);
    final loc = MaterialLocalizations.of(
      tester.element(find.byType(ConverterScreen)),
    );
    await tester.tap(find.text(loc.okButtonLabel));
    await tester.pumpAndSettle();
    expect(find.text('${Strings.lunarResult}: 1/1/2027'), findsOneWidget);
  });

  testWidgets('âm → dương: 1/1/2027 (điền sẵn) → 06/02/2027', (tester) async {
    await tester.pumpWidget(app(initialDate: DateTime.utc(2027, 2, 6)));
    final dayField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('lunar-day')),
        matching: find.byType(TextField),
      ),
    );
    expect(dayField.controller!.text, '1');
    await convert(tester);
    expect(
      find.text('${Strings.solarResult}: Thứ Bảy, 06/02/2027'),
      findsOneWidget,
    );
  });

  testWidgets('1/5 nhuận 2027 → lỗi năm không có tháng nhuận', (tester) async {
    await tester.pumpWidget(app(initialDate: DateTime.utc(2027, 2, 6)));
    await enterLunar(tester, '1', '5', '2027');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await convert(tester);
    expect(find.text(Strings.noLeapMonth(5, 2027)), findsOneWidget);
    expect(find.textContaining(Strings.solarResult), findsNothing);
  });

  testWidgets('tháng nhuận có thật: 1/6 nhuận 2025 → 25/07/2025', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialDate: DateTime.utc(2027, 2, 6)));
    await enterLunar(tester, '1', '6', '2025');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await convert(tester);
    expect(find.textContaining('25/07/2025'), findsOneWidget);
  });

  testWidgets('ngày 30 của tháng thiếu → "không tồn tại"; nhập sai → báo lỗi', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialDate: DateTime.utc(2027, 2, 6)));
    // Tìm một tháng 29 ngày của năm 2027 từ engine (không bịa).
    final short = List.generate(12, (i) => i + 1).firstWhere(
      (m) => lunarToSolar(LunarDate(day: 30, month: m, year: 2027)) == null,
    );
    await enterLunar(tester, '30', '$short', '2027');
    await convert(tester);
    expect(
      find.text(Strings.lunarDateMissing(30, short, 2027, false)),
      findsOneWidget,
    );

    await enterLunar(tester, '31', '1', '2027');
    await convert(tester);
    expect(find.text(Strings.invalidInput), findsOneWidget);

    await enterLunar(tester, '', '1', '2027');
    await convert(tester);
    expect(find.text(Strings.invalidInput), findsOneWidget);
  });
}
