# Prompt kickoff — Phase 1 (từ bước 6)

Copy từng khối, giao lần lượt trên session mới. Đợi xong + verify pass mới giao khối tiếp.
Bước 4, 5 đã xong (xem `.memory/PROGRESS.md`).

## Bước 6
```
Đọc AGENTS.md rồi .memory theo thứ tự (PROGRESS, DECISIONS, ERRORS). Làm Phase 1 bước 6 trong docs/plan.md §6:
MonthView + DayDetail + Converter, trong apps/kade. Đọc trước plan §2.6, §3.2, §3.3, §3.4, §3.7, §4.1, §4.8
và DECISIONS D020–D022.

1. resolveMonth cấp app (Riverpod, không codegen): gộp calendar_data.resolveMonth(year, month, overrides lấy từ
   remoteConfigProvider) + lunar_core.dayInfo cho từng ô; cache theo (year, month), invalidate khi remoteConfigProvider
   đổi. userEvents chưa có (bước 7) → để rỗng nhưng chừa chỗ theo plan §2.6 (D020).
2. MonthView (§3.3): lưới tháng, mỗi ô có ngày dương + ngày âm (mùng 1 hiện dạng "1/M"), highlight hôm nay, ngày nghỉ
   (isOffDay) tô màu riêng, badge sự kiện phân biệt RÕ kind (nghỉ / kỷ niệm / quốc tế) bằng màu và type (âm / dương)
   bằng ký hiệu ÂL/DL (D021). Vuốt hoặc ◀ ▶ đổi tháng; nút "Hôm nay"; tap tiêu đề → picker tháng/năm dương;
   "Tháng âm" → picker tháng âm → nhảy tới tháng dương chứa mùng 1.
3. DayDetail (§3.4): header thứ, dd/mm/yyyy, âm dd/mm + can chi năm; khối lịch: can chi tháng/ngày, tiết khí (nếu có),
   hoàng đạo/hắc đạo + tên thần, 6 giờ hoàng đạo; khối sự kiện app nhóm theo kind, ký hiệu âm/dương; vuốt → ngày ±1.
   Chưa có "+ Thêm sự kiện" (bước 7).
4. Converter (§3.7): dương → âm (date picker → âm + can chi năm/tháng/ngày); âm → dương (nhập d/m/y + checkbox nhuận →
   dương; lunarToSolar trả null → báo lỗi tiếng Việt "năm đó không có tháng nhuận đó" / "ngày không tồn tại").
5. go_router tối thiểu (đủ cho §4.8 mục 2 "reload giữ tháng"): `/` → redirect `/YYYY/MM` hiện tại; `/YYYY/MM` MonthView;
   `/d/YYYY-MM-DD` DayDetail; `/convert`; `/settings` (chuyển SettingsScreen bước 5 vào đây, home không còn là Settings).
   Bottom nav [Lịch] [Đổi ngày] [Cài đặt] (Sắp tới thêm ở bước 8). Responsive 2 cột, PWA, phím tắt: để bước 14.
6. Text UI vào lib/core/strings.dart. KHÔNG đụng packages/lunar_core, packages/calendar_data; cần sửa → ghi DECISIONS
   trước rồi chạy lại test của package đó.
7. Test (flutter test --timeout 90s, E009): widget test MonthView 2/2027 với overrides từ assets/overrides.json:
   ô 05/02 có Giao thừa + nghỉ; 06–08/02 có Tết + nghỉ; 14/02 Valentine không nghỉ; 20/02 Rằm tháng Giêng.
   DayDetail 06/02/2027: "Tết Nguyên đán", năm Đinh Mùi. Converter: 1/1/2027 âm → 06/02/2027; 1/5 nhuận 2027 → lỗi.
8. Verify §4.8 mục 1–2 cần chạy web thật → việc của user: từ apps/kade
   `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
   (Flutter 3.44.5, E008; port 5000 bận, E011) → mở /2027/02, ô 6/2 có badge lễ + nghỉ bù từ Sheet; reload giữ tháng.
   Viết hướng dẫn vào PROGRESS "Cần user làm", đánh ⏸ và dừng.
Commit "phase1-step6: MonthView + DayDetail + Converter". Cập nhật .memory. Không làm bước 7–9.
```

## Template cho các bước sau (7, 8, 9)
```
Đọc AGENTS.md rồi .memory theo thứ tự. Làm Phase 1 bước {M} trong docs/plan.md §6, tiêu chí verify ở §6 và §4.8.
Chỉ bước này. Xong → verify → commit "phase1-step{M}: ..." → cập nhật .memory.
Nếu cần tôi làm gì (chạy web thật, thiết bị thật) → ghi vào PROGRESS "Cần user làm", đánh ⏸ và dừng.
Lưu ý máy: dùng Flutter 3.44.5 (E008), test với --timeout 90s (E009), web port 5001 (E011),
luôn --dart-define-from-file=../../dart_defines.json.
```
