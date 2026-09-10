# Kade — Checklist test thủ công (theo phase × Web / Android)

Mục đích: user test tay MỘT LƯỢT cuối (D031). Agent thêm mục vào đây sau mỗi bước
(thay cho PROGRESS "Cần user làm"). Trạng thái ô: `⬜` chưa test · `✅ <ngày>` OK ·
`❌` lỗi (ghi ở mục "Ghi lỗi" cuối file) · `—` không áp dụng.

## Chuẩn bị
- Web (từ `apps/kade`, Flutter 3.44.5 — E008; port 5001 — E011):
  `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
  Máy thứ 2 để test sync: `-d edge` cùng port, hoặc Chrome profile khác, hoặc Android.
- Android (thiết bị thật / emulator có Google Play):
  `flutter run -d <device> --dart-define-from-file=../../dart_defines.json`
  hoặc cài APK: `flutter build apk --debug --dart-define-from-file=../../dart_defines.json`
  → `build/app/outputs/flutter-apk/app-debug.apk`. Package `vn.kade.kade`, SHA-1 debug đã đăng ký (setup-google B.4).
- Tài khoản Google phải nằm trong Test users (setup-google B.2).
- Xem / xóa dữ liệu sync: Drive web → ⚙ Settings → Manage apps → Kade → "hidden app data" / Delete hidden app data.
- Lỗi hay gặp (mọi phase): xem bảng cuối file.

## Phase 0 — Engine
Không test tay. 256 test tự động (fixture 1900–2100, bảng == runtime, 10 ngày + 24 tiết khí user đã đối chiếu D017).
Sanity ngoài: `docs/reference/README.md`.

## Phase 1 — Data + Core UI
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 1.1 | Lịch tháng `/2027/02` (web: URL `/#/2027/02`; Android: bấm ▶ tới 2/2027): ô 5/2 nhãn ÂL đỏ (Giao thừa) + nền nghỉ; 6/2 ÂL đỏ (Tết) + nền nghỉ; 9/2 nền nghỉ (nghỉ bù) không nhãn; 14/2 DL xanh (Valentine) không nghỉ; 20/2 ÂL cam (Rằm tháng Giêng) | ✅ 2026-09-10 | ⬜ |
| 1.2 | Đang ở tháng khác → F5 (web) vẫn đúng tháng. Android: kill app mở lại không crash | ✅ 2026-09-10 | ⬜ |
| 1.3 | Tap ô 6/2/2027 → "Thứ Bảy, 06/02/2027", "Âm lịch 1/1 · Năm Đinh Mùi", Tháng Nhâm Dần (Giêng), Ngày Bính Thìn, Ngày hoàng đạo Kim Quỹ, 6 giờ hoàng đạo, mục Nghỉ lễ → Tết Nguyên đán (ÂL); ◀ ▶ / vuốt đổi ngày; Quay lại | ✅ 2026-09-10 | ⬜ |
| 1.4 | Đổi ngày: dương → âm + can chi; 1/1/2027 âm → "Thứ Bảy, 06/02/2027"; 1/5/2027 tick nhuận → "Năm 2027 không có tháng 5 nhuận" | ✅ 2026-09-10 | ⬜ |
| 1.5 | Tiêu đề "Tháng 2/2027" → picker tháng dương; "Tháng âm" → picker âm (năm nhuận có chip "X nhuận", vd 2025 "6 nhuận") | ✅ 2026-09-10 | ⬜ |
| 1.6 | Cài đặt → "Kiểm tra cập nhật" → SnackBar; đổi 1 dòng off/work trong Sheet → bấm lại → ô lịch đổi theo | ✅ 2026-09-10 | ⬜ |
| 1.7 | Sự kiện cá nhân: tạo từ DayDetail ("+ Thêm sự kiện") và từ Sự kiện của tôi (+); sửa tên/màu; xóa (dialog); reload còn; âm 15/6 hàng năm → năm 2025 chỉ hiện tháng 6 chính, không hiện tháng 6 nhuận | ✅ 2026-09-10 | ⬜ |
| 1.8 | Sắp tới: 4 chip lớp (tắt "Nghỉ lễ" → Tết biến mất, bật lại; tắt/bật giữ sau reload); "Còn N ngày"; sự kiện âm cá nhân hiện đúng ngày dương năm nay/năm sau; tap → DayDetail | ✅ 2026-09-10 | ⬜ |
| 1.9 | Sao lưu: "Xuất file JSON" → tải `kade_events_YYYY-MM-DD.json` (Android: hộp chọn nơi lưu), SnackBar "Đã xuất N sự kiện" → xóa hết sự kiện → "Nhập file JSON" chọn file → dialog "Nhập N sự kiện từ file?" → Nhập → đủ lại, Sắp tới/lịch tháng hiện lại không cần F5; chọn file JSON khác → "File không đúng định dạng Kade…"; hủy chọn file → không gì xảy ra | ✅ 2026-09-10 | ⬜ |

