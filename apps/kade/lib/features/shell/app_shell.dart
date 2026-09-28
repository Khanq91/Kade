import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/breakpoints.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme_extension.dart';
import '../../data/settings_provider.dart';
import 'snap_rail_navigation_bar.dart';

const _compactNavigationContentClearance = 96.0;

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
      final colors = Theme.of(context).extension<KadeColors>()!;
      final compactBody = Padding(
        padding: EdgeInsets.only(
          bottom:
              _compactNavigationContentClearance +
              MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: shell,
      );
      final Widget bottomBar;
      if (fancy) {
        bottomBar = GlassTabBar.bottom(
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
          quality: GlassQuality.premium,
          backgroundQuality: GlassQuality.premium,
          settings: LiquidGlassSettings(
            glassColor: colors.sf.withValues(alpha: .12),
            backerColor: colors.sf.withValues(alpha: .08),
            blur: 4,
            thickness: 28,
            refractiveIndex: 1.25,
            lightIntensity: .75,
            ambientStrength: .12,
            saturation: 1.4,
          ),
          indicatorColor: colors.ac.withValues(alpha: .2),
          selectedIconColor: colors.acT,
          selectedLabelColor: colors.acT,
          unselectedIconColor: colors.mu,
          unselectedLabelColor: colors.mu,
          textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
        );
      } else {
        bottomBar = SnapRailNavigationBar(
          items: _items,
          selectedIndex: shell.currentIndex,
          onSelected: _select,
        );
      }

      return GlassScaffold(
        backgroundColor: fancy ? Colors.transparent : colors.bg,
        topEdgeFade: false,
        bottomEdgeFade: fancy,
        bottomEdgeFadeExtent: fancy ? -20 : 0,
        extendBody: true,
        body: compactBody,
        bottomBar: bottomBar,
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
