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
