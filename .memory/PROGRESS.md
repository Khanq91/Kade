# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
Phase 1 bước 5 ⏸ — code + test xong (commit `b916f8d`), `flutter build web` với dart_defines OK, URL thật trả JSON + header CORS `*` (kiểm bằng node). Chờ user verify theo plan §6: chạy web → bấm "Kiểm tra cập nhật" → đổi 1 dòng Sheet → bấm lại thấy đổi, console không lỗi CORS. Sau đó bước 6 (MonthView + DayDetail + Converter).

## Đang dở
(không — bước 5 chỉ còn verify của user)

## Cần user làm
- [ ] Chốt Android `applicationId` (T đã chốt (Project chưa giống thì sửa cho thống nhất) `vn.kade.kade`) — cần trước Phase 2 bước 10 (project hiện `com.kade.kade`, đổi khi làm bước 10)
- [x] `docs/setup-google.md` phần A: deploy Apps Script → URL đã có trong `dart_defines.json` (gitignored) — agent đã đọc, dùng qua `--dart-define-from-file`
- [ ] `docs/setup-google.md` phần B: Google Cloud project + OAuth clients — cần trước Phase 2 bước 10 (`KADE_WEB_CLIENT_ID` đã có trong dart_defines.json, chưa dùng)
- [x] Trả lời D006 → giữ Ngày của Mẹ/Cha (D019) — `f2ca73a`
- [ ] Trả lời D009 (license reference, commercial?) — cần trước Phase 3
- [x] Trả lời D013 → user chốt sửa (D014), đã patch + sinh lại fixture — `92b7a6d`
- [x] Scaffold Flutter ở root → user xác nhận là project của mình, đã chuyển vào `apps/kade` (D015) — `4994038`
- [x] Đối chiếu bước 2 → user xác nhận (D017), test cố định — `d33e070`
- [ ] VS Code: `dart.flutterSdkPath` đang trỏ Flutter cũ (Dart 3.10.8) → đổi sang `flutter_windows_3.44.5-stable\flutter` hoặc xóa key (ERRORS E008) — không chặn bước nào, chỉ ảnh hưởng terminal VS Code
- [x] Duyệt `vnMemorials` → user: "lấy hết" (D021) — `336fb9f`
- [x] Gộp "Năm mới 1/1" vào "Tết Dương lịch" → giữ; user cần phân biệt âm/dương rõ trong UI (D021, việc của bước 6)
- [ ] **Verify bước 5 (plan §6)**: trong `apps/kade` chạy `flutter run -d chrome --web-port 5000 --dart-define-from-file=../../dart_defines.json` → màn Cài đặt → bấm "Kiểm tra cập nhật" → kỳ vọng "Đã cập nhật lịch nghỉ mới" và nguồn "Vừa tải từ Google Sheet", version ≈ epoch ms; sửa 1 dòng trong Sheet, chờ ≤ 5 phút (cache Apps Script), bấm lại → ngày mới hiện; F12 console không có lỗi CORS. Báo kết quả để đánh ✅ bước 5.

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
| 5 | Remote config: fetch Apps Script + cache Hive + verify CORS web | ⏸ |
| 6 | MonthView + DayDetail + Converter | ⬜ |
| 7 | UserEvent CRUD + tombstone + Hive | ⬜ |
| 8 | Upcoming | ⬜ |
| 9 | Export/Import JSON | ⬜ |

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
- Bước 6: home hiện là `SettingsScreen` (tạm) → thay bằng MonthView, Settings vào menu. MonthView `ref.watch(remoteConfigProvider)` lấy `overrides` cho `resolveMonth`; UI phải phân biệt `kind` (nghỉ/kỷ niệm/quốc tế) bằng màu/badge và `type` (âm/dương) bằng ký hiệu (D021).
- Bước 7: `DayEvents` của `calendar_data` không có `userEvents`; app gộp thêm (D020).
- Test app: luôn `flutter test --timeout 90s`; widget test dùng Hive phải bọc `tester.runAsync` (E009).
- Chạy app: từ `apps/kade`, luôn kèm `--dart-define-from-file=../../dart_defines.json` (thiếu → remote config tắt, chỉ asset).

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
