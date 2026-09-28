import 'package:flutter/widgets.dart';

/// Ngưỡng layout responsive (plan §4.2): < 600 điện thoại (bottom nav, chỉ
/// lịch), 600–1023 một cột (rail + lịch trên, Sắp tới dưới), ≥ 1024 hai cột
/// (lịch + panel hero "hôm nay" + Sắp tới; DayDetail dạng dialog).
const mediumBreakpoint = 600.0;
const wideBreakpoint = 1024.0;

enum AppLayout { compact, medium, wide }

/// Layout theo bề rộng cửa sổ.
AppLayout layoutOf(double width) => width >= wideBreakpoint
    ? AppLayout.wide
    : width >= mediumBreakpoint
    ? AppLayout.medium
    : AppLayout.compact;

/// Khoảng cuộn cuối để đưa nội dung lên trên floating nav ở layout compact.
double compactNavigationScrollPadding(BuildContext context) =>
    layoutOf(MediaQuery.sizeOf(context).width) == AppLayout.compact
    ? 96 + MediaQuery.viewPaddingOf(context).bottom
    : 0;
