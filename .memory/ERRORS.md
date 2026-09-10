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
