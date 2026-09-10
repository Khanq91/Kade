# AGENTS.md — Kade

Áp dụng cho mọi AI agent làm việc trong repo này (Claude Code, Codex, Cursor, ...).
File này là nguồn duy nhất; `CLAUDE.md` chỉ import file này.

## 1. Dự án

Kade — app lịch âm/dương Việt Nam, Flutter, target **web + Android** (iOS phase sau).
Toàn bộ thiết kế, data model, luồng, roadmap nằm ở `docs/plan.md`. Plan là nguồn sự thật;
nếu code và plan mâu thuẫn → hỏi user, không tự chọn.

## 2. Bắt đầu mỗi session — BẮT BUỘC, theo thứ tự

1. Đọc `.memory/PROGRESS.md` → biết đang ở phase/bước nào, có gì đang chờ user.
2. Đọc `.memory/DECISIONS.md` → các quyết định đã chốt, KHÔNG đặt lại câu hỏi đã có đáp án ở đây.
3. Đọc `.memory/ERRORS.md` → lỗi/quirk đã gặp, đừng dẫm lại.
4. Đọc phần của `docs/plan.md` liên quan tới bước sắp làm (không cần đọc cả file mỗi lần).
5. Nói ngắn gọn với user: "Đang ở bước X, sẽ làm Y" rồi mới bắt đầu.

## 3. Cách làm việc

- **Một bước một lần.** Làm đúng bước user giao (theo số bước trong `docs/plan.md` §6). Không làm trước bước sau, không thêm feature ngoài bước, không "tiện tay" refactor chỗ khác.
- **Verify trước khi báo xong.** Mỗi bước có tiêu chí verify trong plan. Chạy nó. Chỉ báo "xong" khi pass. Fail → sửa → chạy lại; không hỏi user giữa chừng trừ khi bế tắc hoặc cần quyết định.
- **Không bịa dữ liệu lịch.** Thuật toán gốc: `docs/reference/amlich-aa98.js`. Fixture test: `docs/reference/tet_1900_2100.json`. Không tự nhớ ngày Tết, hằng số Meeus, hay danh sách ngày lễ — lấy từ reference và plan.
- **Đơn giản trước.** Không abstraction cho code dùng 1 chỗ, không config/flag không ai yêu cầu, không try/catch cho case không xảy ra.
- **Commit mỗi bước**, message: `phase{N}-step{M}: <mô tả ngắn>`. Không commit khi test đỏ. Message chỉ gồm nội dung thay đổi: KHÔNG tự thêm `Co-Authored-By:`, "Generated with …" hay bất kỳ dòng đánh dấu agent/tool nào (user chốt 2026-09-10, D024).
- **Đụng schema Hive** (field mới/đổi tên trong `UserEvent`, `SyncEnvelope`) → bắt buộc ghi DECISIONS + viết migration + test migration.
- **Không đụng `packages/lunar_core`** khi đang làm bước UI/sync. Engine đã verify ở Phase 0; muốn sửa → ghi DECISIONS trước, chạy lại full fixture test sau.
- Việc chỉ user làm được (Google Cloud, Apps Script deploy, keystore, test thiết bị thật, kiểm tra CORS trên domain thật): viết code + hướng dẫn, ghi vào `PROGRESS.md` mục "Cần user làm", đánh dấu bước ⏸, rồi dừng.

## 4. Ghi memory — BẮT BUỘC

Ba file trong `.memory/`. Tất cả là **append-only** trừ bảng trạng thái trong PROGRESS.
Không sửa/xóa entry cũ; sai thì append entry mới ghi "sửa D00x".

### `.memory/DECISIONS.md` — ghi KHI:
- chọn 1 trong nhiều cách làm hợp lệ (thư viện, cấu trúc, thuật toán, format)
- đi lệch plan vì lý do kỹ thuật
- chốt một mục plan đánh dấu "chốt khi code"
- user chốt một quyết định trong chat

