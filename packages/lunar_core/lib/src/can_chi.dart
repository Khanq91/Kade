// Can chi năm / tháng / ngày / giờ. Công thức mod 10 / mod 12 theo Hồ Ngọc Đức
// (amlich.js bản web): năm (y+6)%10, (y+8)%12; tháng (y*12+m+3)%10, (m+1)%12;
// ngày theo JD (jd+9)%10, (jd+1)%12; giờ Tý của ngày ((jd-1)*2)%10.
// Chưa được user đối chiếu lịch vạn niên → chưa có test giá trị cố định.

/// 10 thiên can, Giáp = 0.
const List<String> can = [
  'Giáp',
  'Ất',
  'Bính',
  'Đinh',
  'Mậu',
  'Kỷ',
  'Canh',
  'Tân',
  'Nhâm',
  'Quý',
];

/// 12 địa chi, Tý = 0.
const List<String> chi = [
  'Tý',
  'Sửu',
  'Dần',
  'Mão',
  'Thìn',
  'Tỵ',
  'Ngọ',
  'Mùi',
  'Thân',
  'Dậu',
  'Tuất',
  'Hợi',
];

/// Can chi của năm âm lịch, ví dụ 2024 → "Giáp Thìn".
String canChiYear(int lunarYear) =>
    '${can[(lunarYear + 6) % 10]} ${chi[(lunarYear + 8) % 12]}';

/// Chỉ số chi (Tý = 0) của tháng âm: tháng Giêng luôn là Dần (2).
int chiIndexOfMonth(int lunarMonth) => (lunarMonth + 1) % 12;

/// Can chi của tháng âm; can tháng suy từ năm (ngũ hổ độn). Tháng nhuận dùng
/// cùng can chi với tháng chính.
String canChiMonth(int lunarMonth, int lunarYear) =>
    '${can[(lunarYear * 12 + lunarMonth + 3) % 10]} '
    '${chi[chiIndexOfMonth(lunarMonth)]}';

/// Chỉ số chi (Tý = 0) của ngày có số ngày Julius [jd].
int chiIndexOfDay(int jd) => (jd + 1) % 12;

/// Can chi của ngày có số ngày Julius [jd], ví dụ jd 2451545 (1/1/2000) → "Mậu Ngọ".
String canChiDay(int jd) => '${can[(jd + 9) % 10]} ${chi[chiIndexOfDay(jd)]}';

/// Can chi của giờ thứ [chiIndex] (Tý = 0: 23h–1h, Sửu = 1: 1h–3h, ...) trong
/// ngày có số ngày Julius [jd]; can giờ Tý suy từ can ngày (ngũ thử độn).
String canChiHour(int jd, int chiIndex) =>
    '${can[((jd - 1) * 2 + chiIndex) % 10]} ${chi[chiIndex]}';
