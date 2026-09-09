# Prompt kickoff — Phase 0

Copy từng khối, giao lần lượt. Đợi xong + verify pass mới giao khối tiếp.

## Bước 1
```
Đọc AGENTS.md rồi làm theo mục 2 (đọc .memory). Sau đó làm Phase 0 bước 1 trong docs/plan.md §6:

1. Init repo: pub workspace ở root (packages/*, apps/*), .gitignore Flutter/Dart, chưa tạo apps/kade.
2. Tạo packages/lunar_core (pure Dart, zero deps). Port docs/reference/amlich-aa98.js sang Dart,
   giữ tên hàm để đối chiếu; API public theo docs/plan.md §2.1 (DayInfo chưa cần đủ field —
   bước này chỉ cần LunarDate + solarToLunar/lunarToSolar, timeZone mặc định 7).
3. Test: packages/lunar_core/test/fixture_test.dart đọc docs/reference/tet_1900_2100.json và kiểm tra
   toàn bộ 1900–2100 theo mô tả trong docs/reference/README.md (Tết, từng tháng: start/days/leap,
   và solarToLunar cho mọi ngày trong năm). Thêm test hai chiều: lunarToSolar(solarToLunar(d)) == d
   cho mọi ngày 1900–2100.
4. Chạy dart test đến khi pass. Commit "phase0-step1: lunar_core port + fixture test".
5. Cập nhật .memory/PROGRESS.md (bước 1 ✅, log). Ghi DECISIONS/ERRORS nếu có gì đáng ghi theo AGENTS.md §4.

Không làm bước 2–3. Không tạo Flutter app.
```

## Bước 2
```
Đọc AGENTS.md, .memory. Làm Phase 0 bước 2: thêm vào lunar_core
- can chi năm/tháng/ngày/giờ (từ JD, công thức mod 10/12; tháng theo can của năm),
- 24 tiết khí: hàm tietKhiOf(date) trả tên tiết khí nếu ngày đó bắt đầu tiết khí (kinh độ MT chia 15°, múi giờ 7),
- giờ hoàng đạo theo chi ngày (bảng 12 dòng),
- ngày hoàng đạo/hắc đạo theo chi tháng × chi ngày (bảng 12x12).
Điền đủ DayInfo theo docs/plan.md §2.1. Test: cố định 10 ngày do bạn chọn, in kết quả ra để tôi đối chiếu
với lịch vạn niên rồi mới chốt fixture (không tự khẳng định đúng). Sau khi tôi xác nhận → viết test cố định.
Commit "phase0-step2: can chi, tiết khí, hoàng đạo". Cập nhật .memory.
```

## Bước 3
```
Đọc AGENTS.md, .memory. Làm Phase 0 bước 3: tools/gen_lunar_table.dart sinh
packages/lunar_core/lib/src/table_1900_2100.dart (const) từ thuật toán runtime; test table == runtime cho mọi ngày.
Quyết định và ghi DECISIONS: runtime dùng bảng hay tính trực tiếp (đề xuất: bảng nếu năm trong 1900–2100, fallback tính).
Commit "phase0-step3: lunar table". Cập nhật .memory.
```

## Template cho các phase sau
```
Đọc AGENTS.md rồi .memory theo thứ tự. Làm Phase {N} bước {M} trong docs/plan.md §6, tiêu chí verify ở §{4.8|5.7}.
Chỉ bước này. Xong → verify → commit "phase{N}-step{M}: ..." → cập nhật .memory.
Nếu cần tôi làm gì (Google Cloud, thiết bị thật) → ghi vào PROGRESS "Cần user làm" và dừng.
```
