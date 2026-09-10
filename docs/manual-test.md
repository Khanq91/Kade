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

## Phase 3 — Web release
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 3.1 | §4.8 đủ 6 mục: (1) `/#/2027/02` đúng + nghỉ bù từ Sheet (như 1.1, 1.6); (2) F5 giữ tháng; (3) tạo sự kiện âm → đóng tab → mở lại còn (IndexedDB); (4) đăng nhập Google → tạo sự kiện → trình duyệt khác cùng tài khoản "Đồng bộ ngay" → thấy (2.5); (5) xóa ở A → sync B → mất (2.6); (6) Lighthouse (Chrome DevTools → Lighthouse → Progressive Web App / "Installable") pass trên bản deploy HTTPS (bước 15); bản `flutter run` localhost không có service worker → bỏ qua mục này ở localhost | ⬜ | — |
| 3.2 | Responsive (kéo cửa sổ Chrome): ≥ 1024 px → rail trái + lịch bên trái + panel phải: hero "hôm nay" (thứ, số ngày to, "Tháng M năm YYYY", âm lịch + can chi năm, ngày can chi, chip Ngày nghỉ, ≤ 3 sự kiện) + "Sắp tới" gọn (không chip); 600–1023 → rail trái, lịch trên, Sắp tới gọn dưới, không hero; < 600 → bottom nav 4 tab, chỉ lịch. Tab "Sắp tới" riêng vẫn có 4 chip lớp. Tap hero → chi tiết hôm nay | ⬜ | — |
| 3.3 | Phím (click vào lịch trước để có focus): ← → đổi tháng, T về tháng hôm nay; ≥ 1024: tap ô → DayDetail là dialog giữa màn (nút ✕ "Đóng", ◀ ▶ vẫn trong dialog, Esc hoặc click nền tối đóng); < 1024: trang riêng, Esc = Quay lại. F5 khi đang ở `/#/d/2027-02-06` trên màn rộng → trang riêng (không dialog) — đúng thiết kế D033 | ⬜ | — |
| 3.4 | URL: giữ dạng hash `/#/2027/02` (D033, không path strategy) — F5 ở URL sâu (`/#/d/2027-02-06`, `/#/settings`) không 404 cả localhost lẫn GitHub Pages. "Tháng âm" → chọn tháng → URL có `?lunar=1`, nút "Tháng âm" tô nền, ◀ ▶ nhảy theo tháng âm (từ 2/2027 Giêng → ▶ = 3/2027 Hai, ◀ = 1/2027 Chạp); "Hôm nay" hoặc chọn tháng dương → hết `?lunar=1`. Lần đầu mở web: banner "Dữ liệu lưu trên trình duyệt này…" → "Đã hiểu" ẩn hẳn (F5 không hiện lại); "Bật đồng bộ" → Cài đặt. Manifest: DevTools → Application → Manifest: name "Kade — Lịch âm dương", theme màu đỏ | ⬜ | — |
| 3.5 | Deploy (sau khi làm `setup-google.md` phần C): Actions → deploy-web xanh; mở `https://khanq91.github.io/Kade/` → lịch tháng hiện tại; F5 tại `/#/d/2027-02-06` và `/#/settings` không 404; Cài đặt → "Kiểm tra cập nhật" → "Lịch nghỉ đã là mới nhất" (nếu "Chưa cấu hình KADE_CONFIG_URL" → secret C.2 thiếu); nút Google → đăng nhập được (origin C.3) → "Đồng bộ ngay" → "Đã đồng bộ…"; Lighthouse PWA installable (3.1 mục 6); icon cài đặt ⊕ trên thanh địa chỉ → cài → mở dạng cửa sổ riêng (standalone) tên "Kade" | ⬜ | — |