## Phase 2 — Sync
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 2.1 | Đăng nhập. Web: nút Google "Tiếp tục với Google" (GIS vẽ) → popup chọn tài khoản → tên + email. Android: nút "Đồng bộ với Google" → bottom sheet chọn tài khoản → tên + email | ✅ 2026-09-10 | ⬜ |
| 2.2 | Quyền Drive: web → bấm "Đồng bộ ngay" → popup consent "See, edit, create, and delete its own configuration data in your Google Drive" → Allow → "Đã cấp quyền Google Drive (thư mục riêng của app)". Android: có ngay sau đăng nhập | ✅ 2026-09-10 (token có scope drive.appdata, log GIS) | ⬜ |
| 2.3 | Mở lại app: Android email tự hiện (khôi phục im lặng), bấm "Đồng bộ ngay" không hỏi lại. Web F5: One Tap có thể hiện; quyền Drive về "Chưa cấp" là đúng thiết kế (D029) | ⬜ | ⬜ |
| 2.4 | Đăng xuất → về nút đăng nhập; dữ liệu local vẫn còn | ⬜ | ⬜ |
| 2.5 | Sync A → B: A tạo 2 sự kiện (1 âm, 1 dương) → "Đồng bộ ngay" → "Đã đồng bộ với Google Drive", dòng "Đồng bộ lần cuối: …". B (cùng tài khoản) → "Đồng bộ ngay" → "Đã đồng bộ, nhận 2 thay đổi từ Drive" → Sự kiện của tôi có 2, ô lịch/Sắp tới có nhãn | ⬜ | ⬜ |
| 2.6 | Xóa ở A → sync A → sync B → sự kiện mất ở B (không resurrect) | ⬜ | ⬜ |
| 2.7 | Sửa tên ở B → sync B → sync A → A thấy tên mới | ⬜ | ⬜ |
| 2.8 | Bấm "Đồng bộ ngay" khi không đổi gì → vẫn "Đã đồng bộ…", không lỗi | ⬜ | ⬜ |
| 2.9 | Drive → Manage apps → Kade có "hidden app data" (file không thấy trong My Drive — đúng, appDataFolder ẩn) | ⬜ | — |
| 2.10 | Tự sync (bước 13, D032): (a) Android: ngay sau đăng nhập, dòng "Đồng bộ lần cuối" có giờ mà không bấm gì; web: sau "Đồng bộ ngay" lần đầu của phiên. (b) Tạo/sửa/xóa 1 sự kiện (hoặc Nhập file JSON) → ~5 s sau mở Cài đặt: "Đồng bộ lần cuối" đổi; máy B "Đồng bộ ngay" → thấy thay đổi. Sửa liên tiếp 3 lần trong 5 s → chỉ 1 lần sync (giờ "lần cuối" đổi 1 lần). (c) Kill app rồi mở lại (Android, đã đăng nhập) → email hiện + "Đồng bộ lần cuối" cập nhật, không hỏi gì; web F5 → KHÔNG có popup Drive tự bật (One Tap nếu có là của Google), quyền Drive "Chưa cấp" tới khi bấm "Đồng bộ ngay". (d) Rời app (Home / tab khác) > 15 phút rồi quay lại → "Đồng bộ lần cuối" đổi; rời < 15 phút → không đổi. (e) Để app mở qua 0h, khóa/mở máy → "Hôm nay" ở Sắp tới và viền hôm nay ở lịch đúng ngày mới | ⬜ | ⬜ |
| 2.11 | Token hết hạn / bị thu hồi (web: > 1 h sau khi cấp quyền, hoặc gỡ quyền app tại myaccount.google.com → Bảo mật → Kết nối bên thứ ba → Kade): sửa 1 sự kiện → sau 5 s mục Đồng bộ hiện "Phiên Google hết hạn — bấm Đồng bộ ngay", KHÔNG có popup tự bật; bấm "Đồng bộ ngay" → popup consent → "Đã đồng bộ…", dòng lỗi biến mất. Android sau khi gỡ quyền: bấm "Đồng bộ ngay" → consent lại → OK (token hết hạn thường Android tự làm mới, không thấy gì) | ⬜ | ⬜ |
| 2.12 | "Xóa dữ liệu trên Drive" → dialog → Hủy (không đổi) → lại → Xóa → SnackBar "Đã xóa dữ liệu trên Drive và đăng xuất", mục về nút đăng nhập, Sự kiện của tôi vẫn còn đủ; Drive → Manage apps → Kade: hidden app data trống / 0 B (hoặc "Delete hidden app data" không còn gì); đăng nhập lại → tự sync → file tạo lại từ local, máy B "Đồng bộ ngay" vẫn thấy sự kiện | ⬜ | ⬜ |

