import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../core/strings.dart';
import '../../data/settings_provider.dart';
import 'snap_rail_navigation_bar.dart';

/// Khung điều hướng [Lịch] [Sắp tới] [Đổi ngày] [Cài đặt] (plan §5.1):
/// < 600 bottom nav, ≥ 600 NavigationRail bên trái (plan §4.2).
/// `StatefulShellRoute` giữ tháng đang xem khi chuyển tab.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<KadeNavigationItem> _items = [
    (
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: Strings.navCalendar,
    ),
    (
      icon: Icons.upcoming_outlined,
      selectedIcon: Icons.upcoming,
      label: Strings.navUpcoming,
    ),
    (
      icon: Icons.swap_horiz,
      selectedIcon: Icons.swap_horiz,
      label: Strings.navConvert,
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: Strings.navSettings,
    ),
  ];

  void _select(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (layoutOf(MediaQuery.sizeOf(context).width) == AppLayout.compact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: SnapRailNavigationBar(
          items: _items,
          selectedIndex: shell.currentIndex,
          onSelected: _select,
          liquidGlass: ref.watch(graphicsModeProvider) == GraphicsMode.fancy,
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
              for (final item in _items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
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
