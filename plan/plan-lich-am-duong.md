# Plan chi tiết — Kade (Lịch Âm/Dương, Flutter web + Android)

> v2 — đã chốt các quyết định mở của v1. iOS lùi sang phase sau.

---

## 0. Phạm vi MVP

**Target**: Web (PWA) + Android. iOS: phase sau, kiến trúc không chặn.

**Có trong MVP**
- Engine âm lịch VN (UTC+7), can chi, tiết khí, giờ hoàng đạo
- Lịch tháng (âm + dương trong cùng ô), view ngày chi tiết
- Sự kiện app: lễ VN nghỉ / lễ VN kỷ niệm / ~10 ngày quốc tế
- Nghỉ bù theo năm: **remote config từ Google Sheet** + fallback asset
- Sự kiện cá nhân: 1 ngày hoặc khoảng ngày, âm hoặc dương, lặp hàng năm, tháng nhuận mặc định `firstMonth`
- "Sắp tới" + nhắc trước N ngày (local notification, Android)
- Đổi ngày hai chiều âm ↔ dương
- Export/Import JSON
- **Sync sự kiện cá nhân qua Google Drive appDataFolder** (Google Sign-In, không backend riêng)
- Android: widget 2x2 + 4x2
- Web: PWA, deep-link theo URL

**Không có trong MVP**
- iOS (app + WidgetKit)
- Xem ngày tốt xấu chi tiết (sao, trực, xung khắc)
- Import từ device calendar
- Chia sẻ ô ngày thành ảnh

**Giả định**
- 1 codebase Flutter, build web + Android
- Offline-first: Hive là source of truth, Drive chỉ là bản sao để sync
- Cần 1 Google Cloud project: OAuth client Web + OAuth client Android (SHA-1 debug + release), bật Drive API
- UI tiếng Việt, chưa i18n
- < vài trăm sự kiện/user

---

## 1. Kiến trúc tổng thể

```
kade/
├ packages/
│  ├ lunar_core/          # pure Dart, zero deps. Thiên văn + quy đổi + can chi + tiết khí
│  └ calendar_data/       # pure Dart. Danh sách lễ (solar/lunar) + model YearOverride + asset fallback
├ apps/
│  └ kade/                # Flutter
│     ├ lib/
│     │  ├ core/          # DI, theme, routing (go_router), platform switch
│     │  ├ features/
│     │  │  ├ month_view/
│     │  │  ├ day_detail/
│     │  │  ├ upcoming/
│     │  │  ├ user_events/
│     │  │  ├ converter/
│     │  │  ├ sync/       # Google Sign-In + Drive appData
│     │  │  └ settings/
│     │  ├ data/
│     │  │  ├ local/      # Hive boxes, repositories
│     │  │  └ remote/     # remote_config (Sheet), drive_sync
│     │  └ platform/      # home_widget bridge, notifications (Android; stub trên web)
│     ├ android/          # AppWidgetProvider (Kotlin)
│     └ web/              # manifest.json, GIS meta tag
└ tools/
   └ gen_lunar_table.dart # sinh bảng JSON 1900–2100 + test đối chiếu
```

**Stack** (đã chốt)
| Việc | Chọn |
|---|---|
| State | Riverpod |
| Routing | go_router |
| Storage | Hive CE (IndexedDB trên web) |
| Model | freezed + json_serializable |
| Widget | `home_widget` |
| Notification | `flutter_local_notifications` + `timezone` |
| Auth + Drive | `google_sign_in` + `googleapis` + `extension_google_sign_in_as_googleapis_auth`, scope `drive.appdata` |
| Remote config | Google Sheet → Apps Script `doGet` trả JSON; `http` + cache Hive |

---

## 2. Data model

### 2.1 `DayInfo` — output engine cho 1 ngày dương
```dart
class DayInfo {
  DateTime solar;
  LunarDate lunar;          // day, month, year, isLeapMonth
  String canChiYear, canChiMonth, canChiDay;
  String? tietKhi;          // chỉ có nếu hôm đó bắt đầu tiết khí
  List<String> gioHoangDao;
  bool isHoangDao;
}
```

### 2.2 `Event` — sự kiện app (read-only, `calendar_data`)
```dart
enum EventKind { vnHoliday, vnMemorial, international }
enum CalendarType { solar, lunar }

class Event {
  String id;                // "tet", "gio-to", "valentine"
  String title;
  EventKind kind;
  CalendarType type;
  int day, month;
  int durationDays;         // Tết = 3, mặc định 1
  String? description;
}
```