Format:
```
## YYYY-MM-DD — D0NN — <tiêu đề ngắn>
- Bởi: <agent | user>
- Quyết định: <1–2 câu>
- Lý do: <1–2 câu>
- Hệ quả: <ảnh hưởng tới code/plan, hoặc "không">
```

### `.memory/ERRORS.md` — ghi KHI:
- một lỗi tốn > 1 lần thử mới qua
- quirk của môi trường / thư viện / platform (version, flag, thứ tự lệnh)
- workaround đang dùng mà chưa phải cách đúng

Format:
```
## YYYY-MM-DD — E0NN — <tiêu đề ngắn>
- Bối cảnh: <đang làm gì, phase/bước>
- Triệu chứng: <message lỗi rút gọn / hành vi>
- Nguyên nhân: <nếu biết>
- Cách xử lý: <đã làm gì>
- Trạng thái: <fixed | workaround | open>
```

### `.memory/PROGRESS.md` — cập nhật KHI:
- kết thúc một bước (pass verify) → đổi trạng thái bảng + append log
- dừng giữa bước (hết session, chờ user) → ghi "Đang dở" nói rõ đã làm gì, còn gì
- phát sinh việc user phải làm → thêm vào "Cần user làm"

Trạng thái: `⬜` chưa làm · `🔄` đang làm · `⏸` chờ user · `✅` xong.
Log format: `- YYYY-MM-DD — phase{N}-step{M} — <kết quả 1 dòng> — <commit hash nếu có>`

## 5. Stack & lệnh

| | |
|---|---|
| Flutter | ≥ 3.24 (cần Dart pub workspaces) |
| Monorepo | pub workspace: root `pubspec.yaml` liệt kê `packages/*`, `apps/*` |
| State | Riverpod (không codegen) |
| Routing | go_router |
| Storage | Hive CE |
| Model | freezed + json_serializable |
| Auth/Sync | google_sign_in (≥ 7, API mới — đọc README bản đang dùng, đừng theo sample cũ) + googleapis, scope `drive.appdata` |
| Widget | home_widget |
| Notification | flutter_local_notifications + timezone |
| Test | `flutter test` / `dart test` (pure packages) |

```
# root
dart pub get                                  # resolve toàn workspace
dart run build_runner build -d               # chạy trong apps/kade khi đổi model
cd packages/lunar_core && dart test           # engine
cd apps/kade && flutter test                  # app
flutter run -d chrome --web-port 5000 --dart-define-from-file=../../dart_defines.json   # web dev, chạy trong apps/kade; port cố định khớp OAuth origin
flutter run -d <android-device> --dart-define-from-file=../../dart_defines.json
```

## 6. Cấu trúc repo

```
kade/
├ AGENTS.md  CLAUDE.md  .memory/  docs/  tools/  assets/
├ packages/lunar_core/      # pure Dart, zero deps
├ packages/calendar_data/   # pure Dart, lễ + YearOverride model + asset fallback
└ apps/kade/                # Flutter (xem docs/plan.md §1 cho cây lib/)
```

## 7. Quy ước code

- Dart: `dart format`, lints `package:flutter_lints`, không `dynamic` trừ khi parse JSON.
- Tên: file `snake_case.dart`, class `PascalCase`, Riverpod provider `xxxProvider`.
- `lunar_core`: mọi hàm public có doc comment 1 dòng + test. Không import Flutter.
- Text UI tiếng Việt có dấu, giữ trong file `lib/core/strings.dart` (chưa i18n, nhưng gom 1 chỗ).
- Không `print`; dùng `log` từ `dart:developer`.
- URL/ID môi trường: `KADE_CONFIG_URL`, `KADE_WEB_CLIENT_ID` truyền qua `--dart-define-from-file=dart_defines.json` (root repo, gitignored; mẫu ở `dart_defines.example.json`), đọc bằng `String.fromEnvironment` trong `lib/core/env.dart`. Không hardcode, không commit file thật. Thiếu giá trị → app vẫn chạy, chỉ tắt tính năng tương ứng và `log` cảnh báo.
