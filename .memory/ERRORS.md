# ERRORS — Kade

Append-only. Lỗi/quirk đã gặp để không dẫm lại. Format: `AGENTS.md` §4.

## 2026-09-09 — E001 — (ghi trước) Dart pub workspaces cần Flutter ≥ 3.24
- Bối cảnh: setup monorepo, Phase 0.
- Triệu chứng: `dart pub get` báo không hiểu `workspace:` nếu SDK cũ.
- Nguyên nhân: pub workspaces có từ Dart 3.5 / Flutter 3.24.
- Cách xử lý: `flutter --version` trước; nếu cũ → nâng, không dùng melos thay thế.
- Trạng thái: open (chưa gặp, ghi để phòng)

## 2026-09-09 — E002 — (ghi trước) Google Sign-In Android fail chỉ trên bản release
- Bối cảnh: Phase 2/4.
- Triệu chứng: đăng nhập được trên debug, bản release ký keystore thật báo lỗi 10 / DEVELOPER_ERROR.
- Nguyên nhân: OAuth client Android chỉ có SHA-1 debug.
- Cách xử lý: tạo thêm OAuth client Android với SHA-1 release (và SHA-1 của Play App Signing nếu dùng). Xem `docs/setup-google.md` B.4.
- Trạng thái: open (chưa gặp, ghi để phòng)

## 2026-09-09 — E003 — (ghi trước) google_sign_in ≥ 7 đổi API
- Bối cảnh: Phase 2.
- Triệu chứng: sample cũ (`GoogleSignIn(scopes: ...)`, `signIn()`) không compile / deprecated.
- Nguyên nhân: v7 (2025) tách authentication và authorization (`GoogleSignIn.instance.initialize`, `authenticate()`, `authorizationClient.authorizationForScopes`).
- Cách xử lý: đọc README đúng version trong `pubspec.lock` trước khi viết.
- Trạng thái: open (chưa gặp, ghi để phòng)

## 2026-09-10 — E004 — pub workspace: glob trong `workspace:` phải khớp ≥ 1 package
- Bối cảnh: Phase 0 bước 1, tạo workspace root với `packages/*`, `apps/*`.
- Triệu chứng: `dart pub get` → `No workspace packages matching apps/*. That was included in the workspace of .\pubspec.yaml.`
- Nguyên nhân: Dart 3.12.2 (Flutter 3.44.5) hỗ trợ glob trong `workspace:`, nhưng glob không khớp thư mục nào là lỗi, không phải cảnh báo. (E001 không xảy ra: SDK đủ mới.)
- Cách xử lý: chỉ để `- packages/*`, comment `apps/*` trong root `pubspec.yaml`; bật lại khi tạo `apps/kade`.
- Trạng thái: workaround

## 2026-09-10 — E005 — reference `convertSolar2Lunar` trả lunar day 0 cho 2 ngày trong 1900–2100
- Bối cảnh: Phase 0 bước 1, test số ngày âm của từng ngày so với fixture.
- Triệu chứng: `solarToLunar(2054-05-07)` = 0/4/2054, `solarToLunar(2062-04-09)` = 0/3/2062. JS gốc chạy `node` cho y hệt → port đúng, reference sai. Fixture (sinh từ JS) gộp 2 ngày này vào tháng kế: tháng trước thiếu 1 ngày (fixture 29, thật 30), tháng sau `start` sớm 1 ngày và `days` thừa 1.
- Nguyên nhân: `k = INT((jd - 2415021.076998695) / 29.530588853)` ước lượng theo sóc trung bình; khi sóc thực trễ hơn sóc trung bình và rơi vào ngày hôm sau (giờ +7), `getNewMoonDay(k)` vẫn > jd nhưng code chỉ lùi đúng 1 sóc → `lunarDay = 0`. Round-trip vẫn khớp (`convertLunar2Solar(0, m, y)` = ngày trước mùng 1) nên test hai chiều không bắt được.
- Cách xử lý: giữ 1:1; `fixture_test.dart` nới đúng 2 ngày này qua `referenceDayZero`; `reference_quirks_test.dart` ghim quirk + khẳng định không còn ngày nào khác có day 0 trong 1900–2100. Sửa thật chờ D013.
- Trạng thái: open

