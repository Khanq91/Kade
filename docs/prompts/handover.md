# Prompt chuyển giao — session tiếp theo (từ 2026-09-10, sau Phase 2 bước 12)

Bối cảnh: đã xong bước 1–12 (Phase 0, 1 và 2 tới `sync()`). User chốt D031: session
sau làm HẾT phần còn lại (13–18) không dừng chờ verify tay; test tay gom cuối theo
`docs/manual-test.md`. Dán nguyên khối dưới vào session mới:

```
Đọc AGENTS.md rồi .memory theo thứ tự (PROGRESS, DECISIONS, ERRORS), rồi docs/manual-test.md. Sau khi clone/pull:
`dart run build_runner build` trong apps/kade (E014). Nói "Đang ở bước X, sẽ làm Y" rồi bắt đầu.

CHẾ ĐỘ LÀM VIỆC (D031, user chốt 2026-09-10): làm HẾT phần còn lại của docs/plan.md §6 — Phase 2 bước 13,
Phase 3 bước 14–15, Phase 4 bước 16–18 — tuần tự, KHÔNG dừng chờ user verify tay từng bước. Mỗi bước:
đọc phần plan liên quan → code → verify tự động (`flutter analyze` sạch; `flutter test --timeout 90s` xanh;
`flutter build web`; `flutter build apk --debug --dart-define-from-file=../../dart_defines.json`) → commit
`phase{N}-step{M}: <mô tả>` (KHÔNG Co-Authored-By, D024) → cập nhật .memory (DECISIONS tiếp D032…, ERRORS
tiếp E017…, PROGRESS: bảng + log + hash) → THÊM mục test tay của bước đó vào docs/manual-test.md (đúng phase,
cột Web/Android, kèm lỗi hay gặp) thay vì ghi PROGRESS "Cần user làm" → sang bước kế. Trạng thái bảng PROGRESS
cho bước agent xong nhưng chưa test tay: 🧪.
Chỉ dừng (⏸) khi thiếu thứ chỉ user cung cấp được mà không có thì không code tiếp được: bước 15 (tài khoản
hosting/domain, thêm origin OAuth), bước 18 (keystore release, Play Console). Với 2 bước này: làm hết phần
code/config/hướng dẫn, ghi "Cần user làm", rồi VẪN làm tiếp các bước không phụ thuộc (16, 17). Lựa chọn kỹ
thuật thuần (hash vs path URL, GitHub Pages vs Cloudflare Pages, …) → tự chọn cách đơn giản, ghi DECISIONS,
không hỏi. Chỉ hỏi user khi code mâu thuẫn plan về nghiệp vụ (AGENTS §1). Kết thúc khi 13–18 đều 🧪 hoặc ⏸
kèm hướng dẫn.

Môi trường/quirk: Flutter 3.44.5 (E008); test luôn `--timeout 90s`, màn dài dùng `testTall` (E009); web port
5001 (E011); Bash tool không ghi được file Dart/tiếng Việt qua heredoc dài → dùng Write/Edit (E012);
build_runner không `-d` (E014); file_picker 12 API mới (E015); giữ `kotlin.incremental=false` trong
android/gradle.properties (E016); Fake* (FakeRemoteConfig, FakeFileIo, FakeGoogleAuth, FakeDriveStore) trong
test/test_app.dart đã override mặc định cho `testApp`/`testOverrides`; `ProviderContainer.test` cho test
provider. Không đụng packages/lunar_core, packages/calendar_data. Text UI vào lib/core/strings.dart. Không
`print`. Không hardcode URL/ID (Env qua dart_defines).

Hướng dẫn từng bước:
- Bước 13 — Trigger + debounce + 401 web (plan §3.10 "Trigger", §3.1, §4.4, §5.6; D029, D030; PROGRESS "Ghi chú
  cho bước sau" mục Bước 12 xong). Gọi `ref.read(syncProvider.notifier).sync()` (im lặng) khi: (a) app start nếu
  cờ `googleSignedIn` và `driveToken()` im lặng có (web thường không có → bỏ qua, KHÔNG popup); (b) sau
  create/update/remove sự kiện, debounce 5s (gộp nhiều lần sửa); (c) resume sau > 15 phút (WidgetsBindingObserver)
  và `ref.invalidate(todayProvider)` khi đã qua ngày (plan §5.6); (d) ngay sau đăng nhập / cấp quyền / sync tay.
  401: `DriveException.status == 401` → thêm `GoogleAuth.clearToken(accessToken)` (bản thật:
  `authorizationClient.clearAuthorizationToken`) rồi thử `driveToken()` im lặng 1 lần; vẫn không được → `lastError`
  "Phiên Google hết hạn — bấm Đồng bộ ngay" (nút đã dùng `sync(interactive: true)`). Không chạy chồng
  (`SyncState.running`), không sync khi chưa đăng nhập. Import file JSON (bước 9) cũng coi là "sửa" → debounce sync.
  Tuỳ chọn "Xóa dữ liệu trên Drive" (plan §3.10) nếu gọn: `files.delete` + đăng xuất. Test: debounce bằng
  `tester.pump(Duration)`/fake timer, 401 → clear + retry + thông báo, resume trigger, không trigger khi chưa
  đăng nhập. Thêm mục 2.10 (và 2.11 nếu có xóa Drive) vào manual-test.md.
- Bước 14 — Routing + responsive + PWA + phím (plan §4.1, §4.2, §4.3, §4.6, §4.7; D023). `usePathUrlStrategy()`
  chỉ nếu hosting bước 15 rewrite được về index.html (Cloudflare Pages có; GitHub Pages không → giữ hash hoặc
  404.html copy index.html — chọn, ghi DECISIONS). Route `/YYYY/MM?lunar=1` (đang duyệt theo tháng âm),
  DayDetail: dialog khi ≥ 1024, full page < 1024. Layout 3 breakpoint: ≥ 1024 MonthView (~65%) + panel phải cố định
  (hero "hôm nay" + Sắp tới, dùng lại `upcomingProvider`); 600–1023 một cột MonthView trên Sắp tới dưới; < 600
  như hiện tại (bottom nav). `TodayCardData` (pure, lib/data hoặc lib/core) dùng chung với widget Android bước 17.
  Phím ← → (đổi tháng), T (hôm nay), Esc (đóng DayDetail) qua Shortcuts/Actions hoặc Focus + KeyboardListener.
  web/manifest.json: name/short_name Kade, display standalone, theme/background color, icon (thay icon mặc định
  Flutter nếu có sẵn, không thì giữ). Cảnh báo một lần "Dữ liệu lưu trên trình duyệt này, bật đồng bộ Google để
  không mất" (plan §4.4) — cờ trong box settings, chỉ web. Verify tự động: widget test 3 breakpoint (đổi
  `tester.view.physicalSize`), phím tắt, route `?lunar=1`; `flutter build web` (thử `--wasm` một lần, không bắt
  buộc pass). manual-test.md: điền chi tiết 3.1–3.4.
- Bước 15 — Deploy. Nếu DECISIONS chưa chốt hosting: chọn GitHub Pages cho repo này (đơn giản, miễn phí) trừ khi
  path URL bắt buộc → Cloudflare Pages. Chuẩn bị `.github/workflows/deploy-web.yml`: checkout → Flutter 3.44.5 →
  `dart run build_runner build` trong apps/kade → `flutter build web --release --base-href /<repo>/` với
  `--dart-define=KADE_CONFIG_URL=${{ secrets.KADE_CONFIG_URL }}` và `KADE_WEB_CLIENT_ID` từ secrets → deploy
  pages artifact. Hướng dẫn user: bật Pages (Source: GitHub Actions), thêm 2 secrets, thêm origin
  `https://<user>.github.io` vào OAuth web client (setup-google B.3), URL cuối cùng. Không hardcode ID vào repo.
  ⏸ phần user; ghi setup-google.md phần C "Deploy". manual-test.md 3.5.