## Phase 3 — Web release (session sau điền chi tiết theo plan §4.8)
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 3.1 | §4.8 đủ 6 mục: /2027/02 đúng + nghỉ bù từ Sheet; reload giữ tháng; tạo sự kiện âm → đóng tab → mở lại còn; đăng nhập Google → tạo sự kiện → trình duyệt khác cùng tài khoản thấy; xóa ở A → sync B → mất; Lighthouse PWA installable pass | ⬜ | — |
| 3.2 | Responsive: ≥1024 2 cột (lịch + panel phải hero hôm nay + Sắp tới); 600–1023 1 cột; <600 bottom nav | ⬜ | — |
| 3.3 | Phím: ← → đổi tháng, T về hôm nay, Esc đóng DayDetail; DayDetail là dialog ≥1024, full page <1024 | ⬜ | — |
| 3.4 | URL path (không `#`) nếu bước 14 chọn path strategy; F5 ở URL sâu không 404 trên hosting | ⬜ | — |
| 3.5 | Deploy: mở domain thật → đăng nhập Google được (origin đã thêm vào OAuth B.3) | ⬜ | — |

## Phase 4 — Android release (session sau điền chi tiết theo plan §5.7)
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 4.1 | Widget 2x2 + 4x2 đúng ngày; đổi giờ máy qua 0h → widget tự đổi không mở app; đổi giờ máy +30 ngày → vẫn đúng | — | ⬜ |
| 4.2 | Giỗ 15/7 âm nhắc trước 3 ngày → notification đúng ngày dương 08:00, tap mở đúng DayDetail; xin quyền thông báo khi bật nhắc (Android 13+) | — | ⬜ |
| 4.3 | Sync 2 chiều với web (như 2.5–2.7) | ⬜ | ⬜ |
| 4.4 | Bản release ký keystore thật đăng nhập Google được (SHA-1 release đã thêm OAuth) | — | ⬜ |
| 4.5 | Dark mode app + widget không vỡ | ⬜ | ⬜ |

## Lỗi hay gặp
| Triệu chứng | Nguyên nhân / xử lý |
|---|---|
| Web: popup trắng, console `origin_mismatch` | Thiếu origin `http://localhost:5001` (hoặc domain deploy) ở OAuth client web (setup-google B.3) |
| "access blocked" / app chưa verify | Tài khoản không có trong Test users (B.2) |
| Android: `clientConfigurationError` hoặc `canceled` ngay sau chọn tài khoản | SHA-1 / package sai (E002): client Android phải là `vn.kade.kade` + SHA-1 của keystore đang ký |
| `serverClientId must be provided` | Thiếu `KADE_WEB_CLIENT_ID` trong dart_defines.json / quên `--dart-define-from-file` |
| "Phiên Google hết hạn — bấm Đồng bộ ngay" | Bình thường trên web sau > 1 h (token GIS hết hạn) hoặc sau khi gỡ quyền app: sync nền không được phép popup → bấm "Đồng bộ ngay" (có popup) là xong (D032) |
| "Đồng bộ không thành công (Drive 401: …)" | Token mới xin vẫn bị từ chối → thường do gỡ quyền app + cache; Đăng xuất rồi đăng nhập lại; còn lỗi → báo agent kèm log |
| Sửa sự kiện mà "Đồng bộ lần cuối" không đổi sau 5 s | Chưa đăng nhập / web chưa bấm "Đồng bộ ngay" trong phiên này (chưa có token) → mục Đồng bộ hiện "Chưa cấp quyền Google Drive" |
| "Drive 403 … Drive API has not been used" | Chưa Enable Drive API (B.1) |
| "File trên Drive không đọc được" | Drive → Manage apps → Kade → Delete hidden app data → sync lại |
| Nút Google (GIS) không hiện trên web | Client ID sai / console báo lỗi GIS → báo agent kèm log |
| Chạy lệnh báo "language version 3.12 too high" / "pubspec.yaml in packages\*" | Terminal đang dùng Flutter cũ (E008) → dùng bản 3.44.5 |

## Ghi lỗi
Format mỗi dòng: `[<phase>.<mục>] [web|android] <mô tả ngắn> — <dòng lỗi đỏ / log console>`
(dán vào chat cho agent; token/ID trong log thì che bớt)

- (chưa có)
