# Setup Google cho Kade

Hai phần độc lập. Phần A cần trước Phase 1 bước 5, phần B cần trước Phase 2 bước 10.
Tất cả là việc user làm tay trên console Google; agent chỉ cần kết quả (URL / Client ID).

---

## A. Google Sheet + Apps Script (remote config nghỉ bù)

### A.1 Tạo Sheet
1. Tạo Google Sheet mới, đặt tên `Kade Config`.
2. Đổi tên tab đầu thành `overrides` (đúng chữ thường).
3. Dòng 1 (header): `year` | `date` | `kind` | `note`
4. Nhập dữ liệu, ví dụ (số liệu minh họa — thay bằng thông báo chính thức của Bộ LĐTBXH):

| year | date | kind | note |
|---|---|---|---|
| 2027 | 2027-02-05 | off | Nghỉ Tết |
| 2027 | 2027-02-06 | off | Mùng 1 |
| 2027 | 2027-02-13 | work | Làm bù |

- `date`: gõ `YYYY-MM-DD` hoặc để Sheet tự nhận kiểu Date đều được.
- `kind`: `off` = nghỉ, `work` = làm bù. Dòng khác bị bỏ qua.
- Ngày lễ chính thức cố định (30/4, 2/9, Tết mùng 1–3…) **không** cần nhập — app đã có trong `calendar_data`. Chỉ nhập ngày nghỉ bù / hoán đổi thay đổi theo năm.

### A.2 Gắn Apps Script
1. Trong Sheet: menu **Extensions → Apps Script**.
2. Xóa nội dung mặc định, dán toàn bộ `tools/apps-script/Code.gs`.
3. Đặt tên project (góc trên trái): `Kade Config`. Ctrl+S.
4. Kiểm tra: chọn hàm `testConfig` ở dropdown (các hàm `buildJson_`, `toIsoDate_` không hiện vì tên kết thúc bằng `_` — Apps Script coi là private) → **Run**. Lần đầu sẽ hỏi quyền:
   *Review permissions → chọn tài khoản → Advanced → Go to Kade Config (unsafe) → Allow.*
   (Cảnh báo "unsafe" là vì script tự viết chưa verify — bình thường.)
5. Xem **Execution log** → phải thấy JSON có `years`.

### A.3 Deploy web app
1. **Deploy → New deployment**.
2. Bấm bánh răng cạnh "Select type" → **Web app**.
3. Điền:
   - Description: `v1`
   - Execute as: **Me**
   - Who has access: **Anyone**  ← quan trọng, nếu chọn "Anyone with Google account" app sẽ nhận HTML login thay vì JSON
4. **Deploy** → copy **Web app URL** (dạng `https://script.google.com/macros/s/AKfy.../exec`).
5. Mở URL đó trong tab ẩn danh → phải thấy JSON. Nếu thấy trang đăng nhập → quay lại bước 3.

### A.4 Đưa URL vào app
Không hardcode. Ở root repo, copy `dart_defines.example.json` → `dart_defines.json` (gitignored), dán URL vào `KADE_CONFIG_URL`.
Mọi lệnh run/build (từ `apps/kade`) thêm `--dart-define-from-file=../../dart_defines.json`. Agent đọc ở `lib/core/env.dart`.
Chưa có `apps/kade` (trước Phase 1) thì chỉ cần tạo file, chưa chạy gì.

### A.5 Cập nhật về sau
- **Sửa dữ liệu trong Sheet**: không cần deploy lại. Script có cache 5 phút → tối đa 5 phút sau app thấy.
- **Sửa code script**: **Deploy → Manage deployments → ✎ (Edit) → Version: New version → Deploy**. URL `/exec` giữ nguyên. Nếu bấm "New deployment" thay vì Edit thì URL đổi → phải đổi `KADE_CONFIG_URL`.
- `version` trong JSON = thời điểm Sheet được sửa lần cuối (tự động) → app chỉ cần so số lớn hơn.

### A.6 Lưu ý kỹ thuật (cho agent)
- URL `/exec` trả **302** sang `script.googleusercontent.com` rồi mới ra JSON. `package:http` và `fetch` trên web đều follow redirect — không cần xử lý gì.
- CORS: response JSON từ Apps Script web app "Anyone" cho phép GET từ browser. **Verify ngay ở Phase 1 bước 5** bằng cách chạy Flutter web và gọi thật. Nếu lỗi CORS → theo D008: đổi nguồn sang file JSON trên GitHub raw (Sheet vẫn là nơi soạn, chạy `test_` copy output ra file), ghi DECISIONS mới.
- Cold start Apps Script 1–3 giây. App đã có timeout 5s + cache + asset fallback nên không chặn UI.
- Không có auth, ai có URL cũng đọc được. Dữ liệu là ngày nghỉ công khai → chấp nhận.
- chạy \test_` copy output ra file→chạy `testConfig` copy output ra file`
---

## B. Google Cloud — OAuth cho Sign-In + Drive appData (sync)