Quốc tế (~10): Năm mới 1/1, Valentine 14/2, Cá tháng Tư 1/4, Ngày Trái Đất 22/4, Ngày của Mẹ (CN thứ 2 tháng 5)*, Ngày của Cha (CN thứ 3 tháng 6)*, Halloween 31/10, Giáng sinh 25/12, Ngày Quốc tế Thiếu nhi 1/6, Ngày Nhà giáo QT 5/10.
`*` cần rule "CN thứ N của tháng" → thêm field `nthWeekday` optional, hoặc bỏ 2 ngày này khỏi MVP. **[chốt khi code]**

### 2.3 `YearOverride` — nghỉ bù, từ Google Sheet
Sheet 1 tab `overrides`, cột: `year | date | kind(off|work) | note`
```
2027 | 2027-02-05 | off  | Nghỉ Tết
2027 | 2027-02-13 | work | Làm bù
```
Apps Script `doGet` gom thành:
```json
{ "version": 3, "updatedAt": "2026-11-20", "years": { "2027": { "off": [...], "work": [...] } } }
```
App: fetch tối đa 1 lần/24h → lưu Hive `remote_config` → nếu fail dùng cache → nếu chưa có cache dùng asset `overrides.json` bundled (copy từ sheet lúc release).

### 2.4 `UserEvent` — sự kiện cá nhân (Hive, sync)
```dart
class UserEvent {
  String id;                // uuid v4
  String title;
  CalendarType type;
  int day, month;
  int? year;                // null = lặp hàng năm
  int durationDays;
  LeapMonthRule leapRule;   // mặc định firstMonth
  int? remindBeforeDays;
  String? note;
  int colorIndex;
  DateTime createdAt, updatedAt;
  DateTime? deletedAt;      // tombstone — cần cho sync, không xóa cứng
}
```

### 2.5 `SyncEnvelope` — format Export/Import **và** file trên Drive (1 format)
```json
{ "schema": 1, "exportedAt": "...", "deviceId": "...", "events": [ UserEvent... ] }
```

### 2.6 `DayEvents` — kết quả gộp cho 1 ô lịch
```dart
class DayEvents {
  DateTime date;
  List<Event> appEvents;
  List<UserEvent> userEvents;   // đã lọc deletedAt == null
  bool isOffDay;
}
```

---

## 3. Luồng chung (web + Android)

### 3.1 Khởi động
```
App start
  → mở Hive boxes: user_events, settings, remote_config
  → load YearOverride: cache Hive → asset fallback; kick fetch remote nếu > 24h (không chặn UI)
  → tính DayInfo tháng hiện tại (lazy, cache theo tháng)
  → render MonthView, highlight hôm nay
  → nếu đã đăng nhập Google: signInSilently → sync (nền, §3.10)
  → [Android] refresh widget + reschedule notification
```

### 3.2 resolveMonth(year, month) — hàm trung tâm
```
for each solar day:
  lunar      = lunar_core.solarToLunar(day)
  appEvents  = solarEvents[m][d] + lunarEvents[lunar.m][lunar.d] (+ durationDays)
  userEvents = userEvents.where(deletedAt == null && matches(day, lunar, leapRule))
  isOffDay   = override[year].off.contains(day) || any(kind == vnHoliday)
             && !override[year].work.contains(day)
return Map<DateTime, DayEvents>
```
Cache `(year, month)`; invalidate khi user events đổi hoặc remote config đổi.

### 3.3 Xem lịch
```
MonthView
  ├ vuốt / ◀ ▶ → tháng ±1
  ├ tap tiêu đề → picker tháng/năm dương
  ├ "Tháng âm" → picker tháng âm → nhảy tới tháng dương chứa mùng 1 âm
  ├ "Hôm nay" → về tháng hiện tại
  └ tap ô → DayDetail
```

### 3.4 Chi tiết ngày
```
DayDetail(date)
  ├ header: Thứ, dd/mm/yyyy · Âm dd/mm (can chi năm)
  ├ khối lịch: can chi tháng/ngày, tiết khí, hoàng đạo/hắc đạo, giờ hoàng đạo
  ├ khối sự kiện: app (nhóm theo kind) + cá nhân
  ├ "+ Thêm sự kiện" → form điền sẵn ngày
  └ vuốt → ngày ±1
```

