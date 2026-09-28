import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/breakpoints.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme_extension.dart';
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
      final fancy = ref.watch(graphicsModeProvider) == GraphicsMode.fancy;
      if (fancy) {
        final colors = Theme.of(context).extension<KadeColors>()!;
        return GlassScaffold(
          backgroundColor: Colors.transparent,
          topEdgeFade: false,
          bottomEdgeFadeExtent: -20,
          body: shell,
          bottomBar: GlassTabBar.bottom(
            tabs: [
              for (final item in _items)
                GlassTab(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.label,
                  glowColor: colors.ac,
                ),
            ],
            selectedIndex: shell.currentIndex,
            onTabSelected: _select,
            horizontalPadding: 12,
            verticalPadding: 8,
            barHeight: 64,
            quality: GlassQuality.standard,
            backgroundQuality: GlassQuality.standard,
            settings: LiquidGlassSettings(
              glassColor: colors.sf.withValues(alpha: .16),
              backerColor: colors.sf.withValues(alpha: .12),
              blur: 10,
              thickness: 18,
              lightIntensity: .55,
              saturation: 1.15,
            ),
            indicatorColor: colors.ac.withValues(alpha: .2),
            selectedIconColor: colors.acT,
            selectedLabelColor: colors.acT,
            unselectedIconColor: colors.mu,
            unselectedLabelColor: colors.mu,
          ),
        );
      }
      return Scaffold(
        body: shell,
        bottomNavigationBar: SnapRailNavigationBar(
          items: _items,
          selectedIndex: shell.currentIndex,
          onSelected: _select,
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