- Bước 16 — Notification (plan §3.8, §5.4; D025 hệ quả: `remindBeforeDays` vào form). Package
  flutter_local_notifications + timezone (đọc README đúng bản trong pubspec.lock: init, channel, POST_NOTIFICATIONS
  Android 13+, `AndroidScheduleMode.inexactAllowWhileIdle`, receiver boot/`SCHEDULE_EXACT_ALARM` không cần).
  `buildReminders(events, holidays, now, horizon 90 ngày)` pure + test: UserEvent có `remindBeforeDays` → lần xuất
  hiện kế (âm → dương qua engine, leapRule D005) − N ngày lúc 08:00 giờ máy; vnHoliday → settings
  `holidayRemindDays` (mặc định 7; UI Cài đặt "Nhắc lễ trước N ngày", plan §5.1). Lịch: cancelAll → zonedSchedule
  từng cái, id = hash(eventId, fireAt), payload `/d/<date>` → go_router. Reschedule ở resume / sau sửa / sau
  sync (tái dùng trigger bước 13). Xin quyền khi user bật nhắc lần đầu, không lúc mở app. Web: stub qua
  `lib/platform/` conditional import (plan §4.6: không nhắc trên web). Verify tự động: unit test buildReminders
  (ví dụ giỗ 15/7 âm nhắc trước 3 ngày → đúng ngày dương), widget test form có trường nhắc; APK build.
  manual-test.md 4.2.
