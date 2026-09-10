# DECISIONS — Kade

Append-only. Đọc hết trước khi hỏi user bất cứ câu "nên chọn A hay B" nào.
Format và quy tắc ghi: xem `AGENTS.md` §4.

## 2026-09-09 — D001 — Tên app: Kade
- Bởi: user
- Quyết định: app tên "Kade". Package Flutter `apps/kade`, Android applicationId do user chốt khi tạo project (xem PROGRESS "Cần user làm").
- Lý do: convention đặt tên của user.
- Hệ quả: không.

## 2026-09-09 — D002 — Target MVP: web + Android, iOS lùi phase sau
- Bởi: user
- Quyết định: MVP build web (PWA) và Android. iOS (app + WidgetKit) là Phase 5.
- Lý do: ưu tiên nhanh; iOS widget tốn công hơn.
- Hệ quả: `platform/` vẫn tách interface để sau thêm iOS không phải sửa UI. Không viết code iOS ở MVP.

## 2026-09-09 — D003 — Stack
- Bởi: user (theo đề xuất)
- Quyết định: Riverpod (không codegen), go_router, Hive CE, freezed + json_serializable, home_widget, flutter_local_notifications + timezone, google_sign_in + googleapis.
- Lý do: chạy được cả web lẫn Android không cần native setup thêm; Hive CE có IndexedDB.
- Hệ quả: không dùng Isar/Drift/sqflite.

## 2026-09-09 — D004 — Export/Import JSON trong MVP
- Bởi: user
- Quyết định: có Export/Import file JSON, format = `SyncEnvelope` (plan §2.5), dùng chung với file sync trên Drive.
- Lý do: user web không đăng nhập Google vẫn có cách giữ dữ liệu.
- Hệ quả: 1 serializer cho cả 2 tính năng.

## 2026-09-09 — D005 — Quy tắc tháng nhuận mặc định: firstMonth
- Bởi: user
- Quyết định: sự kiện âm lịch lặp hàng năm rơi vào năm có tháng nhuận trùng tháng → mặc định lấy tháng chính (tháng đầu). User đổi được từng sự kiện (`LeapMonthRule`: firstMonth | secondMonth | both).
- Lý do: tục lệ phổ biến.
- Hệ quả: không.

## 2026-09-09 — D006 — Ngày lễ quốc tế: ~10 ngày
- Bởi: user
- Quyết định: danh sách ở plan §2.2. Ngày của Mẹ/Cha (rule "CN thứ N của tháng") CHƯA chốt — agent hỏi user khi làm Phase 1 bước 4, hoặc bỏ nếu user không trả lời.
- Lý do: tránh nhồi.
- Hệ quả: `Event` có thể cần field `nthWeekday` nếu giữ 2 ngày này.

## 2026-09-09 — D007 — Sync qua Google Drive appDataFolder, trong MVP
- Bởi: user (hỏi Google Sheets trước, chọn appDataFolder theo đề xuất)
- Quyết định: sync sự kiện cá nhân = 1 file `kade_events.json` trong appDataFolder của user, scope `drive.appdata`. Không dùng Sheets, không backend riêng. Merge theo `updatedAt`, last-write-wins, tombstone `deletedAt`.
- Lý do: scope non-sensitive không cần verify; blob JSON = format Export/Import; không dính rate limit Sheets.
- Hệ quả: `UserEvent` có `deletedAt`; xóa = soft delete; purge tombstone > 90 ngày sau khi đã sync.

## 2026-09-09 — D008 — Nghỉ bù theo năm: remote config từ Google Sheet qua Apps Script
- Bởi: user
- Quyết định: user sở hữu 1 Sheet tab `overrides`; Apps Script `doGet` trả JSON; app fetch ≤ 1 lần/24h, cache Hive, fallback `assets/overrides.json`. Setup: `docs/setup-google.md`.
- Lý do: sửa nghỉ bù không cần release.
- Hệ quả: nếu CORS từ Flutter web lỗi (verify Phase 1 bước 5) → đổi nguồn sang GitHub raw JSON, Sheet chỉ là nơi soạn. Ghi DECISIONS mới khi đó.