## 2026-09-10 — E006 — chú thích giá trị `NewMoon` trong reference lệch với chính hàm
- Bối cảnh: viết test từng hàm port theo chú thích trong `amlich-aa98.js`.
- Triệu chứng: chú thích ghi `NewMoon(2) = 2415079.9758617813`, `NewMoon(-2) = 2414961.935157746`; JS thực tế (node v24.15.0) cho 2415079.9761049072 và 2414961.9343954599 (lệch ~2.4e-4 ngày). Dart khớp JS tới 17 chữ số.
- Nguyên nhân: chú thích từ phiên bản công thức cũ, không cập nhật.
- Cách xử lý: `amlich_test.dart` dùng giá trị chạy thực từ JS, ghi rõ nguồn.
- Trạng thái: fixed

## 2026-09-10 — E005 (cập nhật) — đã fixed theo D014
- Bối cảnh: user chốt sửa reference.
- Cách xử lý: patch JS + port, sinh lại fixture, test regression `reference_patch_test.dart`.
- Trạng thái: fixed

## 2026-09-10 — E007 — pub workspace có app Flutter: `dart pub get` ở root vẫn chạy được
- Bối cảnh: chuyển scaffold vào `apps/kade`, sợ `dart pub get` không resolve được `sdk: flutter`.
- Triệu chứng: không có lỗi — `dart pub get` (Dart 3.12.2 đi kèm Flutter 3.44.5) và `flutter pub get` đều resolve được; `flutter_test` ép `test_core` 0.6.20 → 0.6.17, `test` vẫn 1.32.0.
- Nguyên nhân: `dart` trên PATH là bản trong Flutter SDK nên biết `FLUTTER_ROOT`.
- Cách xử lý: dùng lệnh nào cũng được; nếu máy khác dùng Dart SDK riêng thì dùng `flutter pub get`.
- Trạng thái: fixed (ghi để biết)

## 2026-09-10 — E008 — Terminal VS Code dùng Flutter cũ (Dart 3.10.8) → "language version 3.12 too high"
- Bối cảnh: user chạy `dart run example/day_info_example.dart` trong terminal VS Code (phase0-step2).
- Triệu chứng: `Error: The language version 3.12 specified for the package 'lunar_core' is too high. The highest supported language version is 3.10.` cho mọi file.
- Nguyên nhân: máy có 2 Flutter: `D:\khang\data\flutterDev\flutter` (Dart 3.10.8, cũ) và `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter` (Dart 3.12.2, trên PATH hệ thống, Android Studio dùng, tạo project với `sdk: ^3.12.0`). VS Code user settings `dart.flutterSdkPath` trỏ vào bản cũ → extension Dart chèn bản cũ vào PATH của terminal VS Code.
- Cách xử lý: user đổi `dart.flutterSdkPath` (settings.json user của VS Code) sang `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter` (hoặc xóa key để dùng PATH), mở terminal mới. Tạm thời: gọi thẳng `D:\khang\data\flutterDev\flutter_windows_3.44.5-stable\flutter\bin\dart.bat run ...`. Không hạ `sdk` constraint vì app của user đã yêu cầu ^3.12.0.
- Trạng thái: open (chờ user đổi setting)

## 2026-09-10 — E009 — testWidgets + Hive ghi file thật → treo 10 phút ở tearDown
- Bối cảnh: Phase 1 bước 5, widget test `SettingsScreen` dùng `RemoteConfigRepository` với Hive box thật (thư mục temp).
- Triệu chứng: test fetch → `box.putAll` không bao giờ xong, UI kẹt "Đang kiểm tra…"; `Hive.close()` trong `tearDown` chờ mãi → `TimeoutException after 0:10:00`.
- Nguyên nhân: body của `testWidgets` chạy trong FakeAsync; IO thật (`dart:io` của Hive) không hoàn tất trong zone đó, callback bị kẹt; `close()` chờ lock ghi.
- Cách xử lý: bọc toàn bộ body trong `await tester.runAsync(() async { ... })`, thay `pumpAndSettle` bằng vòng `pump` + `Future.delayed` ngắn tới khi hết spinner. Luôn chạy `flutter test --timeout 90s` để không treo 10 phút. Thêm: viewport test 800×600 → ListTile dưới fold là offstage, `find.text` mặc định bỏ qua → `tester.ensureVisible(find.text(x, skipOffstage: false))` trước khi assert.
- Trạng thái: fixed

