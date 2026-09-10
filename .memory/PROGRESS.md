# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
Phase 1 bước 9 ⏸ — Export/Import JSON: code xong, 63 test pass, `flutter analyze` sạch, `flutter build web` OK; chờ user verify trên web thật (mục đầu "Cần user làm"). User báo ok → đổi 9 sang ✅ → Phase 1 xong. Tiếp: Phase 2 bước 10 là việc user (Google Cloud + OAuth clients, `docs/setup-google.md` phần B); template prompt bước 11+ ở `docs/prompts/phase1.md`.

## Đang dở
(không)

## Cần user làm
- [ ] **Verify bước 9 trên web** (Export/Import, tiêu chí §6: export → xóa hết → import → giống hệt). Từ `apps/kade` (Flutter 3.44.5 — E008; port 5001 — E011):
  `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
  1. Có sẵn vài sự kiện cá nhân (nếu chưa: Cài đặt → Sự kiện của tôi → + tạo 2–3 cái, có 1 âm lịch, 1 cái ghi chú).
  2. Cài đặt → mục "Sao lưu" → "Xuất file JSON" → trình duyệt tải `kade_events_YYYY-MM-DD.json`, SnackBar "Đã xuất N sự kiện" (N = số đang có, không tính đã xóa). Mở file thấy `schema: 1`, `exportedAt`, `deviceId`, `events` (sự kiện đã xóa vẫn nằm trong file với `deletedAt` — đúng thiết kế D025).
  3. Sự kiện của tôi → mở từng cái → Xóa hết → "Chưa có sự kiện nào"; Sắp tới / ô lịch tháng không còn.
  4. Cài đặt → "Nhập file JSON" → chọn file vừa tải → dialog "Nhập N sự kiện từ file? Sự kiện trùng id sẽ bị ghi đè." → Nhập → SnackBar "Đã nhập N sự kiện" → Sự kiện của tôi thấy lại đủ (tên, ghi chú, màu); Sắp tới và ô lịch tháng hiện lại không cần F5. F5 vẫn còn.
  5. Chọn file JSON khác (vd. `dart_defines.example.json`) → SnackBar "File không đúng định dạng Kade (thiếu danh sách sự kiện)"; đóng hộp chọn file → không có gì xảy ra.
  Nếu mục 2 không tải được file (E015: `saveFile` web luôn trả null, agent chưa chạy web thật) → báo agent làm fallback anchor qua `package:web`.
  Báo "ok" hoặc chỗ sai → agent sửa rồi đổi bước 9 sang ✅.
- [x] **Verify bước 6 trên web** (§4.8 mục 1–2) → user xác nhận 2026-09-10 "test hết rồi, chạy tốt, từ 1–5". Từ `apps/kade` (Flutter 3.44.5 — E008; port 5000 bận — E011):
  `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
  1. Mở `http://localhost:5001/#/2027/02` (Flutter web mặc định hash URL, D023) → tiêu đề "Tháng 2/2027"; ô 5/2 có nhãn ÂL đỏ (Giao thừa) + nền nghỉ; ô 6/2 nhãn ÂL đỏ (Tết Nguyên đán) + nền nghỉ; 9/2 nền nghỉ (nghỉ bù từ Sheet/asset) không nhãn; 14/2 nhãn DL xanh (Valentine) không nghỉ; 20/2 nhãn ÂL cam (Rằm tháng Giêng). Nếu Sheet đã có dòng `off`/`work` khác asset → vào Cài đặt bấm "Kiểm tra cập nhật" rồi quay lại Lịch, ô phải đổi theo (cache tháng tự tính lại).
  2. Đang ở tháng khác (vd. bấm ▶ vài lần) → F5 → vẫn đúng tháng đó (URL `/#/YYYY/MM`).
  3. Tap ô 6/2 → chi tiết: "Thứ Bảy, 06/02/2027", "Âm lịch 1/1 · Năm Đinh Mùi", Tháng Nhâm Dần (Giêng), Ngày Bính Thìn, Ngày hoàng đạo Kim Quỹ, 6 giờ hoàng đạo, mục Nghỉ lễ → Tết Nguyên đán (ÂL). ◀ ▶ hoặc vuốt đổi ngày; Quay lại về tháng.
  4. Tab Đổi ngày: chọn ngày dương → âm + can chi; nhập 1/1/2027 → "Thứ Bảy, 06/02/2027"; 1/5/2027 tick nhuận → "Năm 2027 không có tháng 5 nhuận".
  5. Tiêu đề "Tháng 2/2027" → picker tháng dương; "Tháng âm" → picker âm (năm nhuận có chip "X nhuận").
  Báo "ok" hoặc chỗ sai → agent sửa rồi đổi bước 6 sang ✅.
