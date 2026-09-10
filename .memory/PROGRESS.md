# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
Phase 0 — bước 2 (chưa bắt đầu). Bước 1 ✅ commit `1bdd78e`. Trước bước 3 cần user chốt D013 (bug "ngày 0" của reference).

## Đang dở
(không)

## Cần user làm
- [ ] Chốt Android `applicationId` (T đã chốt (Project chưa giống thì sửa cho thống nhất) `vn.khangd.kade`) — cần trước Phase 2 bước 10
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → đưa URL — cần trước Phase 1 bước 5
- [ ] `docs/setup-google.md` phần B: Google Cloud project + OAuth clients — cần trước Phase 2 bước 10
- [ ] Trả lời D006 (Ngày của Mẹ/Cha) — cần trước Phase 1 bước 4
- [ ] Trả lời D009 (license reference, commercial?) — cần trước Phase 3
- [ ] `docs/setup-google.md` phần A: tạo Sheet + deploy Apps Script → URL vào `dart_defines.json` — cần trước Phase 1 bước 5 (Sheet + script đã xong, còn deploy)
- [ ] Trả lời D013: sửa bug "ngày 0" của reference (2054-05-07, 2062-04-09) hay giữ 1:1? Nếu sửa: patch `amlich-aa98.js` + port, `node tools/gen_fixture.js`, sửa README + xóa `reference_quirks_test.dart` — cần trước Phase 0 bước 3
- [ ] Scaffold `flutter create` còn ở root (`lib/main.dart`, `test/widget_test.dart`, `android/`, `web/`, `.metadata`, `README.md`) sau khi root `pubspec.yaml` thành workspace (D011): move vào `apps/kade` (giữ `android/`, đổi applicationId) hay xóa rồi `flutter create` mới? — cần trước Phase 1 bước 6

## Trạng thái

### Phase 0 — Engine
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 1 | Init workspace + port reference → `lunar_core` (jd, sóc, kinh độ MT, solar↔lunar) + test fixture | ✅ |
| 2 | Can chi, tiết khí, giờ hoàng đạo, ngày hoàng đạo/hắc đạo | ⬜ |
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
