# Kế hoạch implement UI mới cho Kade

Nguồn: `plan/new-ui/Kade Android app design/` (file `.dc.html` + screenshot).
Mục tiêu: thay **giao diện** (theme, màu, font, bo góc, bố cục card) sang
phong cách pastel mới, **không đụng route, provider, model, business logic**
(tính âm lịch, đồng bộ Google, nhắc nhở, backup JSON, sự kiện...).

Quyết định đã chốt với người dùng:
- Font: dùng `Baloo 2` (số to / tiêu đề) + `Be Vietnam Pro` (còn lại), theo
  đúng thiết kế — ưu tiên bám sát design vì app chủ yếu dùng tiếng Việt.
- Bộ màu mặc định: **Hồng phấn** (`hong`).
- Có build tính năng đổi theme: 6 bộ màu pastel × Sáng/Tối, trong Cài đặt.
- Mức bám design: theo tinh thần (màu/bo góc/bố cục/font) chứ không cần
  giống tuyệt đối từng px — ưu tiên Flutter widget chuẩn, dễ bảo trì.
- Phạm vi: toàn bộ 8 màn hình, chia theo phase. **Widget màn hình chính
  (native Android, `android/app/.../widget_*.xml`) là 1 phase riêng, làm
  sau cùng.**

---

## 0. Việc KHÔNG được đụng

- Toàn bộ `packages/lunar_core`, `packages/calendar_data` — không sửa.
- `lib/data/**` (providers, models, repository, sync, reminders,
  widget_updater...) — không sửa logic, chỉ **thêm** provider mới cho
  theme/density nếu cần (xem §2).
- `lib/core/router.dart`, `core/breakpoints.dart`, `core/lunar_utils.dart`,
  `core/formats.dart` — giữ nguyên 100%.
- `lib/core/strings.dart` — chỉ **thêm** string mới nếu màn hình mới cần
  (ví dụ nhãn "Giao diện", tên 6 bộ màu), không sửa string cũ.
- Tên class public, method public đang được test hoặc route gọi tới
  (`MonthCalendar`, `DayTile`, `UpcomingList`, `AppShell`...) — giữ nguyên
  tên & constructor signature để không vỡ chỗ gọi tới, kể cả khi rewrite
  phần `build()`.
- File test hiện có trong `apps/kade/test/` — chạy lại sau mỗi phase, không
  sửa test để "cho qua"; nếu test cần đổi vì đổi UI thật sự (ví dụ tìm text
  theo `find.text('Hôm nay')`) thì sửa test cho khớp DOM mới, không đổi ý
  nghĩa test.

## 1. Việc ĐƯỢC đụng (đúng phạm vi UI)

- `main.dart`: đổi `ThemeData(colorSchemeSeed: Colors.red, ...)` thành
  `ThemeData` build từ theme tùy chỉnh (xem §2).
- Toàn bộ file trong `lib/features/**` (phần `build()` — cấu trúc widget,
  không đụng phần đọc provider/logic điều hướng trong cùng file).
- `lib/core/event_style.dart`: giữ nguyên **tên hàm/class public**
  (`kindColor`, `userEventColors`, `layerColor`, `EventTag`,
  `UserEventTag`, `TypeTag`) vì nhiều màn hình import, nhưng đổi **giá trị
  màu bên trong** để khớp bảng `KIND` / `USER` trong `themes.js` (mục
  đích: giữ đúng API, đổi visual).
- Thêm mới: `lib/core/theme/` (theme tokens, `ThemeExtension`, theme
  provider), `lib/features/settings/theme_screen.dart` (màn "Giao diện"),
  và các widget dùng chung mới nếu cần (card bo góc, nút pill...).
- `pubspec.yaml`: thêm `google_fonts` (hoặc tự bundle 2 font — xem §2.2).

## 2. Nền tảng thiết kế (Phase 0 — bắt buộc làm trước)

Đây là phần nền, mọi phase UI sau đều dựa vào đây. Không có màn hình nào
tự nó "xong" nếu thiếu phần này.

### 2.1. Theme tokens

Tạo `lib/core/theme/kade_palette.dart`: port `themes.js` sang Dart —
6 `KadePalette` (id, tên hiển thị, light/dark) với đúng các field:
`bg, sf, sf2, tx, mu, ac, acT, ac1, ac2, on, b, bT, b1, off, offT, sun,
line, sh`. Đây là 1-1 mapping từ file design, không tự sáng tác thêm màu.