- [ ] Chốt Android `applicationId` (T đã chốt (Project chưa giống thì sửa cho thống nhất) `vn.kade.kade`) — cần trước Phase 2 bước 10 (project hiện `com.kade.kade`, đổi khi làm bước 10)
- [x] `docs/setup-google.md` phần A: deploy Apps Script → URL đã có trong `dart_defines.json` (gitignored) — agent đã đọc, dùng qua `--dart-define-from-file`
- [ ] `docs/setup-google.md` phần B: Google Cloud project + OAuth clients — cần trước Phase 2 bước 10 (`KADE_WEB_CLIENT_ID` đã có trong dart_defines.json, chưa dùng). Origin web: thêm cả `http://localhost:5001` vì port 5000 bị app khác chiếm (E011)
- [x] Trả lời D006 → giữ Ngày của Mẹ/Cha (D019) — `f2ca73a`
- [ ] Trả lời D009 (license reference, commercial?) — cần trước Phase 3
- [x] Trả lời D013 → user chốt sửa (D014), đã patch + sinh lại fixture — `92b7a6d`
- [x] Scaffold Flutter ở root → user xác nhận là project của mình, đã chuyển vào `apps/kade` (D015) — `4994038`
- [x] Đối chiếu bước 2 → user xác nhận (D017), test cố định — `d33e070`
- [ ] VS Code: `dart.flutterSdkPath` đang trỏ Flutter 3.38.9 (Dart 3.10.8) → đổi sang `flutter_windows_3.44.5-stable\flutter` hoặc xóa key (ERRORS E008) — tạm thời gọi thẳng `flutter.bat` của bản 3.44.5
- [x] Duyệt `vnMemorials` → user: "lấy hết" (D021) — `336fb9f`
- [x] Gộp "Năm mới 1/1" vào "Tết Dương lịch" → giữ; user cần phân biệt âm/dương rõ trong UI (D021, việc của bước 6)
- [x] Verify bước 5 trên web → user xác nhận "app ngon" 2026-09-10

## Trạng thái

### Phase 0 — Engine
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 1 | Init workspace + port reference → `lunar_core` (jd, sóc, kinh độ MT, solar↔lunar) + test fixture | ✅ |
| 2 | Can chi, tiết khí, giờ hoàng đạo, ngày hoàng đạo/hắc đạo | ✅ |
| 3 | `tools/gen_lunar_table.dart` sinh bảng + test bảng == runtime | ✅ |

### Phase 1 — Data + Core UI
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 4 | `calendar_data`: 3 danh sách lễ + `YearOverride` + asset fallback | ✅ |
| 5 | Remote config: fetch Apps Script + cache Hive + verify CORS web | ✅ |
| 6 | MonthView + DayDetail + Converter | ✅ |
| 7 | UserEvent CRUD + tombstone + Hive | ✅ |
| 8 | Upcoming | ✅ |
| 9 | Export/Import JSON | ⏸ |

### Phase 2 — Sync
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 10 | Google Cloud + OAuth clients (user) | ⬜ |
| 11 | Sign-in web + Android | ⬜ |
| 12 | `sync()` + merge + test 4 case | ⬜ |
| 13 | Trigger + debounce + xử lý 401 web | ⬜ |

### Phase 3 — Web release
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 14 | Routing + responsive + PWA + phím tắt | ⬜ |
| 15 | Deploy + thêm origin vào OAuth | ⬜ |

### Phase 4 — Android release
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 16 | Notification | ⬜ |
| 17 | Widget 2x2 + 4x2 | ⬜ |
| 18 | Release keystore + SHA-1 + Play listing | ⬜ |

