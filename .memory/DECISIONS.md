# DECISIONS — Kade

Append-only. Đọc hết trước khi hỏi user bất cứ câu "nên chọn A hay B" nào.
Format và quy tắc ghi: xem `AGENTS.md` §4.

## 2026-09-09 — D001 — Tên app: Kade
- Bởi: user
- Quyết định: app tên "Kade". Package Flutter `apps/kade`, Android applicationId do user chốt khi tạo project (xem PROGRESS "Cần user làm").
- Lý do: convention đặt tên của user.
- Hệ quả: không.

## 2026-09-09 — D002 — Target MVP: web + Android, iOS lùi phase sau
- Bởi: user
- Quyết định: MVP build web (PWA) và Android. iOS (app + WidgetKit) là Phase 5.
- Lý do: ưu tiên nhanh; iOS widget tốn công hơn.
- Hệ quả: `platform/` vẫn tách interface để sau thêm iOS không phải sửa UI. Không viết code iOS ở MVP.

## 2026-09-09 — D003 — Stack
- Bởi: user (theo đề xuất)
- Quyết định: Riverpod (không codegen), go_router, Hive CE, freezed + json_serializable, home_widget, flutter_local_notifications + timezone, google_sign_in + googleapis.
- Lý do: chạy được cả web lẫn Android không cần native setup thêm; Hive CE có IndexedDB.
- Hệ quả: không dùng Isar/Drift/sqflite.

## 2026-09-09 — D004 — Export/Import JSON trong MVP
- Bởi: user
- Quyết định: có Export/Import file JSON, format = `SyncEnvelope` (plan §2.5), dùng chung với file sync trên Drive.
- Lý do: user web không đăng nhập Google vẫn có cách giữ dữ liệu.
- Hệ quả: 1 serializer cho cả 2 tính năng.

## 2026-09-09 — D005 — Quy tắc tháng nhuận mặc định: firstMonth
- Bởi: user
- Quyết định: sự kiện âm lịch lặp hàng năm rơi vào năm có tháng nhuận trùng tháng → mặc định lấy tháng chính (tháng đầu). User đổi được từng sự kiện (`LeapMonthRule`: firstMonth | secondMonth | both).
- Lý do: tục lệ phổ biến.
- Hệ quả: không.

## 2026-09-09 — D006 — Ngày lễ quốc tế: ~10 ngày
- Bởi: user
- Quyết định: danh sách ở plan §2.2. Ngày của Mẹ/Cha (rule "CN thứ N của tháng") CHƯA chốt — agent hỏi user khi làm Phase 1 bước 4, hoặc bỏ nếu user không trả lời.
- Lý do: tránh nhồi.
- Hệ quả: `Event` có thể cần field `nthWeekday` nếu giữ 2 ngày này.

## 2026-09-09 — D007 — Sync qua Google Drive appDataFolder, trong MVP
- Bởi: user (hỏi Google Sheets trước, chọn appDataFolder theo đề xuất)
- Quyết định: sync sự kiện cá nhân = 1 file `kade_events.json` trong appDataFolder của user, scope `drive.appdata`. Không dùng Sheets, không backend riêng. Merge theo `updatedAt`, last-write-wins, tombstone `deletedAt`.
- Lý do: scope non-sensitive không cần verify; blob JSON = format Export/Import; không dính rate limit Sheets.
- Hệ quả: `UserEvent` có `deletedAt`; xóa = soft delete; purge tombstone > 90 ngày sau khi đã sync.

## 2026-09-09 — D008 — Nghỉ bù theo năm: remote config từ Google Sheet qua Apps Script
- Bởi: user
- Quyết định: user sở hữu 1 Sheet tab `overrides`; Apps Script `doGet` trả JSON; app fetch ≤ 1 lần/24h, cache Hive, fallback `assets/overrides.json`. Setup: `docs/setup-google.md`.
- Lý do: sửa nghỉ bù không cần release.
- Hệ quả: nếu CORS từ Flutter web lỗi (verify Phase 1 bước 5) → đổi nguồn sang GitHub raw JSON, Sheet chỉ là nơi soạn. Ghi DECISIONS mới khi đó.

## 2026-09-09 — D009 — Engine: port `docs/reference/amlich-aa98.js` (Hồ Ngọc Đức), múi giờ cố định +7
- Bởi: user (theo đề xuất)
- Quyết định: `lunar_core` port 1:1 từ reference, giữ tên hàm để dễ đối chiếu. Fixture `tet_1900_2100.json` sinh từ chính reference → test port khớp reference 100%.
- Lý do: thuật toán chuẩn de facto của lịch VN.
- Hệ quả: **License reference là "personal, non-commercial use"** (xem header file). Nếu Kade sẽ thu tiền / có quảng cáo → cần user quyết định: (a) xin phép tác giả, (b) viết lại từ Meeus độc lập, (c) giữ non-commercial. → MỞ, hỏi user trước Phase 3 release. Fixture là output của thuật toán, không phải nguồn độc lập; sanity check ngoài: `docs/reference/README.md`.

## 2026-09-09 — D010 — Memory cho agent: `.memory/` 3 file
- Bởi: user
- Quyết định: mọi agent đọc `.memory/PROGRESS.md`, `DECISIONS.md`, `ERRORS.md` đầu session và ghi theo quy tắc `AGENTS.md` §4.
- Lý do: nhiều agent (Claude Code, Codex) thay phiên làm cùng repo.
- Hệ quả: `CLAUDE.md` chỉ import `AGENTS.md`.