Tạo `lib/core/theme/kade_theme_extension.dart`: một
`ThemeExtension<KadeColors>` bọc các field trên, để mọi widget lấy màu qua
`Theme.of(context).extension<KadeColors>()!` — thay cho việc đọc trực tiếp
`ColorScheme` mặc định của Material 3 ở những chỗ cần đúng màu pastel
(surface, accent, off-day...). `ColorScheme` mặc định của Flutter vẫn giữ
để các widget Material chuẩn (Scaffold, AppBar...) không vỡ, nhưng
`colorSchemeSeed: Colors.red` sẽ đổi seed theo `ac` của palette đang chọn.

Tạo `lib/core/theme/kade_theme.dart`: hàm
`ThemeData buildKadeTheme(KadePalette palette, {required bool dark})` build
`ThemeData` đầy đủ (colorScheme, textTheme dùng 2 font, extension ở trên,
bo góc mặc định cho Card/Button theo phong cách thiết kế mới — số cụ thể
lấy từ CSS trong `.dc.html`, ví dụ card `border-radius: 22–28px`, nút pill
`border-radius: 999px`).

### 2.2. Font

Người dùng chốt: bám design (Baloo 2 + Be Vietnam Pro), làm theo cách nào
tốt nhất — chọn **bundle font tĩnh vào `assets/fonts/`** (khai báo trong
`pubspec.yaml` bằng `fonts:`) thay vì `google_fonts` tải runtime. Lý do:
đây là app lịch dùng offline nhiều (không có mạng vẫn phải xem lịch bình
thường), bundle sẵn tránh phụ thuộc mạng lần đầu mở app và tránh
"flash of unstyled text" lúc chưa tải xong font. Việc cần làm ở Phase 0:
tải 2 family (Baloo 2: weight 600/700/800; Be Vietnam Pro: weight
400/500/600/700) từ Google Fonts về `assets/fonts/`, khai báo family +
từng weight trong `pubspec.yaml`.

`TextTheme`: `displayLarge/headlineLarge` (số ngày to, tiêu đề tháng) dùng
Baloo 2 weight 700–800; phần còn lại (body, label) dùng Be Vietnam Pro
400–600 — đúng theo cách file design gán font trong từng `<span>`.

### 2.3. Theme provider (state)

Thêm vào `lib/data/settings_provider.dart` (cùng pattern với
`HolidayRemindDaysNotifier` đang có, KHÔNG đổi các Notifier cũ):

- `ThemeIdNotifier` (`Notifier<String>`) — lưu key `themeId` trong box
  `settings`, mặc định `'hong'`.
- `DarkModeNotifier` (`Notifier<bool?>`) — lưu key `darkMode`; `null` =
  theo hệ thống, `true/false` = ép Sáng/Tối. Mặc định `null`.

`main.dart`: `MaterialApp.router` đổi `theme:` cố định thành
`ref.watch(...)` build theme động (bọc `KadeApp` bằng `Consumer` hoặc dùng
`ConsumerWidget` — hiện `KadeApp` là `StatelessWidget`, cần đổi sang
`ConsumerWidget`, đây là thay đổi tối thiểu, không đụng logic điều hướng
trong `AppLifecycle`).

### 2.4. Kiểm tra sau Phase 0

- App chạy được, không còn theme đỏ Material 3 mặc định, nhưng **UI từng
  màn hình vẫn y nguyên bố cục cũ** (chỉ đổi màu/font nền tảng qua
  ColorScheme) — vì các widget cụ thể (Card, ListTile...) chưa được
  restyle ở phase này.
- `flutter test` chạy sạch (theme không phá test cũ vì test không nên phụ
  thuộc màu cụ thể — nếu có test kiểm `Colors.red` hoặc tương tự thì cần
  soát riêng).

---

## 3. Phase 1 — Lịch tháng (Month view)

Màn hình quan trọng nhất, cũng là màn hình đầu tiên người dùng thấy.

**File đụng tới:** `features/month_view/month_view_screen.dart`,
`features/month_view/today_card.dart`, `features/month_view/month_picker.dart`.

**Theo thiết kế mới (`Kade App.dc.html` §isMonth + `Kade Preview.dc.html`):**
- Header: nút tròn back/next thay vì `IconButton` phẳng, tiêu đề tháng
  dùng Baloo 2 cỡ lớn, dòng tháng âm nhỏ bên dưới màu `acT`.
