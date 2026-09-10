/// Text UI tiếng Việt có dấu, gom 1 chỗ (chưa i18n) — AGENTS.md §7.
abstract final class Strings {
  static const appName = 'Kade';

  // Bottom nav
  static const navCalendar = 'Lịch';
  static const navConvert = 'Đổi ngày';
  static const navSettings = 'Cài đặt';

  // Chung
  static const cancel = 'Hủy';
  static const back = 'Quay lại';
  static const lunarTag = 'ÂL';
  static const solarTag = 'DL';
  static const tagLegend = 'ÂL = âm lịch · DL = dương lịch · N = tháng nhuận';
  static const leap = 'nhuận';
  static const kindHoliday = 'Nghỉ lễ';
  static const kindMemorial = 'Kỷ niệm';
  static const kindInternational = 'Quốc tế';
  static const offDay = 'Ngày nghỉ';
  static const weekdaysShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật',
  ];
  static const lunarMonthNames = [
    'Giêng',
    'Hai',
    'Ba',
    'Tư',
    'Năm',
    'Sáu',
    'Bảy',
    'Tám',
    'Chín',
    'Mười',
    'Mười một',
    'Chạp',
  ];

  // MonthView
  static const today = 'Hôm nay';
  static const lunarMonthButton = 'Tháng âm';
  static const prevMonth = 'Tháng trước';
  static const nextMonth = 'Tháng sau';
  static const prevYear = 'Năm trước';
  static const nextYear = 'Năm sau';
  static const pickMonth = 'Chọn tháng dương';
  static const pickLunarMonth = 'Chọn tháng âm';
  static const noLeapMonthThisYear = 'Năm này không có tháng nhuận';

  /// "Tháng 2/2027".
  static String monthTitle(int month, int year) => 'Tháng $month/$year';

  /// "Tháng Giêng Đinh Mùi" / "Tháng Sáu nhuận Ất Tỵ".
  static String lunarMonthTitle(int month, bool isLeap, String canChiYear) =>
      'Tháng ${lunarMonthNames[month - 1]}${isLeap ? ' $leap' : ''} $canChiYear';

  /// Nút tháng trong picker âm: "Giêng" / "Sáu nhuận".
  static String lunarMonthLabel(int month, bool isLeap) =>
      '${lunarMonthNames[month - 1]}${isLeap ? ' $leap' : ''}';

  // DayDetail
  static const lunarLabel = 'Âm lịch';
  static const yearLabel = 'Năm';
  static const canChiMonthLabel = 'Tháng';
  static const canChiDayLabel = 'Ngày';
  static const tietKhiLabel = 'Tiết khí';
  static const hoangDaoDay = 'Ngày hoàng đạo';
  static const hacDaoDay = 'Ngày hắc đạo';
  static const gioHoangDaoLabel = 'Giờ hoàng đạo';
  static const eventsTitle = 'Sự kiện';
  static const noEvents = 'Không có sự kiện';
  static const prevDay = 'Hôm trước';
  static const nextDay = 'Hôm sau';

  // Converter
  static const convertTitle = 'Đổi ngày';
  static const solarToLunarTitle = 'Dương → Âm';
  static const lunarToSolarTitle = 'Âm → Dương';
  static const pickSolarDate = 'Chọn ngày dương';
  static const dayField = 'Ngày';
  static const monthField = 'Tháng';
  static const yearField = 'Năm';
  static const leapCheckbox = 'Tháng nhuận';
  static const convertButton = 'Đổi';
  static const solarResult = 'Dương lịch';
  static const lunarResult = 'Âm lịch';
  static const invalidInput = 'Nhập ngày (1–30), tháng (1–12) và năm là số';

  /// "Năm 2027 không có tháng 5 nhuận".
  static String noLeapMonth(int month, int year) =>
      'Năm $year không có tháng $month nhuận';

  /// "Ngày 30/2/2027 âm lịch không tồn tại".
  static String lunarDateMissing(int day, int month, int year, bool isLeap) =>
      'Ngày $day/$month${isLeap ? ' $leap' : ''}/$year âm lịch không tồn tại';

  // Settings
  static const settingsTitle = 'Cài đặt';
  static const remoteConfigSection = 'Lịch nghỉ bù theo năm';
  static const remoteConfigHint =
      'Ngày nghỉ thêm / làm bù do Nhà nước công bố từng năm, tải từ Google Sheet.';
  static const checkUpdates = 'Kiểm tra cập nhật';
  static const checking = 'Đang kiểm tra…';
  static const sourceLabel = 'Nguồn dữ liệu';
  static const sourceNone = 'Chưa có dữ liệu';
  static const sourceAsset = 'Mặc định kèm app';
  static const sourceCache = 'Đã lưu trên máy';
  static const sourceRemote = 'Vừa tải từ Google Sheet';
  static const versionLabel = 'Phiên bản';
  static const updatedAtLabel = 'Sheet sửa lúc';
  static const fetchedAtLabel = 'Kiểm tra lần cuối';
  static const never = 'Chưa bao giờ';
  static const unknown = 'Không rõ';
  static const noConfigUrl =
      'Chưa cấu hình KADE_CONFIG_URL trong dart_defines.json — chỉ dùng dữ liệu mặc định.';
  static const fetchUpdated = 'Đã cập nhật lịch nghỉ mới';
  static const fetchUpToDate = 'Lịch nghỉ đã là mới nhất';
  static const fetchSkipped = 'Mới kiểm tra gần đây, bỏ qua';
  static const fetchFailed = 'Không tải được, giữ dữ liệu đã có';
  static const offDays = 'Nghỉ';
  static const workDays = 'Làm bù';
  static const noOverrides = 'Không có ngày nghỉ bù nào';
  static const loadError = 'Không đọc được dữ liệu';

  /// "Năm 2027".
  static String yearTitle(int year) => 'Năm $year';
}
