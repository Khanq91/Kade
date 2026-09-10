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