- Nút "Tháng âm" dạng pill (bật/tắt), nút "Hôm nay" pill nền `ac`.
- Header thứ (T2...CN) nhỏ, chữ đậm, CN màu `sun`.
- Lưới ngày: mỗi ô là **thẻ bo góc** riêng biệt (`border-radius: 12-14px`,
  nền `sf`/`off`/`ac` tùy trạng thái, `box-shadow` nhẹ) thay vì ô liền
  nhau như hiện tại — đây là khác biệt hình ảnh rõ nhất so với UI cũ.
  Số ngày dùng Baloo 2 đậm; số âm lịch nhỏ bên dưới (không phải bên cạnh
  như bản hiện tại).
  Cơ chế hiện tại (`DayTile`) **giữ nguyên**: vẫn dùng `LayoutBuilder` để
  linh hoạt hiện/ẩn tên sự kiện theo bề rộng ô còn lại (`constraints.maxWidth`),
  không rút gọn xuống chỉ còn chấm tròn như trong file design — người dùng
  cần nhìn thấy ngay trong ô là lễ Âm lịch hay Dương lịch, không phải mở
  Chi tiết ngày mới biết. Cụ thể: `EventTag`/`UserEventTag` (nhãn nhỏ
  "ÂL"/"DL" màu theo kind — xem §0) **vẫn hiện trong ô lưới** như hiện tại,
  chỉ đổi style (bo góc, cỡ chữ, khoảng cách) cho khớp phong cách mới, còn
  `dots` kiểu design (chấm tròn không chữ) không dùng vì làm mất tín hiệu
  ÂL/DL. Restyle `Wrap`/`OverflowBox` phần tag để gọn hơn nếu cần, nhưng
  không đổi logic quyết định hiện/ẩn theo `constraints`.
