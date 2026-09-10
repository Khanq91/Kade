// go_router tối thiểu bước 6 (plan §4.1): `/` → tháng hiện tại, `/YYYY/MM`,
// `/d/YYYY-MM-DD`, `/convert`, `/settings`. `/upcoming`, `/events` thêm ở bước
// 8–9; path URL strategy, responsive, phím tắt ở bước 14.
import 'package:calendar_data/calendar_data.dart' show parseIsoDate;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/converter/converter_screen.dart';
import '../features/day_detail/day_detail_screen.dart';
import '../features/month_view/month_view_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import 'formats.dart';

/// `/2027/02`.
String monthPath(int year, int month) =>
    '/$year/${month.toString().padLeft(2, '0')}';

/// `/d/2027-02-06`.
String dayPath(DateTime d) => '/d/${isoDate(d)}';

String _currentMonthPath() {
  final n = DateTime.now();
  return monthPath(n.year, n.month);
}

(int, int)? _parseMonth(GoRouterState state) {
  final y = int.tryParse(state.pathParameters['year'] ?? '');
  final m = int.tryParse(state.pathParameters['month'] ?? '');
  if (y == null || m == null || y < 1 || y > 9999 || m < 1 || m > 12) {
    return null;
  }
  return (y, m);
}

/// Tạo router; [initialLocation] để test mở thẳng một route.
GoRouter createRouter({String? initialLocation}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => _currentMonthPath()),
      // Khai báo trước shell để `/d/…` không bị `/:year/:month` bắt.
      GoRoute(
        path: '/d/:date',
        parentNavigatorKey: rootKey,
        redirect: (_, state) =>
            parseIsoDate(state.pathParameters['date'] ?? '') == null
            ? _currentMonthPath()
            : null,
        builder: (_, state) =>
            DayDetailScreen(date: parseIsoDate(state.pathParameters['date']!)!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            initialLocation: _currentMonthPath(),
            routes: [
              GoRoute(
                path: '/:year/:month',
                redirect: (_, state) =>
                    _parseMonth(state) == null ? _currentMonthPath() : null,
                builder: (_, state) {
                  final (y, m) = _parseMonth(state)!;
                  return MonthViewScreen(year: y, month: m);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/convert',
                builder: (_, _) => const ConverterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Router của app thật (tạo một lần).
final appRouter = createRouter();