- Bước 17 — Widget 2x2 + 4x2 (plan §5.2, §5.3, §4.3; D001/D015 package `vn.kade.kade`). Package home_widget
  (README đúng bản). `buildWidgetData(from: today, days: 35)` pure từ `TodayCardData` (bước 14) + top 3 sự kiện
  mỗi ngày + isOffDay → `HomeWidget.saveWidgetData('days_json', json)` + `updateWidget(android: 'KadeWidgetProvider')`
  ở resume / sau sửa / sau sync. Kotlin `KadeWidgetProvider` trong android/app/src/main/kotlin/vn/kade/kade/,
  layout `widget_2x2.xml`, `widget_4x2.xml` + `values-night`, AlarmManager 00:00:05 → onUpdate, fallback
  `updatePeriodMillis` 30 phút, tap → deep link `/d/<hôm nay>` (intent → MainActivity → go_router initial
  location). Nội dung theo §5.3 (hôm nay có sự kiện → dòng can chi thành tên sự kiện; ngày nghỉ → số ngày đỏ).
  Verify tự động: unit test buildWidgetData, `flutter build apk --debug`. manual-test.md 4.1, 4.5.
- Bước 18 — Release keystore + SHA-1 + Play (plan §5.5, §5.7 mục 5; E002; setup-google B.4).
  android/app/build.gradle.kts: signingConfig release đọc `android/key.properties` (gitignored; mẫu
  `key.properties.example`), fallback debug nếu thiếu để `flutter run --release` vẫn chạy. Hướng dẫn user: tạo
  keystore (`keytool -genkey -v -keystore kade-release.jks -alias kade -keyalg RSA -keysize 2048 -validity 10000`),
  lấy SHA-1 release, tạo OAuth client Android release (+ SHA-1 Play App Signing sau khi upload), `flutter build
  appbundle --dart-define-from-file=../../dart_defines.json`, Play listing. ⏸ phần user. manual-test.md 4.4.

Nếu bước nào đụng schema Hive (`UserEvent`, `SyncEnvelope`) → DECISIONS + migration + test migration (AGENTS §3);
bước 16 thêm trường vào form KHÔNG đổi schema (field `remindBeforeDays` đã có, D025).

Cuối cùng: PROGRESS "Bước hiện tại" ghi rõ trạng thái 13–18; docs/manual-test.md đầy đủ theo phase × Web/Android
(kể cả mục Android còn ⬜ của Phase 1–2); báo cáo tóm tắt cho user gồm danh sách việc user phải làm (hosting +
secrets + origin, keystore + OAuth release, Play listing) và trỏ tới docs/manual-test.md.
```