- Chú giải (legend) dưới lưới: pill nhỏ nền `sf`, mỗi pill có chấm màu +
  nhãn, thêm cả "Ngày nghỉ" vào legend (hiện tại legend không có "ngày
  nghỉ" như 1 mục riêng).
- Bottom nav (khi compact) hoặc rail (khi wide) cần restyle pill khi active
  (nền `ac1`, chữ `acT`) — đây là phần chung với AppShell (Phase áp dụng
  tại đây vì đụng cùng lúc).

**Giữ nguyên:** breakpoint `AppLayout`, cách build `weeks`/`MonthData` từ
`monthProvider`, gesture vuốt đổi tháng, `CallbackShortcuts` (phím tắt),
route `_goMonth`/`_shift`/`_pickSolar`/`_pickLunar`.

**Rủi ro cần lưu ý:** `DayTile` hiện là widget `const`/stateless dùng
`LayoutBuilder` để quyết định hiện/ẩn title theo `constraints.maxWidth` —
thiết kế mới đơn giản hoá ô ngày (không có `Wrap` nhiều tag), nên có thể
bỏ được `OverflowBox`/`ClipRect` phức tạp hiện tại. Cần giữ lại cách xử lý
"today", "off day", "chủ nhật" (đang là 3 điều kiện tô màu riêng biệt).

---

## 4. Phase 2 — AppShell (bottom nav / rail)

Nhỏ nhưng dùng chung mọi màn hình nên làm sớm, ngay sau lịch tháng.

**File:** `features/shell/app_shell.dart`.

- Bottom nav (compact): pill nền `ac1` cho tab active, icon+label theo
  đúng 4 tab hiện có (Lịch, Sắp tới, Đổi ngày, Cài đặt) — **không đổi số
  lượng tab hay thứ tự**, chỉ đổi style `NavigationBar`/`NavigationDestination`
  qua `NavigationBarThemeData` trong `buildKadeTheme` (§2.1) thay vì sửa
  logic trong `app_shell.dart`.
- Rail (medium/wide): tương tự, qua `NavigationRailThemeData`.

Làm qua ThemeData thay vì sửa từng widget giúp đồng bộ toàn app mà không
đụng logic `_select`/`shell.goBranch`.

---

## 5. Phase 3 — Chi tiết ngày (Day detail)

**File:** `features/day_detail/day_detail_screen.dart`.

**Theo thiết kế mới:**
- Hero card đầu trang: nền `off` (nếu ngày nghỉ) hoặc `ac1`, bo góc lớn
  (28px), 2 cột — trái là ngày dương (thứ, số to, tháng/năm), phải là âm
  lịch (nhãn "ÂM LỊCH", số to màu `acT`, tên tháng âm, năm can chi) — thay
  cho layout hiện tại đang là `Text` xếp dọc đơn giản.
- Card "Tháng / Ngày / Tiết khí / Ngày hoàng đạo / Giờ hoàng đạo": đổi từ
  `Card` + `_InfoRow` custom hiện tại sang card bo góc lớn (22px), giờ
  hoàng đạo hiện dạng pill nhỏ (hiện tại đang là 1 dòng text nối bằng
  dấu phẩy).
- "Sự kiện" (app events) và "Sự kiện cá nhân": đổi `ListTile` sang card
  hàng riêng bo góc (18px) có shadow nhẹ, giữ nguyên cách nhóm theo
  `EventKind` cho app events.
- Nút "+ Thêm sự kiện": pill nền `ac`, icon `+`.

**Giữ nguyên:** toàn bộ logic trong `build()` liên quan tới
`dayCellProvider`, `_shift`, `_back`, phím Esc, route `/events/new`,
`/events/:id`.

---

## 6. Phase 4 — Sắp tới (Upcoming)

**File:** `features/upcoming/upcoming_screen.dart`.

- Chip lọc lớp (`FilterChip` hiện tại) → đổi thành pill tuỳ chỉnh giống
  design (icon chấm tròn + label, nền `sf`/trong suốt tuỳ trạng thái) —
  vẫn bind vào `layersProvider`/`toggle` y nguyên.
  layers y nguyên.
- Mỗi "ngày" trong danh sách: đổi từ dòng `Text` + `ListTile` phẳng sang
  1 card bo góc (22px) chứa badge ngày (ô vuông bo góc 16px, số to + tháng
  viết tắt) ở đầu, các sự kiện trong ngày đó xếp bên trong cùng card
  (đúng cấu trúc `d.cardStyle` → `d.badgeStyle` → `d.items` trong design).
- Giữ chế độ `compact` (nhúng trong lịch tháng ở layout medium/wide) —
  thiết kế mới không có ảnh riêng cho compact, nên áp cùng style card
  nhưng thu gọn padding, giữ đúng ý nghĩa hiện tại của flag `compact`.

**Giữ nguyên:** `upcomingProvider`, cách gom nhóm theo ngày, `openDay`.

---

## 7. Phase 5 — Đổi ngày (Converter)

**File:** `features/converter/converter_screen.dart`.

- 2 card "Dương → Âm" / "Âm → Dương" bo góc lớn (24px) thay `Card` mặc
  định, input ngày/tháng/năm đổi sang `TextField` pill bo tròn hoàn toàn
  (border 1.5px, nền `sf`/`bg` tuỳ theo card).
- Ô "Tháng nhuận" đổi từ `Checkbox` chuẩn sang custom box bo góc nhỏ (7px)
  theo đúng thiết kế (`conv.leapBoxStyle`).
- Nút "Đổi": pill nền `ac`, full width.
- Kết quả: số to Baloo 2 màu `acT` khi thành công; text màu `offT` khi
  lỗi — giữ nguyên state `hasResult`/`hasError` hiện có trong provider của
  màn hình (không đổi validation logic).

## 8. Phase 6 — Cài đặt (Settings) + màn Giao diện (Theme picker) + Sự kiện của tôi + Form sự kiện

Gom 4 màn này vào 1 phase vì chúng phụ thuộc lẫn nhau (Settings mở Theme
picker và Sự kiện của tôi; Sự kiện của tôi mở Form).

**8.1. Settings** (`features/settings/settings_screen.dart`):
- Đổi `ListView` phẳng + `Divider` sang nhóm card bo góc (24px) theo từng
  chủ đề: "Giao diện" + "Sự kiện của tôi" gộp 1 card đầu; "Nhắc nhở" 1
  card; "Đồng bộ Google" 1 card; "Sao lưu" 1 card; "Lịch nghỉ bù theo năm"
  1 card — đúng cấu trúc trong `Kade App.dc.html` §isSettings.
- **Không đụng** phần logic đọc `remoteConfigProvider`, sync Google,
  backup JSON, `checkUpdates` — chỉ bọc lại UI.

**8.2. Màn Giao diện (mới hoàn toàn)** — `features/settings/theme_screen.dart`:
- Grid 3 cột × 2 hàng chọn 1 trong 6 palette (mỗi ô: 2 chấm tròn preview
  màu `ac`+`b`, tên palette, viền `ac` khi đang chọn) → gọi
  `ThemeIdNotifier.set(...)` (thêm method `set` theo đúng pattern
  `HolidayRemindDaysNotifier.set`).
- Segmented control Sáng/Tối → gọi `DarkModeNotifier.set(...)`.
- 4 ô preview nhỏ minh hoạ theme đang chọn (tĩnh, không cần data thật, có
  thể dùng dữ liệu mẫu cố định giống cách `mau-giao-dien.png` làm).

**8.3. Sự kiện của tôi** (`features/user_events/user_events_screen.dart`):
- List card bo góc, nút "+ Thêm sự kiện" nổi (FAB pill) góc dưới phải,
  thay `FloatingActionButton` mặc định — giữ nguyên
  `context.push('/events/new')`.

**8.4. Form sự kiện** (`features/user_events/user_event_form_screen.dart`):
- Input pill, segmented Dương/Âm lịch, ô "Lặp hàng năm" dạng checkbox bo
  góc tuỳ chỉnh, bảng chọn màu (8 chấm tròn), nút Lưu pill lớn — đúng theo
  `su-kien-moi.png`. **Không đụng** `saveEvent`/`deleteEvent`/validate.

---

## 9. Phase 7 — Widget màn hình chính (Android home-screen widget)

Phase riêng theo yêu cầu, làm sau cùng vì đây là code native (Kotlin +
XML layout), không phải Flutter widget tree.

**File:** `android/app/src/main/res/layout/widget_2x2.xml`,
`widget_4x2.xml`, `android/app/src/main/res/drawable/widget_bg.xml`,
`android/app/src/main/res/values*/colors.xml`,
`android/.../KadeWidgetProvider.kt`, `lib/data/widget_data.dart`,
`lib/data/today_card.dart` (dữ liệu đẩy ra widget).

Thiết kế mới cho widget (`(USE)Kade - Thiết kế mới.dc.html`, biến thể
4a/4b/4c...) hiện có **nhiều phương án chưa chốt** (4a, 4b, 4c, và mục 1c
"widget mới" ở cuối file) — cần chọn 1 phương án cụ thể trước khi code,
vì Android RemoteViews có giới hạn riêng (không dùng được gradient phức
tạp, bo góc + shadow tự do như CSS).

**CHƯA LÀM BÂY GIỜ.** Đây là việc của lúc bắt đầu Phase 7, không phải bây
giờ. Khi tới phase này sẽ dừng lại và hỏi người dùng chọn 1 trong các biến
thể (4a/4b/4c/1c), có cần đơn giản hoá thêm cho phù hợp giới hạn
`RemoteViews`/`AppWidget` hay không — trước khi viết bất kỳ dòng code nào
cho widget.

Đây là lý do khiến Phase 7 tách hẳn cuối plan: vừa native, vừa còn quyết
định thiết kế mở.

---

## 10. Thứ tự thực hiện (đề xuất)

1. **Phase 0** — Nền tảng theme (bắt buộc trước tất cả).
2. **Phase 2** — AppShell (nhỏ, dùng chung, làm sớm để mọi màn sau thấy
   đúng nav ngay).
3. **Phase 1** — Lịch tháng (màn quan trọng nhất).
4. **Phase 3** — Chi tiết ngày.
5. **Phase 4** — Sắp tới.
6. **Phase 5** — Đổi ngày.
7. **Phase 6** — Cài đặt + Giao diện + Sự kiện của tôi + Form.
8. **Phase 7** — Widget Android (sau cùng, cần chốt biến thể thiết kế
   trước khi bắt đầu).

Mỗi phase: implement UI → `flutter analyze` sạch → `flutter test` sạch →
so sánh bằng mắt với screenshot tương ứng trong `plan/new-ui/screenshot/`
→ mới sang phase kế tiếp. Không gộp nhiều phase trong 1 lần sửa để dễ
review từng phần.

---

## 11. Điểm còn để mở — chỉ hỏi khi tới đúng lúc, KHÔNG hỏi trước

- **Phase 7 (widget Android):** chốt 1 trong các biến thể thiết kế
  (4a/4b/4c/1c) trước khi code, vì RemoteViews giới hạn hơn Flutter/CSS
  nhiều (không gradient phức tạp, bo góc/shadow tự do). Đây là điểm mở
  duy nhất còn lại trong plan này — sẽ dừng lại hỏi đúng lúc bắt đầu
  Phase 7, không hỏi trước.

Các điểm khác đã chốt và ghi cụ thể trong plan: font bundle tĩnh (§2.2),
hiển thị nhãn ÂL/DL giữ nguyên trong ô lưới tháng (§3), bộ màu mặc định
Hồng phấn, có build màn chọn theme.
