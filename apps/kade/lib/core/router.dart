// go_router (plan §4.1): `/` → tháng hiện tại, `/YYYY/MM` (`?lunar=1` = đang
// duyệt theo tháng âm, D033), `/d/YYYY-MM-DD` (dialog khi ≥ 1024 và mở từ
// trong app; trang riêng khi < 1024 hoặc mở thẳng URL vì dưới dialog không có
// gì), `/upcoming`, `/convert`, `/settings`, `/events`. Giữ hash URL (D033).
import 'package:calendar_data/calendar_data.dart' show parseIsoDate;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/converter/converter_screen.dart';
import '../features/day_detail/day_detail_screen.dart';
import '../features/month_view/month_view_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/upcoming/upcoming_screen.dart';
import '../features/user_events/user_event_form_screen.dart';
import '../features/user_events/user_events_screen.dart';
import 'breakpoints.dart';
import 'formats.dart';

/// `/2027/02`, hoặc `/2027/02?lunar=1` khi duyệt theo tháng âm.
String monthPath(int year, int month, {bool lunar = false}) =>
    '/$year/${month.toString().padLeft(2, '0')}${lunar ? '?lunar=1' : ''}';

/// `/d/2027-02-06`.
String dayPath(DateTime d) => '/d/${isoDate(d)}';

/// `extra` khi mở DayDetail từ trong app: cho phép hiện dạng dialog (≥ 1024).
/// Mở thẳng URL không có extra → trang riêng.
const dayDetailFromApp = 'from-app';

/// Mở chi tiết ngày [date] từ trong app (push, giữ stack về tháng).
void openDay(BuildContext context, DateTime date) =>
    context.push(dayPath(date), extra: dayDetailFromApp);

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

/// Page bọc [DialogRoute] để go_router hiện một route dạng dialog.
class DialogPage<T> extends Page<T> {
  const DialogPage({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Route<T> createRoute(BuildContext context) =>
      DialogRoute<T>(context: context, settings: this, builder: builder);
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
        pageBuilder: (context, state) {
          final date = parseIsoDate(state.pathParameters['date']!)!;
          final asDialog =
              state.extra == dayDetailFromApp &&
              layoutOf(MediaQuery.sizeOf(context).width) == AppLayout.wide;
          if (!asDialog) {
            return MaterialPage(
              key: state.pageKey,
              child: DayDetailScreen(date: date),
            );
          }
          return DialogPage(
            key: state.pageKey,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 820,
                ),
                child: DayDetailScreen(date: date, asDialog: true),
              ),
            ),
          );
        },
      ),
      // Sự kiện cá nhân (bước 7): danh sách, tạo mới (`?date=YYYY-MM-DD` điền
      // sẵn), sửa theo id. Đều là trang gốc đè lên shell.
      GoRoute(
        path: '/events',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const UserEventsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            builder: (_, state) => UserEventFormScreen(
              initialDate: parseIsoDate(
                state.uri.queryParameters['date'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            builder: (_, state) =>
                UserEventEditScreen(id: state.pathParameters['id']!),
          ),
        ],
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
                  return MonthViewScreen(
                    year: y,
                    month: m,
                    lunar: state.uri.queryParameters['lunar'] == '1',
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upcoming',
                builder: (_, _) => const UpcomingScreen(),
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