### B.1 Project + API
1. https://console.cloud.google.com → **New Project** → tên `Kade` → Create → chọn project.
2. **APIs & Services → Library** → tìm **Google Drive API** → Enable.
   (Không cần bật Sheets API — sync không dùng Sheets.)

### B.2 OAuth consent screen
1. **APIs & Services → OAuth consent screen** (giao diện mới gọi là *Google Auth Platform → Branding*).
2. User type: **External** → Create.
3. App name `Kade`, support email, developer email → Save.
4. **Scopes → Add or remove scopes** → tìm và tick:
   `https://www.googleapis.com/auth/drive.appdata` → Update → Save.
   Đây là scope **non-sensitive** → không cần Google verify app, không có màn hình "unverified app" khi publish.
5. **Test users**: thêm các Gmail m sẽ dùng để test. Khi consent screen còn ở trạng thái *Testing*, chỉ các tài khoản này đăng nhập được, và token hết hạn sau 7 ngày (phải đăng nhập lại — chỉ ở Testing).
6. Khi muốn ai cũng dùng được: **Publish app**. Với scope non-sensitive, publish xong là xong, không phải nộp verify.

### B.3 OAuth client — Web
1. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
2. Application type: **Web application**, name `Kade Web`.
3. **Authorized JavaScript origins** — thêm đủ:
   - `http://localhost:5000` (dev — khớp `flutter run -d chrome --web-port 5000`)
   - `http://localhost:5001` (máy hiện tại port 5000 bị app khác chiếm → chạy 5001, ERRORS E011)
   - domain thật khi deploy, vd `https://kade.example.com` (thêm sau ở Phase 3 bước 15)
   Origin phải khớp **đúng port** đang chạy, nếu không GIS báo `origin_mismatch` / popup trắng.
4. Authorized redirect URIs: để trống (GIS popup không cần).
5. Create → copy **Client ID** (dạng `1234-abc.apps.googleusercontent.com`).
6. Điền vào `KADE_WEB_CLIENT_ID` trong `dart_defines.json` (root repo, gitignored; mẫu `dart_defines.example.json`). App đọc qua `--dart-define-from-file`, không hardcode.

### B.4 OAuth client — Android
Cần **1 client cho mỗi SHA-1**. Tối thiểu 2 (debug + release), 3 nếu dùng Play App Signing.

1. Lấy SHA-1 debug:
   ```
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
      macOS/Linux:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   Windows PowerShell:
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

   File chưa có = máy chưa build Android debug lần nào. Hoặc làm bước này sau khi có apps/kade và đã `flutter run` Android 1 lần
   (rồi `cd apps/kade/android; ./gradlew signingReport` in SHA-1 luôn), hoặc tạo trước:
   keytool -genkey -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"

2. Lấy SHA-1 release (sau khi tạo keystore ở Phase 4 bước 18):
   ```
   keytool -list -v -keystore <path>/kade-release.jks -alias <alias>
   ```
3. Nếu dùng Play App Signing: Play Console → app → **Setup → App signing** → copy SHA-1 của *App signing key certificate*.
4. Với mỗi SHA-1: **Create credentials → OAuth client ID → Android**:
   - Name: `Kade Android debug` / `release` / `play`
   - Package name: `vn.kade.kade` (đã chốt D001; `applicationId` + `namespace` trong `apps/kade/android/app/build.gradle.kts`, đổi ở Phase 2 bước 10)
   - SHA-1: dán vào. Máy hiện tại (debug.keystore tạo 2026-08-18) agent đã đọc:
     `54:F9:E3:8D:28:67:96:BA:E0:80:DC:B1:06:1E:6C:51:CA:35:1C:14`
5. Create. **Không cần copy Client ID Android vào code** — `google_sign_in` trên Android tự khớp theo package + SHA-1.

### B.5 Kiểm tra nhanh
- Web (chạy từ `apps/kade`, Flutter 3.44.5 — E008; port phải nằm trong Authorized JavaScript origins ở B.3):
   - chrome: `flutter run -d chrome --web-port 5001 --dart-define-from-file=../../dart_defines.json`
   - edge: `flutter run -d edge --web-port 5001 --dart-define-from-file=../../dart_defines.json`
   - Cốc Cốc: `$env:CHROME_EXECUTABLE = "C:\Program Files\CocCoc\Browser\Application\browser.exe"` rồi chạy lệnh chrome ở trên.
   → Cài đặt → Đồng bộ với Google → popup chọn tài khoản → thấy scope "See, edit, create, and delete its own configuration data in your Google Drive" → Allow.
- Android debug: cài bản debug → tương tự. Lỗi `10` / `DEVELOPER_ERROR` = SHA-1 hoặc package sai (E002).
- Xem file sync đã tạo chưa: không thấy được trong Drive UI (appDataFolder ẩn). Kiểm tra qua **Drive → Settings → Manage apps** → Kade → hiện dung lượng "hidden app data".

### B.6 Xóa dữ liệu test
Drive → Settings → Manage apps → Kade → Options → **Delete hidden app data**.
