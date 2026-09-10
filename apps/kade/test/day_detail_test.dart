import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';

import 'test_app.dart';

void main() {
  testWidgets('06/02/2027: Tết Nguyên đán, năm Đinh Mùi, can chi, hoàng đạo', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp('/d/2027-02-06'));
    await tester.pumpAndSettle();

    expect(find.text('06/02/2027'), findsOneWidget); // AppBar
    expect(find.text('Thứ Bảy, 06/02/2027'), findsOneWidget);
    expect(
      find.text('${Strings.lunarLabel} 1/1 · ${Strings.yearLabel} Đinh Mùi'),
      findsOneWidget,
    );
    expect(find.text('Nhâm Dần (Giêng)'), findsOneWidget);
    expect(find.text('Bính Thìn'), findsOneWidget);
    expect(find.text(Strings.hoangDaoDay), findsOneWidget);
    expect(find.text('Kim Quỹ'), findsOneWidget);
    expect(find.textContaining('Dần (3-5)'), findsOneWidget);
    expect(find.text(Strings.offDay), findsOneWidget);

    expect(find.text(Strings.kindHoliday), findsOneWidget);
    expect(find.text('Tết Nguyên đán'), findsOneWidget);
    expect(find.text(Strings.lunarTag), findsOneWidget);
    expect(find.text(Strings.noEvents), findsNothing);
  });

  testWidgets(
    '09/02/2027: không sự kiện nhưng nghỉ bù (asset); 14/02 Valentine DL',
    (tester) async {
      await tester.pumpWidget(await testApp('/d/2027-02-09'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.noEvents), findsOneWidget);
      expect(find.text(Strings.offDay), findsOneWidget);

      await tester.pumpWidget(await testApp('/d/2027-02-14'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.kindInternational), findsOneWidget);
      expect(find.text(Strings.solarTag), findsOneWidget);
      expect(find.text(Strings.offDay), findsNothing);
    },
  );

  testWidgets(
    '▶ → 07/02; vuốt trái → 08/02; Quay lại (mở thẳng URL) → 2/2027',
    (tester) async {
      await tester.pumpWidget(await testApp('/d/2027-02-06'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(Strings.nextDay));
      await tester.pumpAndSettle();
      expect(find.text('07/02/2027'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('08/02/2027'), findsOneWidget);

      await tester.tap(find.byTooltip(Strings.back));
      await tester.pumpAndSettle();
      expect(find.text(Strings.monthTitle(2, 2027)), findsOneWidget);
    },
  );

  testWidgets('/d/xxx sai định dạng → tháng hiện tại', (tester) async {
    await tester.pumpWidget(await testApp('/d/2027-2-6'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(find.text(Strings.monthTitle(now.month, now.year)), findsOneWidget);
  });
}
