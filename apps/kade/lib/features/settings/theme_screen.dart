import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme/kade_palette.dart';
import '../../core/theme/kade_theme.dart';
import '../../core/theme/kade_theme_extension.dart';
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
    final isDark =
        darkOverride ??
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.themeTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(18),
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
              Material(
                color: colors.sf,
                borderRadius: BorderRadius.circular(kadePillRadius),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _ModeButton(
                        label: Strings.themeLight,
                        icon: Icons.wb_sunny_outlined,
                        selected: !isDark,
                        onTap: () =>
                            ref.read(darkModeProvider.notifier).set(false),
                      ),
                      _ModeButton(
                        label: Strings.themeDark,
                        icon: Icons.nightlight_outlined,
                        selected: isDark,
                        onTap: () =>
                            ref.read(darkModeProvider.notifier).set(true),
                      ),
                    ],
                  ),
                ),
              ),
              if (darkOverride != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        ref.read(darkModeProvider.notifier).set(null),
                    child: const Text(Strings.themeSystem),
                  ),
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kadePillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.ac : Colors.transparent,
            borderRadius: BorderRadius.circular(kadePillRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? colors.on : colors.mu),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.on : colors.tx,
                  fontWeight: FontWeight.w600,
                ),
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