## Ghi chú cho bước sau
- Bước 6: home hiện là `SettingsScreen` (tạm) → thay bằng MonthView, Settings vào route `/settings`. MonthView `ref.watch(remoteConfigProvider)` lấy `overrides` cho `resolveMonth`; cache tháng invalidate khi state đổi. UI phải phân biệt `kind` (nghỉ/kỷ niệm/quốc tế) bằng màu/badge và `type` (âm/dương) bằng ký hiệu ÂL/DL (D021). go_router tối thiểu ngay ở bước 6 vì §4.8 mục 2 (reload giữ tháng) là tiêu chí verify của bước này; responsive/PWA/phím tắt để bước 14.
- Sau khi clone/pull: chạy `dart run build_runner build` trong `apps/kade` trước khi analyze/test (generated `*.freezed.dart`, `*.g.dart` bị gitignore — D025, E014).
- Test widget dùng `test/test_app.dart`: `await testApp('/2027/02')` (async vì mở box in-memory), `FakeRemoteConfig`, `memoryUserEventsBox()`, `FakeFileIo` (param `fileIo`, mặc định có sẵn), `testTall` (viewport 1600, cũng trong test_app.dart; màn có ListView dài bắt buộc dùng — E009). Không cần Hive file/runAsync trừ khi test chính Hive.
- Lớp hiển thị (D026) hiện chỉ lọc "Sắp tới"; muốn áp cho lịch tháng → hỏi user, ghi DECISIONS. `todayProvider` chưa tự đổi qua nửa đêm (invalidate khi resume: bước 13/16).
- Bước 9 xong (D027, D028): bước 12 dùng lại `SyncEnvelope.encode()/parse()` (file Drive cùng format, D004), `deviceIdProvider`, `UserEventsNotifier.importAll` (ghi đè theo id, `updatedAt = now`) — merge theo `updatedAt` làm ở tầng sync trước khi gọi putAll. `FileIo`/`fileIoProvider` ở `lib/platform/file_io.dart`; file_picker 12 API xem E015 (không dùng `withData`).
- Bước 12: merge theo `updatedAt` (tombstone cũng là 1 bản) → `putAll`; purge tombstone > 90 ngày sau khi sync (chưa làm ở bước 7, D025).
- Bước 14: `usePathUrlStrategy()` (hiện hash URL `/#/2027/02`, D023), responsive 2 cột, phím tắt ← → T Esc.
- Test app: luôn `flutter test --timeout 90s`; widget test dùng Hive phải bọc `tester.runAsync` (E009); tile dưới viewport 600px là offstage → `ensureVisible`.
- Chạy app: từ `apps/kade`, luôn kèm `--dart-define-from-file=../../dart_defines.json` (thiếu → remote config tắt, chỉ asset). Máy user: dùng Flutter 3.44.5 (E008), web port 5001 (E011).

