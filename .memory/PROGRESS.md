# PROGRESS — Kade

Cập nhật theo `AGENTS.md` §4. Bảng trạng thái được sửa tại chỗ; Log là append-only.

## Bước hiện tại
**Chế độ D031 (từ 2026-09-10):** session 2026-09-10 đã làm HẾT bước 13 → 18 (không dừng chờ verify tay). Toàn bộ plan §6 đã code xong; 135 test app pass (`flutter test --timeout 90s`), analyze sạch, build web + APK debug + AAB release (fallback debug key) OK, HEAD `584a659`.
Trạng thái 13–18: **13 🧪** (sync tự động, 401, xóa Drive — manual-test 2.10–2.12) · **14 🧪** (responsive/dialog/phím/PWA/`?lunar=1` — 3.1–3.4) · **15 ⏸** (workflow GitHub Pages xong; user: Pages + 2 secrets + origin — 3.5) · **16 🧪** (notification — 4.2) · **17 🧪** (widget 2x2/4x2 — 4.1, 4.5) · **18 ⏸** (signing config + hướng dẫn xong; user: keystore + OAuth release/play + Play Console — 4.4).
Việc tiếp theo là của user: (1) làm 2 mục ⏸ theo "Cần user làm"; (2) test tay một lượt theo `docs/manual-test.md` (Phase 1–4 × Web/Android, gồm cả cột Android của Phase 1–2 còn ⬜) và báo theo mục "Ghi lỗi". Session sau: đọc lỗi user báo → sửa → đổi 🧪 → ✅; chưa có bước code mới (Phase 5 sau MVP, plan §6).
Chi tiết từng bước gần nhất:
Phase 3 bước 14 🧪 — responsive 3 breakpoint + DayDetail dialog + `?lunar=1` + phím + PWA + cảnh báo web (D033, E018): 117 test pass, analyze sạch, build web (+wasm) + APK OK (commit `c4b0af4`); test tay: manual-test.md 3.1–3.4. Bước 13 🧪 (2.10–2.12), bước 12 🧪 (2.5–2.9).
Phase 3 bước 15 ⏸ — workflow `.github/workflows/deploy-web.yml` + `setup-google.md` phần C xong (D034); chờ user bật Pages + secrets + origin (mục "Cần user làm").
Phase 4 bước 16 🧪 — notification (D035): `buildReminders` + `LocalNotifications` + `ReminderScheduler`, form "Nhắc trước", Cài đặt "Nhắc lễ trước"; 128 test pass, analyze sạch, build web + APK OK (commit `8274606`); test tay: manual-test.md 4.2.
Phase 4 bước 17 🧪 — widget 2x2 + 4x2 (D036, E019): `computeWidgetData` 35 ngày + `WidgetUpdater` + `KadeWidgetSmall/WideProvider` Kotlin; 135 test pass, analyze sạch, build web + APK OK (commit `771ccff`); test tay: manual-test.md 4.1, 4.5.
Phase 4 bước 18 ⏸ — signing config release đọc `android/key.properties` (fallback debug), `setup-google.md` phần D (keystore, SHA-1 release/Play, appbundle, listing), `docs/privacy.html` (workflow chép lên site); chờ user tạo keystore + OAuth client release + Play Console (mục "Cần user làm").

## Đang dở
(không)

