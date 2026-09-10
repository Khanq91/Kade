# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
Phase 1 bước 4 ✅ commit `f2ca73a`. Bước kế: Phase 1 bước 5 (remote config trong `apps/kade`) — cần URL Apps Script đã deploy (setup-google phần A) để verify; có thể viết code trước rồi ⏸ chờ URL.

## Đang dở
(không)

## Cần user làm
- [ ] Chốt Android `applicationId` (T đã chốt (Project chưa giống thì sửa cho thống nhất) `vn.kade.kade`) — cần trước Phase 2 bước 10 (project hiện `com.kade.kade`, đổi khi làm bước 10)
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → đưa URL — cần trước Phase 1 bước 5
- [ ] `docs/setup-google.md` phần B: Google Cloud project + OAuth clients — cần trước Phase 2 bước 10
- [x] Trả lời D006 → giữ Ngày của Mẹ/Cha (D019) — `f2ca73a`
- [ ] Trả lời D009 (license reference, commercial?) — cần trước Phase 3
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → URL vào `dart_defines.json` — cần trước Phase 1 bước 5 (Sheet + script đã xong, còn deploy)
- [x] Trả lời D013 → user chốt sửa (D014), đã patch + sinh lại fixture — `92b7a6d`
- [x] Scaffold Flutter ở root → user xác nhận là project của mình, đã chuyển vào `apps/kade` (D015) — `4994038`
- [x] Đối chiếu bước 2 → user xác nhận (D017), test cố định — `d33e070`
- [ ] VS Code: `dart.flutterSdkPath` đang trỏ Flutter cũ (Dart 3.10.8) → đổi sang `flutter_windows_3.44.5-stable\flutter` hoặc xóa key (ERRORS E008) — không chặn bước nào, chỉ ảnh hưởng terminal VS Code
- [ ] **Duyệt danh sách `vnMemorials`** (22 mục đề xuất, D019) trong `packages/calendar_data/lib/src/events.dart`: thêm/bớt/sửa tên — không chặn bước 5, nhưng nên chốt trước bước 6 (UI hiện danh sách)
- [ ] Xác nhận gộp "Năm mới 1/1" (international, plan §2.2) vào "Tết Dương lịch" (vnHoliday) — D019 mục (3); nếu muốn 2 dòng riêng thì nói

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
| 5 | Remote config: fetch Apps Script + cache Hive + verify CORS web | ⬜ |
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
- Bước 5/6: `assets/overrides.json` hiện ở root repo (test `calendar_data` đọc `../../assets/overrides.json`); Flutter chỉ bundle asset trong thư mục project → đưa vào `apps/kade/assets/` (D020), sửa đường dẫn test hoặc để test đọc từ vị trí mới; kiểm `docs/setup-google.md` có nhắc đường dẫn không.
- Bước 7: `DayEvents` của `calendar_data` không có `userEvents`; app gộp thêm (D020).

## Log
- 2026-09-09 — bootstrap — tạo plan, AGENTS.md, .memory, reference, fixture, hướng dẫn Google — (chưa có commit)
- 2026-09-10 — phase0-step1 — workspace root (`packages/*`) + `lunar_core` port 1:1 + 227 test pass (fixture 201 năm, hai chiều 73.414 ngày, bảng Tết README); phát hiện reference trả ngày 0 ở 2 ngày (E005/D013) — 1bdd78e
- 2026-09-10 — phase0-step1 — chuyển scaffold Flutter của user vào `apps/kade`, bật `apps/*`; `flutter analyze` + `flutter test` pass (D015) — 4994038
- 2026-09-10 — phase0-step1 — patch bug ngày 0 ở reference + port, sinh lại fixture (chỉ đổi 2054, 2062), `reference_patch_test.dart`; 227 test pass (D014) — 92b7a6d
- 2026-09-10 — phase0-step2 (wip) — can chi, tiết khí, giờ/ngày hoàng đạo, `DayInfo`, test cấu trúc (238 pass), example in 10 ngày; ⏸ chờ user đối chiếu (D016) — 716104a
- 2026-09-10 — phase0-step2 — user xác nhận 10 ngày + 24 tiết khí 2025 → `day_info_fixed_test.dart`, 249 test pass (D017) — d33e070
- 2026-09-10 — phase0-step3 — `tools/gen_lunar_table.dart` → `table_1900_2100.dart` (201 năm), runtime tra bảng + fallback tính (D018), test bảng == runtime mọi ngày và mọi tổ hợp ngày âm; 256 test pass; sinh lại cho file y hệt — 156e879
- 2026-09-10 — phase1-step4 — `packages/calendar_data`: Event + NthWeekday (D006 giữ Mẹ/Cha), vnHolidays 6 / vnMemorials 22 (đề xuất) / international 9, YearOverrides parse/toJson, resolveMonth theo §3.2; 25 test pass gồm resolveMonth 2/2027 (D019, D020) — f2ca73a