## Phase 4 — Android release (session sau điền chi tiết theo plan §5.7)
| # | Kiểm tra | Web | Android |
|---|---|---|---|
| 4.1 | Widget (bước 17, D036). (a) Cài APK, mở app 1 lần (đẩy `days_json`). Nhấn giữ màn hình chính → Widget → Kade → có 2 mục "Kade · Hôm nay" (2x2) và "Kade · Hôm nay + Sắp tới" (4x2), preview hiện chữ mẫu. Thêm cả 2. (b) 2x2: thứ, số ngày to, "Tháng M", "d/m âm", dòng cuối = can chi ngày (hoặc tên sự kiện hôm nay, màu theo lớp); ngày nghỉ → số ngày đỏ. 4x2: thêm cột "Sắp tới" 3 dòng "• tên · N ng" (so với "Sắp tới" trong app, chỉ lớp đang bật). (c) Tap widget → app mở DayDetail hôm nay (app đang tắt hoặc đang chạy nền đều được). (d) Tạo sự kiện cá nhân ngày mai → về màn hình chính → 4x2 hiện "• tên · 1 ng" trong vài giây (không cần mở lại app). (e) Đổi giờ máy qua 0h (Cài đặt → Ngày giờ, tắt tự động, đặt 23:59 rồi chờ) → widget đổi sang ngày mới trong vài phút mà không mở app (AlarmManager inexact; chậm nhất 30 phút do `updatePeriodMillis`). (f) Đổi giờ máy +30 ngày → widget vẫn đúng ngày đó (trong 35 ngày); +40 ngày → "Mở Kade để cập nhật" (ngoài dữ liệu) → mở app → đúng lại. (g) Khởi động lại máy → widget vẫn đúng và vẫn đổi qua ngày. Trả giờ máy về tự động sau khi test | — | ⬜ |
| 4.2 | Nhắc nhở (bước 16, D035). (a) Mở app lần đầu: KHÔNG có hộp xin quyền thông báo. (b) Sự kiện của tôi → + → "Giỗ ông", Âm lịch 15/7, "Nhắc trước" = "3 ngày trước" → Lưu → Android 13+ hiện hộp xin quyền thông báo → Cho phép. (c) Kiểm tra nhanh không chờ 3 ngày: đổi giờ máy (Cài đặt hệ thống → Ngày giờ, tắt tự động) sang 07:59 của ngày (15/7 âm − 3) rồi chờ qua 08:00 → thông báo "Giỗ ông — Còn 3 ngày · Thứ …, dd/mm/yyyy (15/7 ÂL)"; chạm → mở đúng DayDetail ngày 15/7 âm (URL `/d/<ngày dương>`). Với app đang tắt hẳn: chạm thông báo → app mở thẳng DayDetail. (d) Cài đặt → Nhắc nhở → "Nhắc lễ trước" mặc định "7 ngày trước"; chọn "Không nhắc" rồi chọn lại "3 ngày trước" → hộp xin quyền (nếu chưa cho); đổi giờ máy tới 08:00 của (Tết − 3 ngày) → thông báo "Tết Nguyên đán — Còn 3 ngày…" (chỉ 1 thông báo cho Tết 3 ngày; Giao thừa có thông báo riêng). (e) Từ chối quyền → SnackBar "Chưa được phép hiện thông báo…"; bật lại trong Cài đặt hệ thống → Ứng dụng → Kade → Thông báo. (f) Khởi động lại máy → thông báo vẫn tới (receiver BOOT_COMPLETED). (g) Kênh thông báo "Nhắc sự kiện" hiện trong Cài đặt hệ thống → Kade → Thông báo. Trả giờ máy về tự động sau khi test | — | ⬜ |
| 4.3 | Sync 2 chiều với web (như 2.5–2.7) | ⬜ | ⬜ |
| 4.4 | Release (bước 18, sau `setup-google.md` phần D): (a) `flutter build apk --release --dart-define-from-file=../../dart_defines.json` — log KHÔNG có "Signing with debug keys"; `keytool -printcert -jarfile …app-release.apk` → SHA1 = keystore D.3. (b) Gỡ bản debug, cài `app-release.apk` → Cài đặt → "Đồng bộ với Google" → đăng nhập được, "Đã cấp quyền Google Drive", "Đồng bộ ngay" OK (cần OAuth client "Kade Android release"). (c) Cài từ Play Internal testing → đăng nhập được (cần OAuth client "Kade Android play" với SHA-1 App signing key; thiếu → `clientConfigurationError`). (d) Widget + thông báo trên bản release như 4.1/4.2. (e) `https://khanq91.github.io/Kade/privacy.html` mở được (sau bước 15) | — | ⬜ |
| 4.5 | Dark mode: bật Dark theme hệ thống → widget nền tối chữ sáng (values-night), số ngày nghỉ đỏ nhạt; app Flutter hiện vẫn theme sáng (chưa có `darkTheme`, ghi nhận nếu user muốn); web không áp dụng | — | ⬜ |

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
| Phím ← → T không ăn trên web | Focus đang ở ngoài lịch (thanh địa chỉ, tab khác) → click vào lưới lịch rồi bấm lại; tab Đổi ngày không có phím tắt (D033) |
| Màn ≥ 1024 mà DayDetail vẫn trang riêng | Mở thẳng URL `/#/d/…` (F5) → đúng thiết kế; mở từ ô lịch / Sắp tới / hero mới là dialog |
| Android: không có thông báo đúng 08:00 | Chế độ `inexactAllowWhileIdle` → hệ thống có thể trễ vài phút (Doze); pin tiết kiệm của hãng (Xiaomi/Oppo…) chặn → cho Kade chạy nền không giới hạn. Quyền thông báo phải bật (Cài đặt hệ thống → Kade → Thông báo) |
| Android: đổi giờ máy mà thông báo không tới | Thông báo đã đặt theo mốc tuyệt đối trước khi đổi giờ; mở app lại (resume → đặt lại) rồi mới đổi giờ tới mốc mới; hoặc tạo sự kiện SAU khi đổi giờ |
| Icon thông báo là khối trắng/xám trên status bar | Đang dùng icon launcher (chưa có icon đơn sắc); nội dung trong thanh thông báo vẫn đúng — đổi khi có logo |
| Widget hiện "Mở Kade để cập nhật" | Chưa mở app lần nào sau khi cài, hoặc giờ máy ngoài 35 ngày dữ liệu → mở app (đẩy lại) |
| Widget không đổi ngày sau 0h | AlarmManager inexact có thể trễ vài phút; tối đa 30 phút (`updatePeriodMillis`). Máy tiết kiệm pin gắt → cho Kade chạy nền; sau khi cài lại app phải mở app 1 lần để hẹn lại |
| Tap widget không mở app | Launcher chặn "background activity start" (Android 14+) — plugin đã set MODE_BACKGROUND_ACTIVITY_START_ALLOWED; nếu vẫn kẹt, báo agent kèm model máy |
| "Drive 403 … Drive API has not been used" | Chưa Enable Drive API (B.1) |
| "File trên Drive không đọc được" | Drive → Manage apps → Kade → Delete hidden app data → sync lại |
| Nút Google (GIS) không hiện trên web | Client ID sai / console báo lỗi GIS → báo agent kèm log |
| Chạy lệnh báo "language version 3.12 too high" / "pubspec.yaml in packages\*" | Terminal đang dùng Flutter cũ (E008) → dùng bản 3.44.5 |

## Ghi lỗi
Format mỗi dòng: `[<phase>.<mục>] [web|android] <mô tả ngắn> — <dòng lỗi đỏ / log console>`
(dán vào chat cho agent; token/ID trong log thì che bớt)

- (chưa có)