## 2026-09-09 — D009 — Engine: port `docs/reference/amlich-aa98.js` (Hồ Ngọc Đức), múi giờ cố định +7
- Bởi: user (theo đề xuất)
- Quyết định: `lunar_core` port 1:1 từ reference, giữ tên hàm để dễ đối chiếu. Fixture `tet_1900_2100.json` sinh từ chính reference → test port khớp reference 100%.
- Lý do: thuật toán chuẩn de facto của lịch VN.
- Hệ quả: **License reference là "personal, non-commercial use"** (xem header file). Nếu Kade sẽ thu tiền / có quảng cáo → cần user quyết định: (a) xin phép tác giả, (b) viết lại từ Meeus độc lập, (c) giữ non-commercial. → MỞ, hỏi user trước Phase 3 release. Fixture là output của thuật toán, không phải nguồn độc lập; sanity check ngoài: `docs/reference/README.md`.

## 2026-09-09 — D010 — Memory cho agent: `.memory/` 3 file
- Bởi: user
- Quyết định: mọi agent đọc `.memory/PROGRESS.md`, `DECISIONS.md`, `ERRORS.md` đầu session và ghi theo quy tắc `AGENTS.md` §4.
- Lý do: nhiều agent (Claude Code, Codex) thay phiên làm cùng repo.
- Hệ quả: `CLAUDE.md` chỉ import `AGENTS.md`.

## 2026-09-10 — D011 — Root pubspec = workspace root; scaffold `flutter create` ở root giữ nguyên chờ user
- Bởi: agent
- Quyết định: `pubspec.yaml` root đổi từ app Flutter scaffold (commit "PROJECT UPLOAD") thành workspace root: `workspace: [packages/*]`; `apps/*` để comment, bật khi có `apps/kade`. Các file scaffold còn lại ở root (`lib/main.dart`, `test/widget_test.dart`, `android/`, `web/`, `.metadata`, `README.md`, `analysis_options.yaml`) KHÔNG xóa, KHÔNG move.
- Lý do: plan §1 đặt app ở `apps/kade`; user dặn bước 1 chưa tạo `apps/kade`; xóa hay move scaffold (kèm `android/` applicationId `com.kade.kade`) là việc user quyết.
- Hệ quả: `dart analyze` / `dart test` chạy ở root sẽ lỗi vì `lib/main.dart` import flutter mà root không có dep → chỉ chạy trong từng package (`cd packages/lunar_core`). Việc chờ user ghi ở PROGRESS "Cần user làm".

## 2026-09-10 — D012 — API `lunar_core` bước 1
- Bởi: agent
- Quyết định: `lib/src/amlich.dart` giữ nguyên tên hàm JS kể cả viết hoa (`NewMoon`, `SunLongitude`, `INT`) với `ignore_for_file: non_constant_identifier_names`; mảng JS → record cùng thứ tự. API public (`lib/lunar_core.dart`): `LunarDate{day, month, year, isLeapMonth}`; `solarToLunar(DateTime, {double timeZone = 7})` chỉ dùng y/m/d của input; `lunarToSolar(LunarDate, {timeZone = 7})` trả `DateTime.utc` 0h, hoặc `null` nếu ngày âm không tồn tại (kiểm bằng round-trip `solarToLunar(kết quả) == input`, thay cho `[0,0,0]` của JS).
- Lý do: tên 1:1 để đối chiếu từng hàm; `DateTime.utc` tránh lệch DST/local; `null` để UI converter (Phase 1) dùng thẳng, không cần check `[0,0,0]`.
- Hệ quả: app khi so ngày phải so theo y/m/d hoặc dùng `DateTime.utc`, không so trực tiếp với `DateTime.now()` local. `timeZone` kiểu `double` (theo reference), app luôn dùng mặc định 7.