## Cần user làm
- [ ] **Bước 15 — Deploy GitHub Pages (⏸, chỉ user làm được; hướng dẫn `docs/setup-google.md` phần C):** (1) repo Settings → Pages → Source: **GitHub Actions**; (2) Secrets `KADE_CONFIG_URL`, `KADE_WEB_CLIENT_ID` (giá trị lấy từ `dart_defines.json`); (3) OAuth client Web (B.3) thêm origin `https://khanq91.github.io`; (4) push `main` hoặc Actions → deploy-web → Run workflow → mở `https://khanq91.github.io/Kade/` → test manual-test.md 3.5 (+ 3.1 mục 6 Lighthouse). Báo ok → 15 ⏸ → ✅.
- [ ] **Bước 18 — Release Android (⏸, chỉ user làm được; hướng dẫn `docs/setup-google.md` phần D):** (1) tạo keystore `kade-release.jks` NGOÀI repo (`keytool -genkey …`, D.1); (2) `apps/kade/android/key.properties` từ `key.properties.example` (gitignored); (3) SHA-1 release → OAuth client Android "Kade Android release" (B.4 / D.3); (4) `flutter build appbundle --release --dart-define-from-file=../../dart_defines.json` → upload Internal testing trên Play Console; (5) Play App Signing → SHA-1 của app signing key → OAuth client "Kade Android play"; (6) listing + Data safety + privacy policy `https://khanq91.github.io/Kade/privacy.html` (sau khi bước 15 deploy). Test manual-test.md 4.4. Báo ok → 18 ⏸ → ✅.
- [ ] **Test tay toàn bộ (cuối, D031)** → theo `docs/manual-test.md`, chia phase × Web/Android; báo theo format "Ghi lỗi" ở cuối file đó. Các mục verify chi tiết bên dưới (bước 12, 11, 9, 6) đã gom vào file đó, giữ lại để tham khảo.
- [~] **Verify bước 12 — sync Drive** (→ manual-test.md 2.5–2.9; tiêu chí §4.8 mục 4–5: đăng nhập cùng tài khoản ở 2 nơi thấy nhau; xóa ở A → sync B → mất, không resurrect). Cần 2 "máy": A = Chrome port 5001, B = trình duyệt khác (Edge/Cốc Cốc, hoặc Chrome profile khác — cùng port 5001, cùng origin đã đăng ký) hoặc Android. Lệnh như bước 11.
  1. A: đăng nhập → tạo 2 sự kiện (1 âm, 1 dương) → Cài đặt → "Đồng bộ ngay" → SnackBar "Đã đồng bộ với Google Drive", dòng "Đồng bộ lần cuối: …". (Web: nếu phiên chưa có quyền Drive, popup consent hiện ngay trong click này.)
  2. B: đăng nhập cùng tài khoản → "Đồng bộ ngay" → SnackBar "Đã đồng bộ, nhận 2 thay đổi từ Drive" → Sự kiện của tôi có 2 sự kiện, ô lịch tháng/Sắp tới có nhãn.
  3. A: xóa 1 sự kiện → "Đồng bộ ngay". B: "Đồng bộ ngay" → sự kiện đó biến mất. B: sửa tên sự kiện còn lại → "Đồng bộ ngay". A: "Đồng bộ ngay" → thấy tên mới. Bấm "Đồng bộ ngay" lần nữa khi không đổi gì → vẫn "Đã đồng bộ…" (không nhận thay đổi).
  4. Drive web → ⚙ Settings → Manage apps → Kade → hiện "hidden app data" (file `kade_events.json` không thấy trong My Drive — đúng, appDataFolder ẩn).
  Lỗi hay gặp: "Đồng bộ không thành công (Drive 401: …)" → token web hết hạn (1h) → bấm lại "Đồng bộ ngay" (bước 13 sẽ tự xin lại); "File trên Drive không đọc được" → Drive → Manage apps → Kade → Delete hidden app data rồi sync lại; "Drive 403 … Drive API has not been used" → B.1 chưa Enable Drive API.
  Báo "ok" (kèm A/B là gì) hoặc dán dòng lỗi → agent sửa rồi đổi 12 sang ✅.