### 3.5 Sự kiện cá nhân
```
Tạo/sửa → form → validate → Hive (updatedAt = now) → invalidate cache
        → [Android] reschedule + widget → sync debounce 5s
Xóa     → confirm → set deletedAt (tombstone) → như trên
Purge   → tombstone > 90 ngày và đã sync → xóa cứng
```

### 3.6 Sắp tới
```
upcoming(60 ngày): resolveDay từng ngày → flatten → sort → group
"Hôm nay" / "Ngày mai" / "còn N ngày"; toggle 4 lớp lưu settings
```

### 3.7 Đổi ngày
```
Dương → Âm: date picker → âm + can chi
Âm → Dương: nhập d/m/y + checkbox nhuận → dương (báo lỗi nếu năm đó không có tháng nhuận đó)
```

### 3.8 Nhắc nhở (logic chung)
```
buildReminders(horizon 90 ngày):
  UserEvent có remindBeforeDays → nextOccurrence (quy đổi âm→dương) - N ngày, 08:00
  vnHoliday → remindBefore = settings.holidayRemind (mặc định 7)
```

### 3.9 Remote config (Sheet)
```
fetchOverrides():
  GET <apps-script-url>  (timeout 5s)
  → parse → so version với cache → nếu mới hơn: lưu Hive, invalidate cache tháng
  → lỗi → im lặng, dùng cache
Trigger: app start (nếu > 24h), nút "Kiểm tra cập nhật" trong Settings
```

### 3.10 Sync (Google Drive appDataFolder)
```
Đăng nhập (Settings → "Đồng bộ với Google")
  → google_sign_in scopes: [drive.appdata]
  → lưu trạng thái đã đăng nhập

sync():                                     // 1 file: kade_events.json trong appDataFolder
  1. files.list(spaces: 'appDataFolder', q: name='kade_events.json')
  2. nếu có → download → remote: SyncEnvelope
     nếu không → remote = rỗng, sẽ create ở bước 4
  3. merge(local, remote) theo id:
       - chỉ 1 bên có → lấy bên đó
       - cả 2 → lấy bản updatedAt lớn hơn (tombstone cũng là 1 bản, so cùng quy tắc)
     → ghi kết quả vào Hive
  4. upload merged (create hoặc update media) → lưu lastSyncAt
  5. invalidate cache, [Android] widget + notification

Trigger: app start (nếu đã login), sau khi sửa sự kiện (debounce 5s), nút "Đồng bộ ngay",
         app resume nếu > 15 phút
Đăng xuất: giữ dữ liệu local, xóa token. Tuỳ chọn "Xóa dữ liệu trên Drive".
```
Merge dựa hoàn toàn vào `updatedAt` + tombstone → không cần server, không có "resurrect" sự kiện đã xóa.

---

## 4. Section WEB

### 4.1 Routing (go_router)
```
/                  → redirect /YYYY/MM
/YYYY/MM           → MonthView            (?lunar=1: đang duyệt theo tháng âm)
/d/YYYY-MM-DD      → DayDetail            (dialog trên desktop, full page < 1024)
/upcoming
/convert
/events
/settings
```

### 4.2 Layout responsive
| Breakpoint | Layout |
|---|---|
| ≥ 1024 | 2 cột: MonthView (~65%) + panel phải cố định: hero "hôm nay" + Sắp tới |
| 600–1023 | 1 cột: MonthView trên, Sắp tới dưới |
| < 600 | như Android: MonthView + bottom nav |

### 4.3 Hero card "hôm nay" — thay widget, dùng chung `TodayCardData` với widget Android

### 4.4 Storage & sync
- Hive → IndexedDB. Cảnh báo 1 lần "Dữ liệu lưu trên trình duyệt này, bật đồng bộ Google để không mất".
- Google Sign-In web: cần meta tag client ID trong `index.html`, dùng GIS. Access token hết hạn 1h → trước mỗi `sync()`: `signInSilently()`; nếu 401 → `requestScopes([drive.appdata])` lại (có popup).
- Export/Import: download blob / file picker.

### 4.5 Remote config trên web — CORS
Apps Script web app deploy "Anyone" trả JSON qua `ContentService` → fetch từ browser được. **Verify sớm ở Phase 1**: nếu CORS lỗi thì đổi sang GitHub raw JSON (Sheet chỉ là nơi soạn, script đẩy lên GitHub).

