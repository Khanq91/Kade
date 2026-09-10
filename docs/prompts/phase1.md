# Prompt kickoff — Phase 1 (từ bước 9) và template Phase 2

Copy từng khối, giao lần lượt trên session mới. Đợi xong + verify pass mới giao khối tiếp.
Bước 4–8 đã xong (xem `.memory/PROGRESS.md`; bước 6–8 cùng ngày 2026-09-10, commit `4485657`, `54d3132`, `1f471ca`).

## Bước 9 — Export/Import JSON
```
Đọc AGENTS.md rồi .memory theo thứ tự (PROGRESS, DECISIONS, ERRORS). Làm Phase 1 bước 9 trong docs/plan.md §6:
Export/Import JSON, trong apps/kade. Đọc trước plan §2.4, §2.5, §3.5, §4.4, §4.7, §5.1 và DECISIONS D004, D007,
D025, D026. Sau khi clone/pull: chạy `dart run build_runner build` trong apps/kade trước khi analyze/test (E014).

1. Model `SyncEnvelope` (plan §2.5) freezed + json trong lib/data/models/sync_envelope.dart:
   { "schema": 1, "exportedAt": ISO UTC, "deviceId": uuid, "events": [UserEvent.toJson()…] }.
   `events` = UserEventRepository.all() KỂ CẢ tombstone (D025) — cùng format với file Drive bước 12 (D004).
   deviceId: sinh uuid v4 một lần, lưu box settings key `deviceId` (settingsBoxProvider, D026).
   Parse: schema != 1, JSON hỏng, thiếu `events` → lỗi tiếng Việt (không throw ra UI).
2. Import = ghi đè theo id (repo.putAll), KHÔNG so updatedAt — để "export → xóa hết → import → giống hệt" đúng
   dù local đang có tombstone mới hơn. Đặt `updatedAt = now` cho mọi bản import để sync sau này (bước 12, merge
   theo updatedAt) không bị bản cũ trên Drive đè lại → ghi DECISIONS D027. Sau import: ref.invalidate(userEventsProvider)
   (cache tháng + Sắp tới tự tính lại). Tên file export: kade_events_YYYY-MM-DD.json.
3. Chọn/lưu file: package `file_picker` (đọc README đúng bản trong pubspec.lock): pickFiles(type: custom,
   allowedExtensions: ['json'], withData: true) và saveFile(bytes:) cho cả web + Android. Không dart:io, không
   dart:html (plan §4.7). Bọc sau interface `FileIo { Future<String?> pickJson(); Future<bool> saveJson(String name,
   String content) }` trong lib/platform/file_io.dart + `fileIoProvider` override trong main(); test override bằng fake.
   Nếu saveFile trên web không tải file được → fallback anchor download qua package:web (conditional import trong
   lib/platform/), ghi ERRORS.
4. UI: Cài đặt → mục "Sao lưu" (plan §5.1 Export-Import), đặt sau "Sự kiện của tôi": nút "Xuất file JSON" →
   SnackBar "Đã xuất N sự kiện"; "Nhập file JSON" → dialog xác nhận "Nhập N sự kiện từ file? Sự kiện trùng id sẽ bị
   ghi đè." → SnackBar kết quả hoặc lỗi. Text vào lib/core/strings.dart.
5. Test (flutter test --timeout 90s; helper test/test_app.dart, testTall cho màn dài — E009):
   envelope round trip (có tombstone, leapRule, year null, note); import ghi đè + updatedAt mới; JSON hỏng / schema
   sai → thông báo lỗi; kịch bản verify §6: tạo 3 sự kiện (dương, âm firstMonth, âm secondMonth nhiều ngày) → export
   → remove hết (tombstone) → import → activeUserEventsProvider giống hệt trừ updatedAt, và repo.all() không còn
   tombstone của 3 id đó; widget test Settings với fake FileIo: bấm Xuất → fake nhận đúng JSON; bấm Nhập → dialog →
   sự kiện hiện lại trong "Sự kiện của tôi".
6. KHÔNG đụng packages/lunar_core, packages/calendar_data. Không làm bước 10+ (không thêm google_sign_in/googleapis).
7. Verify trên web thật là việc của user (Flutter 3.44.5 — E008; port 5001 — E011;
   --dart-define-from-file=../../dart_defines.json): Cài đặt → Xuất file → mở "Sự kiện của tôi" xóa hết → Nhập file
   vừa xuất → thấy lại đủ, Sắp tới/lịch tháng hiện lại. Ghi hướng dẫn vào PROGRESS "Cần user làm", đánh ⏸ và dừng.
Commit "phase1-step9: Export/Import JSON". Cập nhật .memory (DECISIONS D027, PROGRESS, ERRORS nếu có).
Không thêm Co-Authored-By hay marker vào commit (D024).
```

## Template cho Phase 2 (bước 10–13)
Bước 10 là việc user (Google Cloud + OAuth clients, `docs/setup-google.md` phần B); agent chỉ kiểm tra
`KADE_WEB_CLIENT_ID` có trong dart_defines.json và cập nhật hướng dẫn. Từ bước 11:
```
Đọc AGENTS.md rồi .memory theo thứ tự. Làm Phase 2 bước {M} trong docs/plan.md §6, tiêu chí verify ở §6 và §4.8.
Đọc trước plan §3.10, §4.4, §5.5 và DECISIONS D007, D025, D027. Chỉ bước này. google_sign_in ≥ 7 API mới (E003):
đọc README đúng bản trong pubspec.lock, không theo sample cũ. Xong → verify → commit "phase2-step{M}: ..." →
cập nhật .memory. Việc cần tôi làm (OAuth console, chạy web/thiết bị thật, đăng nhập tài khoản) → ghi PROGRESS
"Cần user làm", đánh ⏸ và dừng.
Lưu ý máy: Flutter 3.44.5 (E008), test với --timeout 90s (E009), web port 5001 — origin OAuth phải có
http://localhost:5001 (E011), luôn --dart-define-from-file=../../dart_defines.json, chạy build_runner sau pull (E014).
Không thêm Co-Authored-By vào commit (D024).
```
