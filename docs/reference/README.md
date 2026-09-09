# docs/reference — nguồn cho engine, KHÔNG được tự bịa

## amlich-aa98.js
Thuật toán âm lịch Việt Nam của Hồ Ngọc Đức (2006), dựa trên Jean Meeus, *Astronomical Algorithms* (1998).
Lấy nguyên bản từ GitHub `vanng822/amlich` (`lib/amlich-aa98.js`), 227 dòng, giữ nguyên header license.
`lunar_core` port 1:1 từ file này — giữ tên hàm (`jdFromDate`, `NewMoon`, `SunLongitude`, `getLunarMonth11`,
`getLeapMonthOffset`, `convertSolar2Lunar`, `convertLunar2Solar`) để đối chiếu từng hàm khi test.

**License: "personal, non-commercial use"** — xem D009 trong `.memory/DECISIONS.md`. User phải quyết trước khi release
nếu app có thu tiền/quảng cáo.

## tet_1900_2100.json
Sinh bằng `node tools/gen_fixture.js` từ chính `amlich-aa98.js`, múi giờ +7. Mỗi năm âm lịch:
```
"2027": {
  "tet": "2027-02-06",        // ngày dương của mùng 1 tháng Giêng
  "leapMonth": 0,             // 0 = không nhuận, n = nhuận tháng n
  "daysInYear": 354,
  "months": [ { "m": 1, "leap": false, "days": 29, "start": "2027-02-06" }, ... ]
}
```
Dùng cho test `lunar_core`: với mọi năm, `convertLunar2Solar(1,1,y)` == `tet`; với mọi tháng, ngày bắt đầu và số ngày khớp;
`convertSolar2Lunar` của từng ngày trong `months[i]` trả đúng `(m, leap)`.

**Fixture này chứng minh port == reference, KHÔNG chứng minh reference == lịch chính thức** (cùng một thuật toán).
Kiểm chứng độc lập: các mốc dưới đây là ngày Tết / tháng nhuận đã biết rộng rãi, fixture khớp toàn bộ:

| Năm | Tết (VN) | Nhuận | Ghi chú |
|---|---|---|---|
| 1968 | 1968-01-29 | 7 | TQ ăn Tết 30/1 — lệch 1 ngày |
| 1985 | 1985-01-21 | 2 | TQ ăn Tết 20/2 — lệch cả tháng (case nổi tiếng) |
| 2007 | 2007-02-17 | — | TQ 18/2 — lệch 1 ngày |
| 2014 | 2014-01-31 | 9 | |
| 2017 | 2017-01-28 | 6 | |
| 2020 | 2020-01-25 | 4 | |
| 2023 | 2023-01-22 | 2 | |
| 2024 | 2024-02-10 | — | |
| 2025 | 2025-01-29 | 6 | |
| 2026 | 2026-02-17 | — | |
| 2027 | 2027-02-06 | — | |
| 2028 | 2028-01-26 | 5 | |
| 2029 | 2029-02-13 | — | |
| 2030 | 2030-02-02 | — | |
| 2033 | 2033-01-31 | 11 | năm "2033 problem", nhuận 11 |

Muốn chắc hơn: user đối chiếu thêm vài năm ngẫu nhiên với lịch in của Ban Lịch Nhà nước (Viện Hàn lâm KHCN VN)
rồi thêm vào bảng trên. Agent không tự thêm dòng vào bảng này.

## Sinh lại fixture
Chỉ khi đổi `amlich-aa98.js` (không nên). `node tools/gen_fixture.js` → ghi đè `tet_1900_2100.json`.
