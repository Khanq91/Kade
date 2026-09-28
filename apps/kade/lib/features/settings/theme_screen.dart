import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_palette.dart';
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';
import '../../core/widgets/tab_pill_glide.dart';
import '../../data/settings_provider.dart';

/// Chọn một trong sáu bảng màu và chế độ sáng/tối.
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    final text = Theme.of(context).textTheme;
    final selectedId = ref.watch(themeIdProvider);
    final darkOverride = ref.watch(darkModeProvider);
    final graphicsMode = ref.watch(graphicsModeProvider);
    final darkModeIndex = darkOverride == null
        ? 2
        : darkOverride
        ? 1
        : 0;
    final isDark =
        darkOverride ??
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.themeTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              18 + compactNavigationScrollPadding(context),
            ),
            children: [
              Text(
                Strings.themePaletteLabel.toUpperCase(),
                style: text.labelSmall?.copyWith(color: colors.mu),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kadePalettes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (context, i) {
                  final palette = kadePalettes[i];
                  final selected = palette.id == selectedId;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: palette.name,
                    child: Material(
                      color: colors.sf,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: selected ? colors.ac : colors.line,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        key: ValueKey('theme-${palette.id}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            ref.read(themeIdProvider.notifier).set(palette.id),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? palette.dark.bg
                                    : palette.light.bg,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.line),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: isDark
                                          ? palette.dark.ac
                                          : palette.light.ac,
                                    ),
                                    const SizedBox(width: 3),
                                    CircleAvatar(
                                      radius: 4,
                                      backgroundColor: isDark
                                          ? palette.dark.b
                                          : palette.light.b,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              palette.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                Strings.themeModeLabel.toUpperCase(),
                style: text.labelSmall?.copyWith(color: colors.mu),
              ),
              const SizedBox(height: 8),
              TabPillGlide(
                key: const ValueKey('theme-mode-control'),
                tabs: const [
                  TabPillGlideOption(
                    label: Strings.themeLight,
                    icon: Icons.wb_sunny_outlined,
                  ),
                  TabPillGlideOption(
                    label: Strings.themeDark,
                    icon: Icons.nightlight_outlined,
                  ),
                  TabPillGlideOption(
                    label: Strings.themeSystem,
                    icon: Icons.brightness_auto_outlined,
                  ),
                ],
                index: darkModeIndex,
                onChanged: (index) =>
                    ref.read(darkModeProvider.notifier).set(switch (index) {
                      0 => false,
                      1 => true,
                      _ => null,
                    }),
              ),
              const SizedBox(height: 14),
              Text(
                Strings.graphicsLabel.toUpperCase(),
                style: text.labelSmall?.copyWith(color: colors.mu),
              ),
              const SizedBox(height: 8),
              TabPillGlide(
                key: const ValueKey('graphics-mode-control'),
                tabs: const [
                  TabPillGlideOption(
                    label: Strings.graphicsNormal,
                    icon: Icons.eco_outlined,
                  ),
                  TabPillGlideOption(
                    label: Strings.graphicsFancy,
                    icon: Icons.auto_awesome_outlined,
                  ),
                ],
                index: graphicsMode == GraphicsMode.normal ? 0 : 1,
                onChanged: (index) => ref
                    .read(graphicsModeProvider.notifier)
                    .set(index == 0 ? GraphicsMode.normal : GraphicsMode.fancy),
              ),
              const SizedBox(height: 14),
              Text(
                Strings.themePreview.toUpperCase(),
                style: text.labelSmall?.copyWith(color: colors.mu),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final day in [10, 11, 12, 13])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: day == 13 ? 0 : 4),
                        child: _PreviewDay(day: day, colors: colors),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDay extends StatelessWidget {
  const _PreviewDay({required this.day, required this.colors});

  final int day;
  final KadeColors colors;

  @override
  Widget build(BuildContext context) {
    final selected = day == 11;
    final offDay = day == 12;
    return Container(
      height: 60,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: selected
            ? colors.ac
            : offDay
            ? colors.off
            : colors.sf,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors.sh, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontFamily: kadeDisplayFont,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: selected
                  ? colors.on
                  : offDay
                  ? colors.offT
                  : colors.tx,
            ),
          ),
          Text(
            switch (day) {
              10 => '29',
              11 => '1/8',
              _ => '${day - 10}',
            },
            style: TextStyle(
              fontSize: 9,
              color: selected ? colors.on : colors.mu,
            ),
          ),
          if (day == 13)
            Row(
              children: [
                CircleAvatar(radius: 2, backgroundColor: colors.ac),
                const SizedBox(width: 2),
                CircleAvatar(radius: 2, backgroundColor: colors.b),
              ],
            ),
        ],
      ),
    );
  }
}