## 2026-09-10 — D013 — (MỞ) Bug "ngày 0" trong reference: giữ 1:1 hay sửa
- Bởi: agent (chờ user chốt)
- Quyết định: TẠM giữ port 1:1 theo D009 → port tái hiện đúng quirk của reference. Test `reference_quirks_test.dart` ghim 2 ngày này và sẽ đỏ khi sửa. Đề xuất SỬA: thêm 1 dòng sau fallback hiện có trong `convertSolar2Lunar` — `if (monthStart > dayNumber) monthStart = getNewMoonDay(k - 1, timeZone);` — ở CẢ `docs/reference/amlich-aa98.js` và port, rồi `node tools/gen_fixture.js` sinh lại fixture, sửa README + xóa quirk test. Cần chốt trước Phase 0 bước 3 (bảng const sẽ đóng băng kết quả).
- Lý do: reference trả `0/4/2054` cho 2054-05-07 và `0/3/2062` cho 2062-04-09 (JS gốc chạy node cho cùng kết quả — chi tiết ERRORS E005). Theo chính sóc mà thuật toán tính ra, đúng phải là 30/3/2054 và 30/2/2062. Sửa = lệch D009 và đổi reference (README nói "không nên") → không tự quyết.
- Hệ quả: nếu giữ, app hiện "ngày 0" ở 2 ngày trên. Nếu sửa: fixture 2054 (tháng 3: 29→30 ngày, tháng 4 start 05-07→05-08, 30→29) và 2062 (tháng 2: 29→30, tháng 3 start 04-09→04-10, 30→29) đổi.

## 2026-09-10 — D014 — Chốt D013: SỬA bug "ngày 0" trong reference + port, sinh lại fixture
- Bởi: user ("ok theo đề xuất")
- Quyết định: thêm 1 lần lùi sóc trong `convertSolar2Lunar` (`if (monthStart > dayNumber) monthStart = getNewMoonDay(k-1, timeZone)`) ở cả `docs/reference/amlich-aa98.js` (đánh dấu `Kade patch`) và `packages/lunar_core/lib/src/amlich.dart`. Fixture `tet_1900_2100.json` sinh lại bằng `node tools/gen_fixture.js` từ JS đã patch. README reference ghi mục "Patch". Xóa `reference_quirks_test.dart`, thay bằng `reference_patch_test.dart` (2054-05-07 = 30/3/2054, 2062-04-09 = 30/2/2062, mọi ngày day ∈ 1..30).
- Lý do: ngày âm 0 là sai hiển nhiên; patch chỉ mở rộng fallback sẵn có, không đổi công thức thiên văn.
- Hệ quả: D009 "port 1:1" nay hiểu là 1:1 với reference ĐÃ PATCH (1 chỗ, có đánh dấu). Fixture 2054 (tháng 3: 30 ngày, tháng 4 start 05-08) và 2062 (tháng 2: 30 ngày, tháng 3 start 04-10) đổi; các năm khác giữ nguyên.

## 2026-09-10 — D015 — Scaffold Flutter ở root là project của user → chuyển vào `apps/kade`
- Bởi: user (xác nhận "project t tự tạo trong Android Studio"), agent thực hiện
- Quyết định: `git mv` toàn bộ scaffold (`lib/`, `test/`, `android/`, `web/`, `.metadata`, `README.md`) vào `apps/kade/`; khôi phục `apps/kade/pubspec.yaml` từ commit `5f8f34a` + thêm `resolution: workspace`; copy `analysis_options.yaml`; root `pubspec.yaml` bật `apps/*`. Không đổi applicationId (`com.kade.kade`) lúc này — user đã chốt `vn.kade.kade`, làm ở Phase 2 bước 10 như PROGRESS ghi.
- Lý do: plan §1 đặt app ở `apps/kade`; root không thể vừa là workspace root vừa là app Flutter; giữ `android/`, `web/` do user tạo thay vì `flutter create` lại.
- Hệ quả: Sửa D011 (scaffold không còn ở root). Lệnh `dart pub get` ở root vẫn chạy được với app Flutter trong workspace (Dart của Flutter SDK), `flutter pub get` cũng được. Verify: `flutter analyze` + `flutter test` trong `apps/kade` pass.

