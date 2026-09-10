import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../core/strings.dart';

/// Khung điều hướng [Lịch] [Sắp tới] [Đổi ngày] [Cài đặt] (plan §5.1):
/// < 600 bottom nav, ≥ 600 NavigationRail bên trái (plan §4.2).
/// `StatefulShellRoute` giữ tháng đang xem khi chuyển tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.calendar_month_outlined, Icons.calendar_month, Strings.navCalendar),
    (Icons.upcoming_outlined, Icons.upcoming, Strings.navUpcoming),
    (Icons.swap_horiz, Icons.swap_horiz, Strings.navConvert),
    (Icons.settings_outlined, Icons.settings, Strings.navSettings),
  ];

  void _select(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    if (layoutOf(MediaQuery.sizeOf(context).width) == AppLayout.compact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final (icon, selected, label) in _items)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (icon, selected, label) in _items)
                NavigationRailDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selected),
                  label: Text(label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