## Log
- 2026-09-09 — bootstrap — tạo plan, AGENTS.md, .memory, reference, fixture, hướng dẫn Google — (chưa có commit)
- 2026-09-10 — phase0-step1 — workspace root (`packages/*`) + `lunar_core` port 1:1 + 227 test pass (fixture 201 năm, hai chiều 73.414 ngày, bảng Tết README); phát hiện reference trả ngày 0 ở 2 ngày (E005/D013) — 1bdd78e
- 2026-09-10 — phase0-step1 — chuyển scaffold Flutter của user vào `apps/kade`, bật `apps/*`; `flutter analyze` + `flutter test` pass (D015) — 4994038
- 2026-09-10 — phase0-step1 — patch bug ngày 0 ở reference + port, sinh lại fixture (chỉ đổi 2054, 2062), `reference_patch_test.dart`; 227 test pass (D014) — 92b7a6d
- 2026-09-10 — phase0-step2 (wip) — can chi, tiết khí, giờ/ngày hoàng đạo, `DayInfo`, test cấu trúc (238 pass), example in 10 ngày; ⏸ chờ user đối chiếu (D016) — 716104a
- 2026-09-10 — phase0-step2 — user xác nhận 10 ngày + 24 tiết khí 2025 → `day_info_fixed_test.dart`, 249 test pass (D017) — d33e070
- 2026-09-10 — phase0-step3 — `tools/gen_lunar_table.dart` → `table_1900_2100.dart` (201 năm), runtime tra bảng + fallback tính (D018), test bảng == runtime mọi ngày và mọi tổ hợp ngày âm; 256 test pass; sinh lại cho file y hệt — 156e879
- 2026-09-10 — phase1-step4 — `packages/calendar_data`: Event + NthWeekday (D006 giữ Mẹ/Cha), vnHolidays 6 / vnMemorials 22 (đề xuất) / international 9, YearOverrides parse/toJson, resolveMonth theo §3.2; 25 test pass gồm resolveMonth 2/2027 (D019, D020) — f2ca73a
- 2026-09-10 — phase1-step4 — Giao thừa qua `Event.offsetDays` (D021), giữ đủ 22 kỷ niệm; asset `overrides.json` → `apps/kade/assets`; 27 test pass — 336fb9f
- 2026-09-10 — phase1-step5 — env/strings/Hive boxes/`RemoteConfigRepository`/`AsyncNotifier`/`SettingsScreen` (D022); 10 test app pass (E009), `flutter build web` OK; URL thật 200 JSON + CORS `*` (E010); ⏸ chờ user verify trên web — b916f8d
- 2026-09-10 — phase1-step5 — user chạy web (Flutter 3.44.5, port 5001), bấm "Kiểm tra cập nhật" OK → ✅; thêm `docs/prompts/phase1.md` (prompt bước 6 + template) — (commit kèm .memory)
- 2026-09-10 — phase1-step6 — `month_provider` (DayCell/MonthData, cache family, invalidate theo overrides), `event_style` (màu kind + nhãn ÂL/DL), MonthView + picker tháng dương/âm, DayDetail, Converter, `StatefulShellRoute` bottom nav, `/` `/YYYY/MM` `/d/YYYY-MM-DD` `/convert` `/settings`, locale vi (D023); AGENTS.md rule commit (D024); 29 test app pass (`flutter test --timeout 90s`), `flutter build web` OK; ⏸ chờ user verify §4.8 mục 1–2 — 4485657
- 2026-09-10 — phase1-step6 — user chạy web (port 5001), verify mục 1–5 trong "Cần user làm" OK → ✅ — c19ff02
- 2026-09-10 — phase1-step7 — `UserEvent` freezed/json + `LeapMonthRule`, box `user_events` JSON, `UserEventRepository`, `UserEventsNotifier` (create/update/remove tombstone), `userEventsOn` (leap rule D005), `DayCell.userEvents`, form `/events/new` `/events/:id`, danh sách `/events` (Cài đặt → Sự kiện của tôi), DayDetail "+ Thêm sự kiện", MonthView nhãn màu (D025, E014); 48 test pass (match 2025 nhuận tháng 6, Hive reload, CRUD qua UI), build web OK → ✅ — 54d3132
- 2026-09-10 — phase1-step8 — `EventLayer` + `settingsBoxProvider`/`layersProvider` (box settings), `todayProvider`, `upcomingProvider` (60 ngày qua cache tháng, nhiều ngày 1 dòng, đang diễn ra ở Hôm nay), `UpcomingScreen` 4 chip + gom theo ngày, tab "Sắp tới" vị trí 2 (D026); 55 test pass (Tết 06/02/2027 còn 36 ngày, Tết 2028 từ 01/12/2027, cá nhân âm 1/1 năm nay/năm sau, lớp lưu/đọc lại), build web OK → ✅ — 1f471ca
- 2026-09-10 — phase1-step9 — `SyncEnvelope` freezed/json + `parse` lỗi tiếng Việt, `deviceIdProvider`, `FileIo`/`FilePickerFileIo` (file_picker 12.2.0, E015), `UserEventsNotifier.importAll` (D027, D028), Cài đặt → "Sao lưu" Xuất/Nhập + dialog xác nhận; `testTall`/`FakeFileIo` vào test_app; 2 test cũ Settings sang `testTall` (E009); 63 test pass, analyze sạch, build web OK; ⏸ chờ user verify web — (hash ở dòng sau)