## 2026-09-10 — D016 — Quy ước bước 2: can chi, tiết khí, hoàng đạo, DayInfo (chờ user đối chiếu)
- Bởi: agent (giá trị cụ thể chờ user xác nhận bằng lịch vạn niên)
- Quyết định: (1) Can chi theo công thức Hồ Ngọc Đức bản web: năm `(y+6)%10, (y+8)%12`; tháng `(y*12+m+3)%10, (m+1)%12`, tháng nhuận cùng can chi tháng chính (không gắn "(nhuận)" vào chuỗi, UI tự thêm); ngày `(jd+9)%10, (jd+1)%12`; giờ `((jd-1)*2 + chiGiờ)%10`. (2) Tiết khí: 24 mốc 15°, tính `SunLongitude` tại 0h địa phương (+7); `tietKhiOf(d)` trả tên tiết khí mới nếu chỉ số ở 0h ngày d+1 khác 0h ngày d (Mặt Trời vượt mốc trong ngày d → ngày d là ngày đầu tiết). Danh sách tên bắt đầu Xuân phân. (3) Giờ hoàng đạo: bảng 12 dòng theo chi ngày (GIO_HD của HND), định dạng "Tý (23-1)". (4) Ngày hoàng đạo: bảng 12×12 chi tháng × chi ngày, sinh từ vòng 12 thần với Thanh Long khởi Tý ở tháng Dần, +2 chi mỗi tháng; 6 thần hoàng đạo: Thanh Long, Minh Đường, Kim Quỹ, Kim Đường, Ngọc Đường, Tư Mệnh. Có `thanOfDay()` trả tên thần. (5) `DayInfo` immutable, `solar` chuẩn hóa về `DateTime.utc` y/m/d.
- Lý do: các công thức là chuẩn phổ biến của lịch VN; bảng ngày hoàng đạo viết tường minh để user dò từng dòng, có test kiểm bảng == vòng 12 thần.
- Hệ quả: test hiện tại chỉ kiểm cấu trúc (chu kỳ 60, 24 tiết khí/năm, 6 giờ HĐ/ngày...). Sau khi user xác nhận output `example/day_info_example.dart` → thêm test giá trị cố định, commit "phase0-step2: ...". Nếu user báo lệch → sửa bảng/công thức, ghi DECISIONS mới.

## 2026-09-10 — D017 — User xác nhận output bước 2 → test giá trị cố định
- Bởi: user ("ổn thì tiếp tục" sau khi tự chạy `example/day_info_example.dart` và xem 10 ngày + 24 tiết khí 2025)
- Quyết định: chốt công thức/bảng của D016. Toàn bộ output (10 ngày: âm lịch, can chi năm/tháng/ngày/giờ Tý, tiết khí, 6 giờ hoàng đạo, ngày hoàng đạo + thần; 24 ngày tiết khí 2025) thành test cố định `test/day_info_fixed_test.dart`.
- Lý do: theo prompt bước 2, chỉ chốt fixture sau khi user đối chiếu lịch vạn niên.
- Hệ quả: đổi bất kỳ công thức/bảng nào ở can_chi / tiet_khi / hoang_dao → test này đỏ → cần DECISIONS mới + user xác nhận lại.

## 2026-09-10 — D018 — Runtime tra bảng const 1900–2100 khi múi giờ 7, ngoài đó tính trực tiếp
- Bởi: agent (theo đề xuất trong prompt bước 3)
- Quyết định: `tools/gen_lunar_table.dart` (chạy ở root: `dart run tools/gen_lunar_table.dart && dart format packages/lunar_core`) sinh `packages/lunar_core/lib/src/table_1900_2100.dart`: 201 entry `(JD mùng 1 Tết, tháng nhuận | 0, bitmask 13 bit tháng 30 ngày)`. `solarToLunar`/`lunarToSolar` public: nếu `timeZone == 7` và ngày/năm nằm trong bảng → tra bảng (`lib/src/lunar_table.dart`), ngược lại → `solarToLunarComputed`/`lunarToSolarComputed` (thuật toán, vẫn export). Root `pubspec.yaml` thêm `dev_dependencies: lunar_core: any` để script trong `tools/` import được và analyze sạch.
- Lý do: (1) kết quả cố định, không phụ thuộc `sin()` của VM / dart2js / wasm ở biên nửa đêm; (2) nhanh hơn nhiều cho MonthView/Upcoming quét nhiều ngày; (3) vẫn chạy được ngoài 1900–2100 và múi giờ khác nhờ fallback.
- Hệ quả: đổi thuật toán (amlich.dart) → phải chạy lại generator; `test/lunar_table_test.dart` so bảng == runtime cho mọi ngày 1900–2100 và mọi tổ hợp (năm, tháng, nhuận, ngày 1–30) nên quên sinh lại sẽ đỏ. Fixture test (`fixture_test.dart`) giờ đi qua đường bảng; đường tính trực tiếp được phủ bởi test bảng == runtime.

