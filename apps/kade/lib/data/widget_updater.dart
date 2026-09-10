// Đẩy dữ liệu widget (plan §5.2, bước 17): lúc start, khi `widgetDataProvider`
// đổi (hôm nay, sự kiện — kể cả sau sync —, overrides, lớp hiển thị), khi
// resume. Hẹn native vẽ lại lúc 00:00:05 mỗi ngày trong 35 ngày. Chạm widget
// → mở route trong URI `kade://open/<route>`.
import 'dart:async';
import 'dart:developer';

import 'package:calendar_data/calendar_data.dart' show YearOverrides;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/home_widgets.dart';
import 'models/event_layer.dart';
import 'models/user_event.dart';
import 'remote/remote_config_provider.dart';
import 'settings_provider.dart';
import 'sync/sync_trigger.dart';
import 'upcoming_provider.dart';
import 'user_events_provider.dart';
import 'widget_data.dart';

/// Route trong URI widget (`kade://open/d/2027-02-06` → `/d/2027-02-06`);
/// null nếu không có URI / không có path.
String? widgetRouteOf(Uri? uri) {
  if (uri == null) return null;
  final path = uri.path;
  return path.isEmpty || path == '/' ? null : path;
}

/// 00:00:05 giờ máy của [count] ngày kế tiếp sau [now].
List<DateTime> nextMidnights(DateTime now, int count) => [
  for (var i = 1; i <= count; i++)
    DateTime(now.year, now.month, now.day + i, 0, 0, 5),
];

class WidgetUpdater {
  WidgetUpdater(this._ref) {
    // Nghe các nguồn (Notifier) thay vì `widgetDataProvider`: provider dẫn
    // xuất nhiều tầng trong Riverpod 3 chỉ tính lại khi có người đọc (E019);
    // `push()` đọc `widgetDataProvider` nên luôn lấy bản mới.
    _ref.listen<List<UserEvent>>(userEventsProvider, (_, _) => push());
    _ref.listen<Set<EventLayer>>(layersProvider, (_, _) => push());
    _ref.listen<YearOverrides?>(
      remoteConfigProvider.select((s) => s.value?.overrides),
      (_, _) => push(),
    );
    _ref.onDispose(() => _clicks?.cancel());
  }

  final Ref _ref;
  StreamSubscription<Uri?>? _clicks;
  Future<void> _chain = Future.value();

  /// Số lần đẩy và dữ liệu gần nhất (test).
  int pushes = 0;
  WidgetData? last;

  HomeWidgets get _hw => _ref.read(homeWidgetsProvider);

  /// Lúc app start: nghe chạm widget, mở route nếu app được mở từ widget,
  /// đẩy dữ liệu lần đầu.
  Future<void> start(void Function(String route) open) async {
    _clicks = _hw.clicks.listen((uri) {
      final route = widgetRouteOf(uri);
      if (route != null) open(route);
    });
    try {
      final route = widgetRouteOf(await _hw.initialLaunch());
      if (route != null) open(route);
    } catch (e) {
      log('initialLaunch lỗi: $e', name: 'kade.widget');
    }
    await push();
  }

  /// Ghi dữ liệu hiện tại + hẹn vẽ lại; các lần đẩy chạy tuần tự.
  Future<void> push() {
    _chain = _chain.then((_) => _run());
    return _chain;
  }

  Future<void> _run() async {
    final now = _ref.read(clockProvider)();
    // Tính thẳng từ nguồn (không đọc widgetDataProvider): ngay sau khi
    // Notifier đổi, provider dẫn xuất còn giữ bản cũ (E019).
    final data = computeWidgetData(
      today: _ref.read(todayProvider),
      events: _ref.read(userEventsProvider),
      overrides:
          _ref.read(remoteConfigProvider).value?.overrides ??
          YearOverrides.empty,
      layers: _ref.read(layersProvider),
      generatedAt: now,
    );
    last = data;
    pushes++;
    try {
      await _hw.push(data.encode(), nextMidnights(now, data.days.length));
    } catch (e) {
      log('đẩy widget lỗi: $e', name: 'kade.widget');
    }
  }
}

/// Tạo lúc app start (`AppLifecycle`), giữ sống.
final widgetUpdaterProvider = Provider<WidgetUpdater>(WidgetUpdater.new);