### 4.6 PWA
- `manifest.json` standalone, icon, theme color; service worker mặc định Flutter
- Nhắc nhở trên web: không làm (cần Web Push + server)

### 4.7 Khác
- Không `dart:io`; `platform/` dùng conditional import
- Phím: ← → đổi tháng, `T` hôm nay, `Esc` đóng DayDetail

### 4.8 Tiêu chí hoàn thành web
- [ ] `/2027/02` đúng tháng, ô 6/2 (Tết Đinh Mùi) có badge lễ + nghỉ bù từ Sheet
- [ ] Reload giữ tháng đang xem
- [ ] Tạo sự kiện âm → đóng tab → mở lại còn
- [ ] Đăng nhập Google → tạo sự kiện → mở trình duyệt khác đăng nhập cùng tài khoản → thấy sự kiện
- [ ] Xóa sự kiện ở máy A → sync máy B → biến mất (không resurrect)
- [ ] Lighthouse PWA installable pass

---

## 5. Section ANDROID

### 5.1 Navigation
```
Bottom nav: [Lịch] [Sắp tới] [Đổi ngày] [Cài đặt]
Cài đặt → Sự kiện của tôi / Lớp hiển thị / Nhắc lễ trước N ngày / Đồng bộ Google / Export-Import
```

### 5.2 Widget — cơ chế
Widget native không chạy Dart → Dart tính sẵn, native chỉ đọc.
```
Dart (app resume, sau khi sửa sự kiện, sau sync):
  data = buildWidgetData(from: today, days: 35)
       = [{ date, weekday, solarDay, solarMonth, lunarDay, lunarMonth,
            canChiDay, topEvents[≤3], isOffDay }]
  HomeWidget.saveWidgetData('days_json', json)
  HomeWidget.updateWidget(android: 'KadeWidgetProvider')

Kotlin AppWidgetProvider:
  đọc days_json → entry có date == hôm nay (giờ máy) → RemoteViews
  layout: widget_2x2.xml, widget_4x2.xml (+ values-night)
  qua ngày: AlarmManager 00:00:05 → onUpdate; fallback updatePeriodMillis 30 phút
  tap → deep link /d/hôm-nay
```
JSON 35 ngày → app không mở 1 tháng widget vẫn đúng, không phụ thuộc background job / OEM kill.

### 5.3 Widget — nội dung
```
2x2                          4x2
┌──────────────┐             ┌──────────────┬────────────────────┐
│ Thứ Tư       │             │ Thứ Tư       │ Sắp tới            │
│ 9            │             │ 9  Tháng 9   │ • Trung Thu   13 ng│
│ Tháng 9      │             │ 28/7 âm      │ • Giỗ ông     20 ng│
│ 28/7 âm      │             │ Giáp Tý      │ • 20/10       41 ng│
│ Giáp Tý      │             └──────────────┴────────────────────┘
└──────────────┘
```
Hôm nay có sự kiện → dòng can chi đổi thành tên sự kiện (màu theo lớp). Ngày nghỉ → số ngày đỏ.

### 5.4 Nhắc nhở
```
onAppResume / onUserEventChanged / afterSync:
  reminders = buildReminders(90 ngày)
  cancelAll() → zonedSchedule từng cái (id = hash(eventId, fireAt), payload /d/<date>)
```
- Xin quyền `POST_NOTIFICATIONS` (13+) lần đầu user bật nhắc, không xin lúc mở app
- Dùng `inexactAllowWhileIdle` → không cần `SCHEDULE_EXACT_ALARM`

### 5.5 Sign-In Android
- OAuth client Android với SHA-1 của debug keystore **và** release keystore (hay quên → sign-in fail chỉ trên bản release)
- Token refresh tự động, không có vấn đề 1h như web

### 5.6 Khác
- Múi giờ: "hôm nay" theo giờ máy, engine cố định UTC+7; ghi rõ trong Settings
- Đổi ngày lúc app đang mở: `WidgetsBindingObserver` + so date → rebuild
- Dark mode app + widget

