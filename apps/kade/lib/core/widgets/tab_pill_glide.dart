/*
Copyright (c) 2026 Khang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/// Tab Pill Glide, adapted from Snipz's MIT-licensed component by Khang.
/// The pill glides with the original 400 ms cubic curve and label crossfade.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kade_theme.dart';
import '../theme/kade_theme_extension.dart';

/// One labeled option in [TabPillGlide].
class TabPillGlideOption {
  const TabPillGlideOption({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Full-width segmented control with the Tab Pill Glide selection animation.
class TabPillGlide extends StatelessWidget {
  const TabPillGlide({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  }) : assert(tabs.length > 0),
       assert(index >= 0 && index < tabs.length);

  final List<TabPillGlideOption> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  static const double _framePadding = 5;
  static const double _gap = 4;
  static const double _horizontalPadding = 10;
  static const double _verticalPadding = 7;
  static const double _iconSize = 16;
  static const double _iconGap = 4;
  static const Duration _glideDuration = Duration(milliseconds: 400);
  static const Duration _labelDuration = Duration(milliseconds: 300);
  static const Curve _glideCurve = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontFamily: kadeBodyFont,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final direction = Directionality.of(context);
    final motion = !MediaQuery.disableAnimationsOf(context);
    final glideDuration = motion ? _glideDuration : Duration.zero;
    final labelDuration = motion ? _labelDuration : Duration.zero;

    return LayoutBuilder(
      builder: (context, constraints) {
        final naturalWidths = [
          for (final tab in tabs)
            _measureWidth(tab, textStyle, textScaler, direction),
        ];
        final gapsWidth = _gap * (tabs.length - 1);
        final usableWidth = math.max(
          0.0,
          constraints.maxWidth - _framePadding * 2 - gapsWidth,
        );
        final naturalWidth = naturalWidths.fold<double>(0, (a, b) => a + b);
        final scale = naturalWidth > usableWidth && naturalWidth > 0
            ? usableWidth / naturalWidth
            : 1.0;
        final extraWidth = naturalWidth < usableWidth
            ? (usableWidth - naturalWidth) / tabs.length
            : 0.0;
        final widths = [
          for (final width in naturalWidths) width * scale + extraWidth,
        ];
        var pillLeft = _framePadding;
        for (var i = 0; i < index; i++) {
          pillLeft += widths[i] + _gap;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(kadePillRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.sf,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(kadePillRadius),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: glideDuration,
                  curve: _glideCurve,
                  left: pillLeft,
                  top: _framePadding,
                  bottom: _framePadding,
                  width: widths[index],
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.ac,
                      borderRadius: BorderRadius.circular(kadePillRadius),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(_framePadding),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        _tab(
                          context,
                          i,
                          widths[i],
                          textStyle: textStyle,
                          labelDuration: labelDuration,
                          colors: colors,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tab(
    BuildContext context,
    int tabIndex,
    double width, {
    required TextStyle textStyle,
    required Duration labelDuration,
    required KadeColors colors,
  }) {
    final tab = tabs[tabIndex];
    final selected = tabIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kadePillRadius),
            onTap: () => onChanged(tabIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: _verticalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tab.icon != null) ...[
                    Icon(
                      tab.icon,
                      size: _iconSize,
                      color: selected ? colors.on : colors.mu,
                    ),
                    const SizedBox(width: _iconGap),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: labelDuration,
                      curve: Curves.ease,
                      style: textStyle.copyWith(
                        color: selected ? colors.on : colors.tx,
                      ),
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _measureWidth(
    TabPillGlideOption tab,
    TextStyle style,
    TextScaler textScaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: tab.label, style: style),
      textDirection: direction,
      textScaler: textScaler,
    )..layout();
    final width =
        painter.width +
        _horizontalPadding * 2 +
        (tab.icon == null ? 0 : _iconSize + _iconGap);
    painter.dispose();
    return width;
  }
}