## 2026-09-10 — E010 — Apps Script cold start ~3.2s (đo bằng node, có redirect 302)
- Bối cảnh: kiểm tra URL thật trong `dart_defines.json` trước bước 5.
- Triệu chứng: GET `/exec` → 302 → `script.googleusercontent.com`, 200 JSON, `access-control-allow-origin: *`, tổng 3166 ms lần đầu.
- Nguyên nhân: cold start Apps Script (setup-google A.6 nói 1–3s).
- Cách xử lý: giữ timeout 5s theo plan §3.9; nếu user thấy hay fail "TimeoutException" trên web thì nâng lên 8–10s (đổi `RemoteConfigRepository.timeout` mặc định) và ghi DECISIONS.
- Trạng thái: open (theo dõi)

## 2026-09-10 — E008 (cập nhật) — thêm triệu chứng: `flutter run` báo `Could not find a file named "pubspec.yaml" in "…\packages\*"`
- Bối cảnh: user chạy `flutter run -d chrome …` trong terminal VS Code (bước 5 verify).
- Triệu chứng: `Could not find a file named "pubspec.yaml" in "D:\…\Kade\packages\*". That was included in the workspace of ..\..\pubspec.yaml. Failed to update packages.`
- Nguyên nhân: cùng E008 — terminal dùng Flutter 3.38.9 / Dart 3.10.8 (`D:\khang\data\flutterDev\flutter`), pub bản này chưa hiểu glob trong `workspace:`; bản 3.44.5 / Dart 3.12.2 resolve bình thường. Bản cũ dù có sửa glob cũng không build được vì `sdk: ^3.12.0`.
- Cách xử lý: dùng Flutter 3.44.5 (đổi `dart.flutterSdkPath` trong VS Code hoặc gọi thẳng `…\flutter_windows_3.44.5-stable\flutter\bin\flutter.bat`, hoặc mở PowerShell/cmd ngoài VS Code — PATH hệ thống đã trỏ bản mới). Không đổi workspace glob.
- Trạng thái: open (chờ user đổi SDK trong VS Code)

## 2026-09-10 — E011 — Port 5000 trên máy user bị `QLVanBanAPI` (project .NET khác) chiếm
- Bối cảnh: `flutter run -d chrome --web-port 5000` khi verify bước 5.
- Triệu chứng: `Failed to bind web development server: SocketException … errno = 10048, port = 5000`.
- Nguyên nhân: PID của `D:\khang\project\QLVB\QLVanBanAPI\bin\Debug\net8.0\QLVanBanAPI.exe` đang lắng nghe 127.0.0.1:5000 và [::1]:5000.
- Cách xử lý: tắt API đó khi chạy Kade web, hoặc chạy `--web-port 5001` (bước 5 không phụ thuộc port vì Apps Script trả CORS `*`). Phase 2: origin OAuth web đã ghi `http://localhost:5000` trong setup-google B.3 → nếu user hay chạy 5001 thì thêm cả `http://localhost:5001` vào Authorized JavaScript origins.
- Trạng thái: workaround

## 2026-09-10 — E012 — Bash tool (Git Bash) không parse được lệnh nhiều heredoc dài chứa Dart/tiếng Việt
- Bối cảnh: bước 6, ghi 4 file Dart bằng một lệnh `cat > f <<'EOF' … EOF` nối nhau.
- Triệu chứng: `unexpected EOF while looking for matching `''` ở một dòng giữa lệnh; không file nào được ghi.
- Nguyên nhân: chưa rõ (nghi tool tiền xử lý quote/ký tự đa byte trước khi giao cho bash); lệnh heredoc ngắn 1 file (script probe) vẫn chạy.
- Cách xử lý: ghi file nguồn bằng Write/Edit tool; Bash chỉ dùng cho lệnh chạy (format, analyze, test, git).
- Trạng thái: workaround

## 2026-09-10 — E013 — Riverpod 3: kiểu `Override` không nằm trong `package:flutter_riverpod/flutter_riverpod.dart`
- Bối cảnh: bước 6, helper test trả `List<Override>`.
- Triệu chứng: `The name 'Override' isn't a type` dù `ProviderScope(overrides:)` nhận `List<Override>`.
- Nguyên nhân: riverpod 3 đánh dấu `Override` là `@publicInMisc` → chỉ export qua `package:flutter_riverpod/misc.dart` (cũng có `ProviderContainer.test`, `AsyncNotifierProvider.overrideWith(() => Notifier)` thì ở export chính).
- Cách xử lý: `import 'package:flutter_riverpod/misc.dart' show Override;`. Lưu ý thêm: `Notifier.state` là `@protected` → test muốn đổi state phải gọi method của subclass (xem `FakeRemoteConfig.replace`).
- Trạng thái: fixed

