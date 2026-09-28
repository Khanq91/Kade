// Port chuyển thể từ Snipz/snap_rail: pill spring chạy giữa các ô bằng nhau.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/theme/kade_theme_extension.dart';

typedef KadeNavigationItem = ({
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// Bottom navigation dùng chuyển động Snap Rail; [liquidGlass] chỉ đổi surface.
class SnapRailNavigationBar extends StatelessWidget {
  const SnapRailNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.liquidGlass,
  });

  final List<KadeNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool liquidGlass;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    final track = _SnapTrack(
      items: items,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      backgroundColor: liquidGlass ? Colors.transparent : colors.sf,
      borderColor: liquidGlass ? Colors.transparent : colors.line,
      labelColor: colors.mu,
      accentColor: colors.acT,
      pillColor: colors.ac,
    );
    final Widget surface = liquidGlass
        ? GlassContainer(
            // Vị trí dùng liquid_glass_widgets duy nhất trong app.
            useOwnLayer: true,
            quality: GlassQuality.standard,
            shape: const LiquidRoundedSuperellipse(borderRadius: 32),
            settings: LiquidGlassSettings(
              glassColor: colors.sf.withValues(alpha: .16),
              backerColor: colors.sf.withValues(alpha: .12),
              blur: 10,
              thickness: 18,
              lightIntensity: .55,
              saturation: 1.15,
            ),
            child: track,
          )
        : track;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(height: 66, child: surface),
    );
  }
}

class _SnapTrack extends StatelessWidget {
  const _SnapTrack({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.backgroundColor,
    required this.borderColor,
    required this.labelColor,
    required this.accentColor,
    required this.pillColor,
  });

  final List<KadeNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;
  final Color accentColor;
  final Color pillColor;

  static const _spring = Cubic(.34, 1.56, .64, 1);

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 4.0;
        final trackWidth = constraints.maxWidth - padding * 2;
        final cellWidth = trackWidth / items.length;
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selectedIndex.toDouble()),
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    curve: _spring,
                    builder: (context, cell, child) {
                      final x = cell * cellWidth;
                      final left = math.max(x, 0.0);
                      final right = math.min(x + cellWidth, trackWidth);
                      return Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: math.max(right - left, 0.0),
                        child: child!,
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: .16),
                        border: Border.all(
                          color: pillColor.withValues(alpha: .5),
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == selectedIndex,
                            label: items[i].label,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelected(i),
                              child: _NavigationContent(
                                item: items[i],
                                selected: i == selectedIndex,
                                selectedColor: accentColor,
                                normalColor: labelColor,
                                disableAnimations: disableAnimations,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavigationContent extends StatelessWidget {
  const _NavigationContent({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.normalColor,
    required this.disableAnimations,
  });

  final KadeNavigationItem item;
  final bool selected;
  final Color selectedColor;
  final Color normalColor;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : normalColor;
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: duration,
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            key: ValueKey(selected),
            size: 21,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: duration,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
