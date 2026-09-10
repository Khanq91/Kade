import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';

/// Khung bottom nav [Lịch] [Sắp tới] [Đổi ngày] [Cài đặt] (plan §5.1).
/// `StatefulShellRoute` giữ tháng đang xem khi chuyển tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: Strings.navCalendar,
          ),
          NavigationDestination(
            icon: Icon(Icons.upcoming_outlined),
            selectedIcon: Icon(Icons.upcoming),
            label: Strings.navUpcoming,
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: Strings.navConvert,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Strings.navSettings,
          ),
        ],
      ),
    );
  }
}
