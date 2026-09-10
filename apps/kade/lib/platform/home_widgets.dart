// Widget màn hình chính Android (plan §5.2) qua package home_widget 0.9:
// ghi `days_json` → SharedPreferences, bảo 2 provider vẽ lại, hẹn giờ vẽ lại
// sau 0h (AlarmManager của plugin, cần HomeWidgetScheduledUpdateReceiver trong
// manifest). Tap widget → app mở với URI `kade://open/<route>`.
// Web / nền tảng khác: [NoopHomeWidgets].
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/widget_data.dart';

/// Lớp widget. Bản thật [AndroidHomeWidgets]; web [NoopHomeWidgets]; test fake.
abstract class HomeWidgets {
  /// Ghi [daysJson], vẽ lại widget, hẹn vẽ lại tại [refreshAt] (mốc tuyệt đối).
  Future<void> push(String daysJson, List<DateTime> refreshAt);

  /// URI nếu app được mở từ widget (lúc start), else null.
  Future<Uri?> initialLaunch();

  /// URI mỗi lần chạm widget khi app đang chạy.
  Stream<Uri?> get clicks;
}

class NoopHomeWidgets implements HomeWidgets {
  const NoopHomeWidgets();

  @override
  Future<void> push(String daysJson, List<DateTime> refreshAt) async {}

  @override
  Future<Uri?> initialLaunch() async => null;

  @override
  Stream<Uri?> get clicks => const Stream.empty();
}

class AndroidHomeWidgets implements HomeWidgets {
  /// Tên đầy đủ 2 AppWidgetProvider (android/app/src/main/kotlin/vn/kade/kade).
  static const providers = [
    'vn.kade.kade.KadeWidgetSmallProvider',
    'vn.kade.kade.KadeWidgetWideProvider',
  ];

  @override
  Future<void> push(String daysJson, List<DateTime> refreshAt) async {
    await HomeWidget.saveWidgetData<String>(widgetDaysKey, daysJson);
    for (final p in providers) {
      await HomeWidget.updateWidget(qualifiedAndroidName: p);
      await HomeWidget.scheduleWidgetUpdates(
        refreshAt,
        qualifiedAndroidName: p,
      );
    }
  }

  @override
  Future<Uri?> initialLaunch() => HomeWidget.initiallyLaunchedFromHomeWidget();

  @override
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;
}

/// Override trong `main()` (Android: bản thật; còn lại Noop); test fake.
final homeWidgetsProvider = Provider<HomeWidgets>(
  (_) => const NoopHomeWidgets(),
);