## 2026-09-10 — D019 — Chốt D006 + nội dung 3 danh sách sự kiện app (`calendar_data`)
- Bởi: user (D006: "giữ ngày mẹ/cha"); agent đề xuất danh sách
- Quyết định: (1) `Event` thêm `NthWeekday? nthWeekday` (thứ X lần thứ N trong tháng, chỉ lịch dương); Ngày của Mẹ = CN thứ 2 tháng 5, Ngày của Cha = CN thứ 3 tháng 6. (2) `vnHolidays` = ngày nghỉ cố định theo Bộ luật Lao động 2019 Điều 112: Tết Dương lịch 1/1, Tết Nguyên đán mùng 1–3 (durationDays 3 theo plan §2.2), Giỗ Tổ 10/3 âm, 30/4, 1/5, 2/9. Ngày nghỉ thêm theo năm (30 Tết, mùng 4–5, ngày thứ 2 Quốc khánh, nghỉ bù) đi qua YearOverride, không hardcode. (3) `international` đúng plan §2.2 trừ "Năm mới 1/1" gộp vào "Tết Dương lịch" (vnHoliday) để không hiện 2 dòng cùng ngày → 9 mục. (4) `vnMemorials` (22 mục, KHÔNG ảnh hưởng ngày nghỉ) là ĐỀ XUẤT, chờ user duyệt: dương 3/2, 27/2, 8/3, 26/3, 7/5, 19/5, 21/6, 28/6, 27/7, 19/8, 10/10, 13/10, 20/10, 20/11, 22/12; âm 15/1, 3/3, 15/4, 5/5, 15/7, 15/8, 23/12.
- Lý do: plan chỉ liệt kê danh sách quốc tế và vài ví dụ (30/4, 2/9, Tết, Giỗ Tổ, Trung Thu, 20/10); danh sách nghỉ là luật, danh sách kỷ niệm là lựa chọn biên tập → user quyết.
- Hệ quả: user thêm/bớt mục trong `packages/calendar_data/lib/src/events.dart` chỉ là sửa dữ liệu; test `events_test.dart` kiểm cấu trúc, `resolve_month_test.dart` dùng vài id cụ thể (thanh-lap-dang, thay-thuoc, ram-thang-gieng, doan-ngo) → đổi id thì sửa test.

## 2026-09-10 — D020 — API `calendar_data`: resolveMonth chỉ gộp sự kiện app; sự kiện âm chỉ tháng chính
- Bởi: agent
- Quyết định: `resolveMonth(year, month, {overrides, events})` → `Map<DateTime(utc 0h), DayEvents{date, appEvents, isOffDay}>`; `eventsOn(date)`; `isOffDay` đúng công thức plan §3.2 (`work` thắng, rồi `off`, rồi có vnHoliday). `DayEvents` ở đây KHÔNG có `userEvents` (UserEvent là model app dùng Hive/freezed, không thể nằm trong pure Dart package) — app gộp thêm ở bước 7. Sự kiện âm của app chỉ khớp tháng chính (`!isLeapMonth`), tương tự `firstMonth` của D005. Sự kiện nhiều ngày khớp theo "ngày bắt đầu = hôm nay − k" nên vắt qua tháng/năm vẫn đúng. `YearOverrides` parse chấp nhận `version` số thực (JS), bỏ qua ngày sai định dạng và key lạ (`_note`); ngày là `DateTime.utc`.
- Lý do: pure Dart, không phụ thuộc Flutter/Hive; giữ đúng công thức plan.
- Hệ quả: asset `assets/overrides.json` vẫn ở root repo (test đọc `../../assets/overrides.json`); khi làm bước 5/6 phải đưa vào `apps/kade` (Flutter chỉ bundle asset trong thư mục project) và cập nhật `docs/setup-google.md` nếu có nhắc đường dẫn.

