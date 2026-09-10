# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
Phase 0 — bước 2 ⏸ chờ user đối chiếu. Code + test cấu trúc đã commit `716104a` (wip). Chờ user xác nhận output `dart run example/day_info_example.dart` (10 ngày + 24 tiết khí 2025) với lịch vạn niên → viết test giá trị cố định → commit "phase0-step2: can chi, tiết khí, hoàng đạo".

## Đang dở
- phase0-step2: đã làm can chi / tiết khí / giờ+ngày hoàng đạo / `DayInfo` (D016), 238 test pass (cấu trúc). Còn: test giá trị cố định sau khi user xác nhận; nếu user báo lệch → sửa bảng/công thức + ghi DECISIONS.

## Cần user làm
- [ ] Chốt Android `applicationId` (T đã chốt (Project chưa giống thì sửa cho thống nhất) `vn.kade.kade`) — cần trước Phase 2 bước 10 (project hiện `com.kade.kade`, đổi khi làm bước 10)
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → đưa URL — cần trước Phase 1 bước 5
- [ ] `docs/setup-google.md` phần B: Google Cloud project + OAuth clients — cần trước Phase 2 bước 10
- [ ] Trả lời D006 (Ngày của Mẹ/Cha) — cần trước Phase 1 bước 4
- [ ] Trả lời D009 (license reference, commercial?) — cần trước Phase 3
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → URL vào `dart_defines.json` — cần trước Phase 1 bước 5 (Sheet + script đã xong, còn deploy)
- [x] Trả lời D013 → user chốt sửa (D014), đã patch + sinh lại fixture — `92b7a6d`
- [x] Scaffold Flutter ở root → user xác nhận là project của mình, đã chuyển vào `apps/kade` (D015) — `4994038`
- [ ] **Đối chiếu bước 2**: chạy `cd packages/lunar_core && dart run example/day_info_example.dart`, so 10 ngày (âm lịch, can chi năm/tháng/ngày/giờ Tý, tiết khí, giờ hoàng đạo, ngày hoàng đạo/hắc đạo) + 24 ngày tiết khí 2025 với lịch vạn niên; báo "đúng" hoặc chỉ ra chỗ lệch — cần để chốt Phase 0 bước 2

## Trạng thái

### Phase 0 — Engine
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 1 | Init workspace + port reference → `lunar_core` (jd, sóc, kinh độ MT, solar↔lunar) + test fixture | ✅ |
| 2 | Can chi, tiết khí, giờ hoàng đạo, ngày hoàng đạo/hắc đạo | ⏸ |
| 3 | `tools/gen_lunar_table.dart` sinh bảng + test bảng == runtime | ⬜ |

### Phase 1 — Data + Core UI
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 4 | `calendar_data`: 3 danh sách lễ + `YearOverride` + asset fallback | ⬜ |
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

## Log
- 2026-09-09 — bootstrap — tạo plan, AGENTS.md, .memory, reference, fixture, hướng dẫn Google — (chưa có commit)
- 2026-09-10 — phase0-step1 — workspace root (`packages/*`) + `lunar_core` port 1:1 + 227 test pass (fixture 201 năm, hai chiều 73.414 ngày, bảng Tết README); phát hiện reference trả ngày 0 ở 2 ngày (E005/D013) — 1bdd78e
- 2026-09-10 — phase0-step1 — chuyển scaffold Flutter của user vào `apps/kade`, bật `apps/*`; `flutter analyze` + `flutter test` pass (D015) — 4994038
- 2026-09-10 — phase0-step1 — patch bug ngày 0 ở reference + port, sinh lại fixture (chỉ đổi 2054, 2062), `reference_patch_test.dart`; 227 test pass (D014) — 92b7a6d
- 2026-09-10 — phase0-step2 (wip) — can chi, tiết khí, giờ/ngày hoàng đạo, `DayInfo`, test cấu trúc (238 pass), example in 10 ngày; ⏸ chờ user đối chiếu (D016) — 716104a
