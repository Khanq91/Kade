// Giờ hoàng đạo (theo chi ngày) và ngày hoàng đạo / hắc đạo (theo chi tháng ×
// chi ngày). Cả hai bảng đều là vòng 12 thần: Thanh Long, Minh Đường, Thiên
// Hình, Chu Tước, Kim Quỹ, Kim Đường, Bạch Hổ, Ngọc Đường, Thiên Lao, Nguyên
// Vũ, Tư Mệnh, Câu Trận — 6 thần hoàng đạo: Thanh Long, Minh Đường, Kim Quỹ,
// Kim Đường, Ngọc Đường, Tư Mệnh.
// Bảng giờ theo Hồ Ngọc Đức (GIO_HD trong amlich.js bản web). Bảng ngày: Thanh
// Long khởi tại Tý cho tháng Dần (Giêng), mỗi tháng tiến 2 chi (Dần→Tý, Mão→Dần,
// Thìn→Thìn, Tỵ→Ngọ, Ngọ→Thân, Mùi→Tuất, rồi lặp).
// Chưa được user đối chiếu lịch vạn niên → chưa có test giá trị cố định.
import 'can_chi.dart';

/// 12 thần theo thứ tự vòng, bắt đầu Thanh Long.
const List<String> thanNames = [
  'Thanh Long',
  'Minh Đường',
  'Thiên Hình',
  'Chu Tước',
  'Kim Quỹ',
  'Kim Đường',
  'Bạch Hổ',
  'Ngọc Đường',
  'Thiên Lao',
  'Nguyên Vũ',
  'Tư Mệnh',
  'Câu Trận',
];

/// `true` tại vị trí thần hoàng đạo trong [thanNames].
const List<bool> thanIsHoangDao = [
  true, // Thanh Long
  true, // Minh Đường
  false, // Thiên Hình
  false, // Chu Tước
  true, // Kim Quỹ
  true, // Kim Đường
  false, // Bạch Hổ
  true, // Ngọc Đường
  false, // Thiên Lao
  false, // Nguyên Vũ
  true, // Tư Mệnh
  false, // Câu Trận
];

/// Bảng giờ hoàng đạo: dòng = chi NGÀY (Tý = 0), ký tự thứ i = '1' nếu giờ chi i
/// là hoàng đạo (i: 0 Tý 23–1h, 1 Sửu 1–3h, 2 Dần 3–5h, ... 11 Hợi 21–23h).
const List<String> gioHoangDaoTable = [
  '110100101100', // ngày Tý:   Tý, Sửu, Mão, Ngọ, Thân, Dậu
  '001101001011', // ngày Sửu:  Dần, Mão, Tỵ, Thân, Tuất, Hợi
  '110011010010', // ngày Dần:  Tý, Sửu, Thìn, Tỵ, Mùi, Tuất
  '101100110100', // ngày Mão:  Tý, Dần, Mão, Ngọ, Mùi, Dậu
  '001011001101', // ngày Thìn: Dần, Thìn, Tỵ, Thân, Dậu, Hợi
  '010010110011', // ngày Tỵ:   Sửu, Thìn, Ngọ, Mùi, Tuất, Hợi
  '110100101100', // ngày Ngọ:  như Tý
  '001101001011', // ngày Mùi:  như Sửu
  '110011010010', // ngày Thân: như Dần
  '101100110100', // ngày Dậu:  như Mão
  '001011001101', // ngày Tuất: như Thìn
  '010010110011', // ngày Hợi:  như Tỵ
];

/// Bảng ngày hoàng đạo: dòng = chi THÁNG (Tý = 0), ký tự thứ d = '1' nếu ngày
/// chi d là hoàng đạo.
const List<String> ngayHoangDaoTable = [
  '110100101100', // tháng Tý (11):    Tý, Sửu, Mão, Ngọ, Thân, Dậu
  '001101001011', // tháng Sửu (12):   Dần, Mão, Tỵ, Thân, Tuất, Hợi
  '110011010010', // tháng Dần (Giêng): Tý, Sửu, Thìn, Tỵ, Mùi, Tuất
  '101100110100', // tháng Mão (2):    Tý, Dần, Mão, Ngọ, Mùi, Dậu
  '001011001101', // tháng Thìn (3):   Dần, Thìn, Tỵ, Thân, Dậu, Hợi
  '010010110011', // tháng Tỵ (4):     Sửu, Thìn, Ngọ, Mùi, Tuất, Hợi
  '110100101100', // tháng Ngọ (5):    như Tý
  '001101001011', // tháng Mùi (6):    như Sửu
  '110011010010', // tháng Thân (7):   như Dần
  '101100110100', // tháng Dậu (8):    như Mão
  '001011001101', // tháng Tuất (9):   như Thìn
  '010010110011', // tháng Hợi (10):   như Tỵ
];

/// 6 giờ hoàng đạo của ngày có chi [dayChi] (Tý = 0), dạng "Tý (23-1)".
List<String> gioHoangDao(int dayChi) {
  final row = gioHoangDaoTable[dayChi];
  return [
    for (var i = 0; i < 12; i++)
      if (row[i] == '1') '${chi[i]} (${(i * 2 + 23) % 24}-${(i * 2 + 1) % 24})',
  ];
}

/// Ngày chi [dayChi] trong tháng chi [monthChi] có phải hoàng đạo không.
bool isNgayHoangDao(int monthChi, int dayChi) =>
    ngayHoangDaoTable[monthChi][dayChi] == '1';

/// Chỉ số chi ngày có Thanh Long trong tháng chi [monthChi]: Dần → Tý, mỗi tháng +2.
int thanhLongChi(int monthChi) => (2 * monthChi - 4) % 12;

/// Tên thần (trong 12 thần) của ngày chi [dayChi] trong tháng chi [monthChi].
String thanOfDay(int monthChi, int dayChi) =>
    thanNames[(dayChi - thanhLongChi(monthChi)) % 12];