- [x] **Verify bước 11 — Sign-in web + Android** → user gửi ảnh web 2026-09-10 (Cài đặt hiện tên + email + "Đã cấp quyền Google Drive") "có vẻ ổn r đó" → web đạt. **Android chưa thấy báo** → verify chung khi chạy bước 12/13 trên máy thật (mục Android bên dưới vẫn áp dụng; lỗi `clientConfigurationError`/`canceled` → E002). (Tiêu chí §6: lấy được access token scope `drive.appdata` trên cả 2; app hiện "Đã cấp quyền Google Drive" khi có token). Tài khoản dùng phải nằm trong Test users (B.2).
  **Web** (từ `apps/kade`, Flutter 3.44.5 — E008): `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
  1. Cài đặt → mục "Đồng bộ Google" có nút Google "Tiếp tục với Google" (GIS vẽ, không phải nút app). Bấm → popup chọn tài khoản → mục hiện tên + email, dòng "Chưa cấp quyền Google Drive" + nút "Cấp quyền Drive".
  2. Bấm "Cấp quyền Drive" → popup consent "See, edit, create, and delete its own configuration data in your Google Drive" → Allow → "Đã cấp quyền Google Drive (thư mục riêng của app)". ← tiêu chí bước 11 trên web.
  3. F5 → có thể hiện One Tap/FedCM (cờ đã đăng nhập); đăng nhập lại thì email hiện lại nhưng quyền Drive về "Chưa cấp" — đúng thiết kế (web không giữ token qua reload, D029). Đăng xuất → về nút Google.
  Lỗi hay gặp: popup trắng / console `origin_mismatch` → thiếu origin `http://localhost:5001` ở B.3; "access blocked / app chưa verify" → tài khoản không có trong Test users; nút Google không hiện → xem console (client ID sai) và báo agent.
  **Android** (thiết bị thật hoặc emulator có Google Play): `flutter run -d <device> --dart-define-from-file=../../dart_defines.json`
  1. Cài đặt → nút "Đồng bộ với Google" → bottom sheet chọn tài khoản → (consent Drive nếu hỏi) → tên + email + "Đã cấp quyền Google Drive". ← tiêu chí bước 11 trên Android.
  2. Đóng hẳn app, mở lại → email tự hiện (khôi phục im lặng); dòng Drive có thể "Chưa cấp" cho tới khi bấm "Cấp quyền Drive" → phải qua ngay, không hỏi lại.
  3. Đăng xuất → về nút.
  Lỗi hay gặp: `clientConfigurationError` hoặc `canceled` ngay sau khi chọn tài khoản → SHA-1/package sai (E002; client Android phải là package `vn.kade.kade` + SHA-1 debug đã ghi ở B.4); `serverClientId must be provided` → thiếu `KADE_WEB_CLIENT_ID`.
  Báo "ok" (kèm nền tảng đã thử) hoặc dán dòng lỗi đỏ trong mục Đồng bộ → agent sửa rồi đổi bước 11 sang ✅.
- [x] **Verify bước 9 trên web** → user xác nhận 2026-09-10 "ok tốt". (Export/Import, tiêu chí §6: export → xóa hết → import → giống hệt). Từ `apps/kade` (Flutter 3.44.5 — E008; port 5001 — E011):
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
- [x] Chốt Android `applicationId` `vn.kade.kade` (user chốt) → agent đã đổi `namespace` + `applicationId` trong `apps/kade/android/app/build.gradle.kts` và `MainActivity.kt` sang `vn/kade/kade` (bước 10, 2026-09-10)
- [x] `docs/setup-google.md` phần A: deploy Apps Script → URL đã có trong `dart_defines.json` (gitignored) — agent đã đọc, dùng qua `--dart-define-from-file`
- [x] **Bước 10 — Google Cloud + OAuth clients** → user xác nhận 2026-09-10 "gg cloud setup xong rồi". (`docs/setup-google.md` phần B). `dart_defines.json` đã có `KADE_WEB_CLIENT_ID` (72 ký tự, đúng dạng); checklist đã làm:
  1. B.1: project Kade có **Google Drive API** đã Enable.
  2. B.2: consent screen External, scope `drive.appdata`, **Test users** có Gmail sẽ dùng test (còn Testing → chỉ tài khoản này đăng nhập được).
  3. B.3: web client `Kade Web` → Authorized JavaScript origins có **cả** `http://localhost:5000` và `http://localhost:5001` (E011). Client ID trong `dart_defines.json` đúng client này.
  4. B.4: tạo OAuth client **Android** `Kade Android debug`: package `vn.kade.kade`, SHA-1 debug máy này `54:F9:E3:8D:28:67:96:BA:E0:80:DC:B1:06:1E:6C:51:CA:35:1C:14` (agent đọc từ `%USERPROFILE%\.android\debug.keystore`; nếu build Android trên máy khác thì lấy SHA-1 máy đó). Không cần copy Client ID Android vào code. Release/Play: Phase 4 bước 18.
  Xong → báo "xong bước 10" → agent đổi 10 sang ✅, làm bước 11 (Sign-in web + Android; verify: access token có scope drive.appdata trên cả 2).
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
| 9 | Export/Import JSON | ✅ |