## 2026-09-10 — E014 — build_runner 2.15: `-d` / `--delete-conflicting-outputs` bị bỏ (chỉ cảnh báo); freezed resolve bản 3.2.6-dev.1
- Bối cảnh: bước 7, `flutter pub add dev:freezed` rồi `dart run build_runner build -d`.
- Triệu chứng: `W These options have been removed and were ignored: --delete-conflicting-outputs` (vẫn build OK). Pub chọn `freezed 3.2.6-dev.1` (bản stable 3.x xung đột analyzer 12.1.0 mà build_runner 2.15 kéo; freezed 4 cần analyzer mới hơn).
- Nguyên nhân: build_runner ≥ 2.15 luôn ghi đè output; freezed stable chưa hỗ trợ analyzer 12 tại thời điểm này.
- Cách xử lý: dùng `dart run build_runner build` (không `-d`), đã sửa AGENTS.md §5. Giữ `freezed: ^3.2.6-dev.1` — sinh code đúng, 48 test pass. Khi freezed 3.3/4.x stable resolve được thì nâng.
- Trạng thái: workaround

## 2026-09-10 — E009 (cập nhật) — widget test màn dài: dùng `testTall` (viewport 800×1600)
- Bối cảnh: bước 7, `find.text` / `tap` nút "Lưu" ở cuối form và mục "Sự kiện cá nhân" cuối DayDetail báo không tìm thấy.
- Nguyên nhân: cùng E009 — dưới fold 600px là offstage.
- Cách xử lý: `test/user_events_test.dart` có helper `testTall()` đặt `tester.view.physicalSize = 800×1600`, `devicePixelRatio = 1`, `addTearDown(tester.view.reset)`. Test màn dài (form, DayDetail, Settings) dùng helper này thay vì `ensureVisible` từng widget.
- Trạng thái: fixed

## 2026-09-10 — E015 — file_picker 12 (federated): API khác prompt bước 9; `saveFile` trên web luôn trả null
- Bối cảnh: bước 9, `flutter pub add file_picker` resolve 12.2.0 (federated: android_file_picker 1.1.1, file_picker_web 3.1.0, …).
- Triệu chứng: `pickFiles()` trả `List<PlatformFile>` (rỗng = hủy), `withData:` deprecated (README v12: dùng `file.readAsBytes()`); có `pickFile()` trả `PlatformFile?`. `saveFile(bytes:)` trả `Uri?`: Android ghi qua SAF, trả `content://…` hoặc null khi hủy; web tạo Blob + `<a download>` click rồi **luôn trả null** (không phân biệt hủy).
- Nguyên nhân: v12 đổi API (README "Migrating to v12"); bản web không có hộp thoại lưu nên không biết user hủy.
- Cách xử lý: `FilePickerFileIo.saveJson` trả `kIsWeb || uri != null`; `pickJson` dùng `pickFile` + `readAsBytes` + `utf8.decode(allowMalformed: true)` (byte hỏng → JSON hỏng → thông báo tiếng Việt). Không thêm `package:web`/conditional import. Web thật chưa verify (chờ user).
- Trạng thái: workaround (ghi để bước 12 không dùng `withData`)

## 2026-09-10 — E009 (cập nhật) — `ListView(children:)` không build con ngoài viewport + cacheExtent → `find(skipOffstage: false)` cũng không thấy
- Bối cảnh: bước 9 thêm mục "Sao lưu" vào Cài đặt → 2 test cũ `settings_screen_test.dart` đỏ "Bad state: No element" ở `ensureVisible(find.text(yearTitle, skipOffstage: false))`.
- Nguyên nhân: tile năm bị đẩy xuống quá 600px + cacheExtent 250px → widget chưa được build (không phải chỉ offstage).
- Cách xử lý: đổi 2 test sang `testTall` (viewport 1600, giờ nằm ở `test/test_app.dart`). Quy tắc: widget test màn có ListView dài → luôn `testTall`, đừng trông vào `skipOffstage: false`.
- Trạng thái: fixed

