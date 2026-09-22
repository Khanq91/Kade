repo: Khanq91/Kade
branch: main
path: apps/kade

## Last sync
date: 2026-09-11T01:57:00Z

### Updated in this project
- Tái tạo UI Android hiện tại (Material 3, seed đỏ): Lịch tháng, Chi tiết ngày, Sắp tới, Đổi ngày, Cài đặt, Form sự kiện, Widget 2×2/4×2
- Port thuật toán âm lịch (amlich-aa98.js + lunar_core + calendar_data) sang `lunar.js` để prototype dùng dữ liệu thật
- Thiết kế mới: 6 bộ màu pastel (sáng + tối), lưới ngày dạng thẻ, font tiếng Việt (Baloo 2 + Be Vietnam Pro)

## Screen map
| Screen (project) | Repo files |
| --- | --- |
| Kade — Hiện tại.dc.html · 0a Lịch tháng | apps/kade/lib/features/month_view/month_view_screen.dart, features/shell/app_shell.dart, core/event_style.dart, core/strings.dart, core/formats.dart, main.dart |
| Kade — Hiện tại.dc.html · 0b Chi tiết ngày | apps/kade/lib/features/day_detail/day_detail_screen.dart |
| Kade — Hiện tại.dc.html · 0c Sắp tới | apps/kade/lib/features/upcoming/upcoming_screen.dart, data/upcoming_provider.dart |
| Kade — Hiện tại.dc.html · 0d Đổi ngày | apps/kade/lib/features/converter/converter_screen.dart |
| Kade — Hiện tại.dc.html · 0e Cài đặt | apps/kade/lib/features/settings/settings_screen.dart, data/settings_provider.dart |
| Kade — Hiện tại.dc.html · 0f Form sự kiện | apps/kade/lib/features/user_events/user_event_form_screen.dart, user_events_screen.dart, data/models/user_event.dart |
| Kade — Hiện tại.dc.html · 0g Widget | apps/kade/android/app/src/main/res/layout/widget_2x2.xml, widget_4x2.xml, values/colors.xml, values-night/colors.xml, values/strings.xml, lib/data/widget_data.dart, lib/data/today_card.dart |
| Kade — Thiết kế mới.dc.html · 1a/1b/1c | tất cả file trên + core/router.dart, core/breakpoints.dart, features/month_view/month_picker.dart |
| lunar.js | docs/reference/amlich-aa98.js, packages/lunar_core/lib/src/*.dart, packages/calendar_data/lib/src/events.dart, event.dart, apps/kade/lib/data/month_provider.dart |