### Phase 2 — Sync
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 10 | Google Cloud + OAuth clients (user) | ✅ |
| 11 | Sign-in web + Android | ✅ |
| 12 | `sync()` + merge + test 4 case | 🧪 |
| 13 | Trigger + debounce + xử lý 401 web | 🧪 |

### Phase 3 — Web release
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 14 | Routing + responsive + PWA + phím tắt | 🧪 |
| 15 | Deploy + thêm origin vào OAuth | ⏸ |

### Phase 4 — Android release
| Bước | Nội dung | Trạng thái |
|---|---|---|
| 16 | Notification | 🧪 |
| 17 | Widget 2x2 + 4x2 | 🧪 |
| 18 | Release keystore + SHA-1 + Play listing | ⏸ |

## Ghi chú cho bước sau
- Bước 6: home hiện là `SettingsScreen` (tạm) → thay bằng MonthView, Settings vào route `/settings`. MonthView `ref.watch(remoteConfigProvider)` lấy `overrides` cho `resolveMonth`; cache tháng invalidate khi state đổi. UI phải phân biệt `kind` (nghỉ/kỷ niệm/quốc tế) bằng màu/badge và `type` (âm/dương) bằng ký hiệu ÂL/DL (D021). go_router tối thiểu ngay ở bước 6 vì §4.8 mục 2 (reload giữ tháng) là tiêu chí verify của bước này; responsive/PWA/phím tắt để bước 14.
- Sau khi clone/pull: chạy `dart run build_runner build` trong `apps/kade` trước khi analyze/test (generated `*.freezed.dart`, `*.g.dart` bị gitignore — D025, E014).
- Test widget dùng `test/test_app.dart`: `await testApp('/2027/02')` (async vì mở box in-memory), `FakeRemoteConfig`, `memoryUserEventsBox()`, `FakeFileIo` (param `fileIo`, mặc định có sẵn), `testTall` (viewport 1600, cũng trong test_app.dart; màn có ListView dài bắt buộc dùng — E009). Không cần Hive file/runAsync trừ khi test chính Hive.
- Lớp hiển thị (D026) hiện chỉ lọc "Sắp tới"; muốn áp cho lịch tháng → hỏi user, ghi DECISIONS. `todayProvider` chưa tự đổi qua nửa đêm (invalidate khi resume: bước 13/16).
- Bước 9 xong (D027, D028): bước 12 dùng lại `SyncEnvelope.encode()/parse()` (file Drive cùng format, D004), `deviceIdProvider`, `UserEventsNotifier.importAll` (ghi đè theo id, `updatedAt = now`) — merge theo `updatedAt` làm ở tầng sync trước khi gọi putAll. `FileIo`/`fileIoProvider` ở `lib/platform/file_io.dart`; file_picker 12 API xem E015 (không dùng `withData`).
- Bước 12 xong (D030): `SyncNotifier.sync({interactive})` ở `lib/data/sync/sync_provider.dart`, `DriveStore`/`DriveApiStore` (googleapis), `merge.dart`, `UserEventsNotifier.replaceAll`. Bước 13 = trigger + debounce + 401: (a) app start nếu cờ `googleSignedIn` và đã có token im lặng (Android; web thường chưa có token → bỏ qua, không popup); (b) sau `create/update/remove` debounce 5s → `sync()`; (c) `WidgetsBindingObserver` resume > 15 phút → `sync()` + `ref.invalidate(todayProvider)`; (d) sau đăng nhập/cấp quyền → `sync()`; (e) `DriveException(401)` → `GoogleSignInAuth` gọi `clearAuthorizationToken(accessToken)` rồi `driveToken(interactive)` chỉ khi từ nút; trigger nền chỉ ghi `lastError` "Phiên Google hết hạn, bấm Đồng bộ ngay". Không sync khi `SyncState.running`. Tùy chọn "Xóa dữ liệu trên Drive" (plan §3.10) làm ở bước 13 nếu còn thời gian, không bắt buộc.
- Bước 14 xong (D033): giữ hash URL (GitHub Pages); `layoutOf()` ở `core/breakpoints.dart`; `openDay()` để mở DayDetail (dialog ≥ 1024); `TodayCardData.toJson` (`lib/data/today_card.dart`) là schema cho widget bước 17; test responsive dùng `setViewport()`, viewport mặc định 800×600 = layout medium (E018).
- Test app: luôn `flutter test --timeout 90s`; widget test dùng Hive phải bọc `tester.runAsync` (E009); tile dưới viewport 600px là offstage → `ensureVisible`.
- Chạy app: từ `apps/kade`, luôn kèm `--dart-define-from-file=../../dart_defines.json` (thiếu → remote config tắt, chỉ asset). Máy user: dùng Flutter 3.44.5 (E008), web port 5001 (E011).
- Bước 13 xong (D032): `SyncTrigger` (`lib/data/sync/sync_trigger.dart`) tạo ở `AppLifecycle` (main.dart); bước 16/17 nối "sau sync / sau sửa / resume" → reschedule notification + widget bằng listener tương tự (`userEventsProvider`, `syncProvider` lastSyncAt, `onResume`). Test vòng đời: `sendLifecycle()` (E017); test giả giờ: `clock:` trong `testApp`/`testOverrides`.

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
- 2026-09-10 — phase1-step9 — commit code + .memory (D027, D028, E015) — 4047362
- 2026-09-10 — phase1-step9 — user verify web "ok tốt" → ✅; Phase 1 xong — (hash ở dòng sau)
- 2026-09-10 — phase2-step10 — đổi applicationId/namespace/MainActivity → vn.kade.kade (APK debug build OK, aapt: package vn.kade.kade); setup-google.md phần B: origin 5001, package name, SHA-1 debug, lệnh chạy từ apps/kade; kotlin.incremental=false cho android_file_picker 1.1.1 (E016); ⏸ chờ user: Android OAuth client + origin 5001 + test users — (hash ở dòng sau)
- 2026-09-10 — phase2-step10 — commit (bước 9 ✅ + bước 10 ⏸) — b8569c6
- 2026-09-10 — phase2-step11 — `GoogleAuth`/`GoogleSignInAuth` (google_sign_in 7.2.0: web clientId qua initialize, Android serverClientId), `AuthNotifier` (signIn/driveToken/signOut, cờ googleSignedIn), nút GIS web qua conditional import, Cài đặt → "Đồng bộ Google" (D029); FakeGoogleAuth mặc định trong test_app; 72 test pass, analyze sạch, build web + APK debug OK; ⏸ chờ user verify sign-in web + Android — (hash ở dòng sau)
- 2026-09-10 — phase2-step11 — commit — c0ef79d
- 2026-09-10 — phase2-step12 — `DriveStore`/`DriveApiStore` (googleapis 17, Bearer client, list/get alt=media/create/update multipart), `merge.dart` (mergeEvents/purgeTombstones/sameEvents), `SyncNotifier.sync` (find → parse → merge+purge → replaceAll → create/update → lastSyncAt), `UserEventRepository/UserEventsNotifier.replaceAll` (xóa cứng tombstone purge), Cài đặt: "Đồng bộ ngay" + "Đồng bộ lần cuối" thay "Cấp quyền Drive" (D030); 92 test pass (merge 4 case, sync 8 kịch bản, MockClient), analyze sạch, build web + APK OK; ⏸ chờ user verify §4.8 mục 4–5 — (hash ở dòng sau)
- 2026-09-10 — phase2-step12 — commit — d4eb444
- 2026-09-10 — handover — user chốt D031 (chạy hết 13–18 không dừng chờ test tay; test tay gom cuối theo phase × Web/Android): docs/manual-test.md (checklist), docs/prompts/handover.md (prompt session sau), AGENTS.md §2/§3/§4/§5 sửa, trạng thái 🧪; bước 12 ⏸ → 🧪 — (hash ở dòng sau)
- 2026-09-10 — handover — commit — b2941a2
- 2026-09-10 — phase2-step13 — `SyncTrigger` (sau đăng nhập/cấp quyền/khôi phục phiên, debounce 5s sau sửa/nhập, resume ≥ 15 phút + invalidate todayProvider qua ngày) qua `AppLifecycle`; `sync()` đặt running trước khi xin token, 401 → `clearToken` + xin lại 1 lần (im lặng; popup chỉ từ nút) + "Phiên Google hết hạn — bấm Đồng bộ ngay"; `deleteRemote()` + nút "Xóa dữ liệu trên Drive" (D032, E017); 104 test pass, analyze sạch, build web + APK OK → 🧪 — 1735642
- 2026-09-10 — phase2-step13 — DECISIONS D032, ERRORS E017, manual-test 2.10–2.12 — 8330df7
- 2026-09-10 — phase3-step14 — `AppShell` rail ≥ 600 / bottom nav < 600; `MonthViewScreen` 3 layout (wide: lịch 65% + `TodayCard` hero + `UpcomingList(compact)`; medium: lịch trên Sắp tới dưới), `?lunar=1` + `shiftLunarMonth`, `/d/:date` `DialogPage` ≥ 1024 khi mở từ app (`openDay`, extra), phím ← → T (MonthView) + Esc (DayDetail), `TodayCardData`/`todayCardProvider`, cảnh báo lưu trữ web một lần (`webNoticeProvider`), manifest/index.html PWA (D033, E018); 117 test pass, analyze sạch, build web + wasm + APK OK → 🧪 — c4b0af4
- 2026-09-10 — phase3-step14 — DECISIONS D033, ERRORS E018, manual-test 3.1–3.4 — dfc519f
- 2026-09-10 — phase3-step15 — `.github/workflows/deploy-web.yml` (Flutter 3.44.5, build_runner, test, `flutter build web --release --base-href /<repo>/` + secrets → Pages), `setup-google.md` phần C (Pages, secrets, origin `https://khanq91.github.io`, lỗi hay gặp), manual-test 3.5 (D034); ⏸ chờ user — 4ebbc57
- 2026-09-10 — phase4-step16 — `buildReminders` pure (cá nhân `remindBeforeDays` qua `userEventsOn`, nghỉ lễ qua `eventsOn`, ngày đầu, 08:00 giờ máy, 90 ngày, FNV id), `Notifications`/`LocalNotifications` (flutter_local_notifications 22.3.0 + timezone 0.11.1, inexactAllowWhileIdle, chạm → `/d/<date>`, mở từ thông báo khi app tắt) / `NoopNotifications` web, `ReminderScheduler` (start + nghe sự kiện/cài đặt + resume, tuần tự), form "Nhắc trước" + xin quyền lúc lưu, Cài đặt "Nhắc nhở → Nhắc lễ trước" (0/1/3/7/14, ẩn web), manifest receiver + `RECEIVE_BOOT_COMPLETED`, desugaring (D035); 128 test pass, analyze sạch, build web + APK OK → 🧪 — 8274606
- 2026-09-10 — phase4-step16 — DECISIONS D035, manual-test 4.2 — be5263c
- 2026-09-10 — phase4-step17 — `computeWidgetData`/`widgetDataProvider` (35 ngày, `TodayCardData.toJson`, lọc lớp), `HomeWidgets`/`AndroidHomeWidgets` (home_widget 0.9.4: saveWidgetData + updateWidget + scheduleWidgetUpdates 00:00:05 ×35) / Noop, `WidgetUpdater` (start/nghe Notifier nguồn/resume, chạm widget + mở từ widget → `router.go`), Kotlin `KadeWidgetProvider` + Small/Wide, layout 2x2/4x2 + widget_bg + colors (night) + strings + xml info, manifest 2 receiver + HomeWidgetScheduledUpdateReceiver (D036, E019); 135 test pass, analyze sạch, build web + APK OK → 🧪 — 771ccff
- 2026-09-10 — phase4-step18 — `build.gradle.kts` signingConfig release từ `android/key.properties` (fallback debug), `android/key.properties.example`, `.gitignore` key/jks, `setup-google.md` phần D, `docs/privacy.html` + bước copy trong workflow deploy-web, manual-test 4.4 (D037); build apk debug + appbundle release (fallback debug) + web OK; ⏸ chờ user — 584a659