### 5.7 Tiêu chí hoàn thành Android
- [ ] Widget 2x2 + 4x2 đúng ngày, tự đổi sau 0h không mở app (đổi giờ máy để test)
- [ ] Giỗ 15/7 âm nhắc trước 3 ngày → notification đúng ngày dương, tap mở đúng DayDetail
- [ ] Đổi giờ máy +30 ngày → widget vẫn đúng
- [ ] Sync 2 chiều với web pass (như §4.8)
- [ ] Bản release ký keystore thật đăng nhập Google được
- [ ] Dark mode không vỡ

---

## 6. Roadmap & verify

### Phase 0 — Engine (1 tuần)
1. Port Hồ Ngọc Đức → `lunar_core` → verify: 30 ngày Tết 1900–2100 + năm lệch TQ (1985, 2007) pass
2. Can chi, tiết khí, giờ hoàng đạo → verify: đối chiếu 20 ngày ngẫu nhiên với lịch vạn niên
3. `gen_lunar_table.dart` → verify: bảng == runtime cho mọi ngày 1900–2100

### Phase 1 — Data + Core UI (2 tuần)
4. `calendar_data`: 3 danh sách lễ + asset override → verify: unit test resolveMonth 2/2027
5. Google Sheet + Apps Script doGet + fetch/cache → verify: đổi 1 dòng trong sheet → app hiện sau khi "Kiểm tra cập nhật"; **fetch từ Flutter web không lỗi CORS**
6. MonthView + DayDetail + Converter → verify: §4.8 mục 1–2
7. UserEvent CRUD + tombstone + Hive → verify: tạo/sửa/xóa, reload, tháng nhuận `firstMonth` đúng
8. Upcoming → verify: sự kiện âm hiện đúng ngày dương năm nay/năm sau
9. Export/Import JSON → verify: export → xóa hết → import → giống hệt

### Phase 2 — Sync (1 tuần)
10. Google Cloud project, OAuth clients web + Android, Drive API
11. Sign-in web + Android → verify: lấy được access token có scope drive.appdata trên cả 2
12. `sync()` + merge → verify: unit test merge (4 case: chỉ local / chỉ remote / cả 2 local mới hơn / tombstone thắng); §4.8 mục 4–5
13. Trigger + debounce + xử lý 401 trên web

### Phase 3 — Web release (1 tuần)
14. Routing + responsive + PWA + phím → verify: §4.8 đủ
15. Deploy Cloudflare Pages / GitHub Pages; thêm origin vào OAuth client

### Phase 4 — Android release (1.5 tuần)
16. Notification → verify: §5.7 mục 2
17. Widget → verify: §5.7 mục 1, 3
18. Release keystore + SHA-1 + Play listing → verify: §5.7 mục 5

### Phase 5 — sau MVP
- iOS: WidgetKit (timeline 35 entry), App Group, giới hạn 64 pending notification, Sign in with Apple nếu Store bắt
- Ngày tốt xấu chi tiết
- Chia sẻ ô ngày thành ảnh
- Import device calendar

---

## 7. Quyết định

**Đã chốt**
1. Tên: **Kade**
2. Stack §1
3. Export/Import JSON trong MVP
4. iOS: phase 5
5. Tháng nhuận mặc định: `firstMonth`
6. Quốc tế ~10 ngày (danh sách §2.2)
7. Sync: Google Drive appDataFolder, trong MVP (Phase 2)
8. Nghỉ bù: remote config từ Google Sheet qua Apps Script

**Còn mở, chốt khi code**
- Ngày của Mẹ/Cha (rule "CN thứ N") giữ hay bỏ
- Sheet sync? — **không**, chỉ appDataFolder; nếu sau này muốn user xem được thì thêm "Export lên Sheet" 1 chiều

## 8. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Engine lệch 1 ngày | test đối chiếu 1900–2100 Phase 0, ship bảng |
| Apps Script CORS trên web | verify ngay Phase 1 bước 5; fallback GitHub raw JSON |
| Apps Script cache/chậm (~vài giây cold start) | timeout 5s, luôn có cache + asset |
| Web token Google hết hạn 1h | signInSilently trước sync, 401 → requestScopes |
| Sync resurrect sự kiện đã xóa | tombstone `deletedAt`, purge sau 90 ngày |
| 2 máy sửa cùng sự kiện offline | last-write-wins theo `updatedAt`, chấp nhận ở MVP |
| Release Android sign-in fail | SHA-1 release keystore thêm vào OAuth client từ Phase 2 |
| Widget bị OEM kill background | JSON 35 ngày, không phụ thuộc job nền |