## 2026-09-10 — E016 — `flutter build apk` đỏ ở `:android_file_picker:compileDebugKotlin`: "Could not close incremental caches … Storage … is already registered"
- Bối cảnh: Phase 2 bước 10, build APK debug lần đầu sau khi thêm `file_picker` 12.2.0 (bước 9) và đổi `applicationId` → `vn.kade.kade`.
- Triệu chứng: Kotlin compile của module plugin xong (chỉ warning) rồi fail lúc đóng cache incremental: `Could not close incremental caches in build\android_file_picker\kotlin\compileDebugKotlin\cacheable\…: class-fq-name-to-source.tab …`, suppressed `IllegalStateException: Storage for […] is already registered`. Lặp lại ổn định (12s), cả khi xóa `build/android_file_picker` và khi `-Pkotlin.compiler.execution.strategy=in-process` → không phải daemon/cache hỏng.
- Nguyên nhân: `android_file_picker` 1.1.x (CHANGELOG 1.1.0) khôi phục `buildscript { classpath AGP 8.5.2 + kotlin-gradle-plugin 1.8.22 }` trong `android/build.gradle.kts` của plugin làm workaround cho project `android.newDsl=false` (flutter_file_picker#2170; 1.0.3 đã bỏ pin này vì "module supports AGP 9 and Kotlin 2.3"). Project Kade (template Flutter 3.44: AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1, `android.newDsl=false`, `android.builtInKotlin=false`) → classpath module trộn 2 bản KGP → phần incremental compilation đăng ký storage 2 lần.
- Cách xử lý: thêm `kotlin.incremental=false` vào `apps/kade/android/gradle.properties` (áp cho mọi module; app chỉ có 1 file Kotlin nên không tốn). Verify: `./gradlew :android_file_picker:compileDebugKotlin -Pkotlin.incremental=false` BUILD SUCCESSFUL. Lựa chọn khác không dùng: `dependency_overrides: android_file_picker: 1.0.3` (bản không pin, nhưng có thể dính #2170), hay bật `android.newDsl=true` (Flutter template cố ý tắt). Khi plugin bỏ pin (Flutter hoàn tất migration newDsl, flutter/flutter#180137) → xóa dòng này.
- Trạng thái: workaround

## 2026-09-10 — E017 — Test vòng đời app: `handleAppLifecycleStateChanged` là `@protected`, Flutter phát trạng thái trung gian
- Bối cảnh: bước 13, widget test "resume sau > 15 phút → sync".
- Triệu chứng: gọi `tester.binding.handleAppLifecycleStateChanged(...)` → lint `invalid_use_of_protected_member`. Gửi `paused` rồi `resumed` qua kênh nền tảng thì observer nhận `inactive, hidden, paused` rồi `hidden, inactive, resumed` (ServicesBinding `_generateStateTransitions`).
- Nguyên nhân: API là `@protected` trong SchedulerBinding; Flutter ≥ 3.13 luôn sinh chuỗi trạng thái liền kề.
- Cách xử lý: helper `sendLifecycle(tester, state)` trong `test/test_app.dart` gửi `StringCodec().encodeMessage('AppLifecycleState.paused')` qua `defaultBinaryMessenger.handlePlatformMessage(SystemChannels.lifecycle.name, …)` như Flutter thật. Observer phải chịu được trạng thái trung gian: `SyncTrigger` chỉ ghi mốc rời foreground ở lần chuyển đầu tiên (cờ `_foreground`), không ghi đè ở hidden/inactive trước resumed.
- Trạng thái: fixed

## 2026-09-10 — E018 — Font test rộng 1em/ký tự + layout medium làm ô ngày overflow; IDE diagnostics (SDK cũ) báo sai import
- Bối cảnh: bước 14, viewport test 800×600 giờ là layout medium (lưới 3/5 chiều cao) và test 400px.
- Triệu chứng: `RenderFlex overflowed by 1.9 pixels on the right` (Row số dương + số âm trong `DayTile` ở 400px) và `overflowed 5.7/9.6 px on the bottom` (Column nhãn trong ô khi hàng ~50px) → mọi widget test render MonthView đỏ lây (exception render = fail). Đồng thời hook IDE báo `import 'package:flutter/services.dart'` "unnecessary" nhưng `flutter analyze` 3.44.5 báo `LogicalKeyboardKey` undefined khi bỏ import.
- Nguyên nhân: font test "FlutterTest" mỗi glyph rộng đúng 1em (chữ số 15px = 15px) nên text dài hơn thật ~2×; ô ngày thấp thì Column con (title + tags) không co được. IDE dùng Flutter 3.38.9 (E008) → analyzer khác bản build.
- Cách xử lý: `DayTile`: số âm trong `Expanded(Text(maxLines 1, softWrap false, clip))`; phần nhãn bọc `ClipRect > OverflowBox(maxHeight ∞) > Column(min)` để cắt thay vì overflow. Test assert text trong lịch dùng `find.descendant(of: find.byType(MonthCalendar))` vì panel Sắp tới ở ≥ 600 cũng có tên sự kiện. Tin `flutter analyze` (3.44.5), không tin diagnostics IDE khi mâu thuẫn. Gửi 2 phím liên tiếp phải `pumpAndSettle` giữa chừng (widget cũ còn nhận phím thứ 2).
- Trạng thái: fixed

## 2026-09-10 — E019 — Riverpod 3: `ref.listen` trên provider dẫn xuất nhiều tầng không bắn đủ trong test; đọc ngay sau khi Notifier đổi vẫn ra bản cũ
- Bối cảnh: bước 17, `WidgetUpdater` ban đầu `ref.listen(widgetDataProvider)` (Provider → dayCellProvider → monthProvider → activeUserEventsProvider → userEventsProvider Notifier). Widget test: tạo sự kiện → `pumpAndSettle` → không có lần đẩy nào; đọc thẳng `c.read(widgetDataProvider)` sau đó thì lại ra bản mới.
- Triệu chứng: listener trên provider dẫn xuất 3–4 tầng không được gọi (Riverpod 3 đánh dấu dirty + refresh theo từng tầng qua task `Future(...)`; `pumpAndSettle` dừng khi hết frame nên các tầng sau không kịp flush); listener trên Notifier (`userEventsProvider`) thì bắn ngay, nhưng trong callback đó `ref.read(widgetDataProvider)` chưa chắc mới (chuỗi chưa được đánh dấu).
- Nguyên nhân: Riverpod 3 tính lại provider dẫn xuất lười (khi có người đọc / khi scheduler flush từng tầng), khác Riverpod 2.
- Cách xử lý: side-effect (đẩy widget, đặt thông báo, sync) → `ref.listen` trên **Notifier nguồn** (`userEventsProvider`, `layersProvider`, `remoteConfigProvider.select(...)`, `authProvider`) và tính dữ liệu cần thiết **trực tiếp từ state nguồn** bằng hàm pure (`computeWidgetData` dùng `buildMonth`; `buildReminders` dùng `userEventsProvider`), không đọc provider dẫn xuất trong callback. Widget UI (`ref.watch`) không bị ảnh hưởng. Lưu ý khi debug: assert nội dung phải tính cả sự kiện app có sẵn của ngày đó (03/02 có "Ngày thành lập Đảng") — lỗi assert ban đầu bị tưởng nhầm là stale.
- Trạng thái: fixed (quy tắc cho bước sau)

## 2026-09-10 — E020 — GitHub Actions deploy-pages: "Failed to get ID Token … Request timeout" dù đã có `id-token: write`
- Bối cảnh: bước 15, lần chạy workflow deploy-web đầu tiên của user; job `build` xanh, job `deploy` đỏ ở `actions/deploy-pages@v4`.
- Triệu chứng: `Error: Failed to get ID Token. Error Message: Request timeout: /…/idtoken/…` rồi gợi ý "Ensure GITHUB_TOKEN has permission id-token: write" (gợi ý gây hiểu nhầm — quyền đã đúng ở `permissions:` cấp workflow). Kèm cảnh báo Node 20 deprecated trên runner (chỉ warning).
- Nguyên nhân: endpoint OIDC của GitHub timeout (quá tải/incident), không phải cấu hình.
- Cách xử lý: Re-run failed jobs là đủ. Workflow thêm `continue-on-error` cho bước deploy + bước `retry` chạy lại `deploy-pages@v4` khi bước đầu fail, `timeout-minutes: 15`. Nếu lỗi lặp lại nhiều lần với message khác ("Get Pages site failed", "Resource not accessible") → xem setup-google C.1/C.5.
- Trạng thái: workaround