## 2026-09-10 — D021 — Chốt danh sách sự kiện: thêm Giao thừa, giữ đủ 22 kỷ niệm, phân biệt bằng `kind` + `type`
- Bởi: user ("lấy thêm ngày trước 1/1 để đánh dấu giao thừa"; "lấy hết"; "cần phân biệt rõ lễ nào của âm, nào của dương")
- Quyết định: (1) `Event.offsetDays` (mặc định 0): ngày bắt đầu = ngày neo + offsetDays; sự kiện mới `giao-thua` (vnHoliday, âm, neo 1/1, offsetDays −1, 1 ngày) → luôn là 29 hoặc 30 tháng Chạp; `tet` giữ mùng 1–3. (2) `vnMemorials` giữ nguyên 22 mục đã đề xuất (D019). (3) Phân biệt hiển thị dựa trên 2 field có sẵn: `kind` (nghỉ / kỷ niệm / quốc tế) và `type` (âm / dương) — UI bước 6 phải hiện rõ: màu/badge khác cho `vnHoliday` vs `vnMemorial`, và ký hiệu âm/dương (vd. "ÂL"/"DL" hoặc icon) cạnh mỗi sự kiện. Gộp "Năm mới 1/1" vào "Tết Dương lịch" giữ nguyên (user không phản đối; là sự kiện dương).
- Lý do: theo yêu cầu user; Giao thừa không có ngày cố định (tháng Chạp 29/30 ngày) nên cần offset từ mùng 1.
- Hệ quả: `giao-thua` là vnHoliday → `isOffDay` true ngày trước Tết (thực tế lịch nghỉ Nhà nước luôn gồm ngày này). Test cố định: 05/02/2027, 30/01/2014.

## 2026-09-10 — D022 — Kiến trúc bước 5: remote config trong `apps/kade`
- Bởi: agent
- Quyết định: `lib/core/env.dart` đọc `KADE_CONFIG_URL`/`KADE_WEB_CLIENT_ID` bằng `String.fromEnvironment` (từ `--dart-define-from-file=../../dart_defines.json`); `lib/core/strings.dart` gom text UI; `lib/data/local/hive_boxes.dart` mở box `remote_config` (String) + `settings`; `lib/data/remote/remote_config.dart` = `RemoteConfigRepository` (loadLocal: cache → asset → rỗng; fetch: GET timeout 5s, so `version` với cache, lưu `json|version|fetchedAt`, chỉ tự fetch khi quá 24h, `force` bỏ qua; nhận HTML → báo lỗi deploy "Anyone"); `remote_config_provider.dart` = `AsyncNotifier` + `remoteConfigRepositoryProvider` override trong `main()` (DI qua Riverpod override, test override bằng MockClient + Hive temp). Tự fetch nền lúc start nếu quá 24h (plan §3.1). `SettingsScreen` là home tạm (bước 6 thay bằng MonthView) với nút "Kiểm tra cập nhật" + SnackBar kết quả. Asset `apps/kade/assets/overrides.json` khai báo trong pubspec.
- Lý do: pure Dart repo test được không cần Flutter binding; provider override là cách DI không codegen của Riverpod; `AsyncNotifier` cho phép UI `when(loading/error/data)`.
- Hệ quả: MonthView (bước 6) `ref.watch(remoteConfigProvider)` → lấy `overrides` truyền vào `resolveMonth`, cache tháng invalidate khi state đổi. Chưa có nút trong UI để xóa cache (không cần).
