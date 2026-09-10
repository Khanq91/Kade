/// Text UI tiếng Việt có dấu, gom 1 chỗ (chưa i18n) — AGENTS.md §7.
abstract final class Strings {
  static const appName = 'Kade';

  // Bottom nav
  static const navCalendar = 'Lịch';
  static const navUpcoming = 'Sắp tới';
  static const navConvert = 'Đổi ngày';
  static const navSettings = 'Cài đặt';

  // Sắp tới
  static const upcomingTitle = 'Sắp tới';
  static const tomorrow = 'Ngày mai';
  static const noUpcoming = 'Không có sự kiện trong 60 ngày tới';
  static const layerPersonal = 'Cá nhân';
  static const layersLabel = 'Lớp hiển thị';

  /// "Còn 5 ngày".
  static String inDays(int n) => 'Còn $n ngày';

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

  // Sự kiện cá nhân
  static const personalEvents = 'Sự kiện cá nhân';
  static const myEvents = 'Sự kiện của tôi';
  static const myEventsHint =
      'Ngày giỗ, sinh nhật, kỷ niệm… theo âm hoặc dương lịch';
  static const addEvent = 'Thêm sự kiện';
  static const newEvent = 'Sự kiện mới';
  static const editEvent = 'Sửa sự kiện';
  static const noUserEvents = 'Chưa có sự kiện nào';
  static const titleField = 'Tên sự kiện';
  static const titleRequired = 'Nhập tên sự kiện';
  static const solarType = 'Dương lịch';
  static const lunarType = 'Âm lịch';
  static const yearly = 'Lặp hàng năm';
  static const everyYear = 'hàng năm';
  static const durationField = 'Số ngày';
  static const leapRuleLabel = 'Năm có tháng nhuận trùng tháng';
  static const leapFirst = 'Tháng chính';
  static const leapSecond = 'Tháng nhuận';
  static const leapBoth = 'Cả hai';
  static const noteField = 'Ghi chú';
  static const colorLabel = 'Màu';
  static const save = 'Lưu';
  static const delete = 'Xóa';
  static const deleteEventTitle = 'Xóa sự kiện?';
  static const invalidEventDate = 'Ngày/tháng không hợp lệ';
  static const eventDateMissing = 'Ngày này không tồn tại trong năm đã chọn';

  /// '"Giỗ ông" sẽ bị xóa khỏi lịch.'
  static String deleteEventBody(String title) =>
      '"$title" sẽ bị xóa khỏi lịch.';

  /// "3 ngày".
  static String daysCount(int n) => '$n ngày';

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

  // Sao lưu (Export/Import JSON, plan §5.1)
  static const backupSection = 'Sao lưu';
  static const backupHint =
      'Xuất sự kiện cá nhân ra file JSON để giữ hoặc chuyển máy; nhập lại từ file đã xuất.';
  static const exportJson = 'Xuất file JSON';
  static const importJson = 'Nhập file JSON';
  static const importButton = 'Nhập';
  static const importConfirmBody = 'Sự kiện trùng id sẽ bị ghi đè.';
  static const backupInvalidJson = 'File không phải JSON hợp lệ';
  static const backupBadFile =
      'File không đúng định dạng Kade (thiếu danh sách sự kiện)';
  static const exportFailed = 'Không xuất được file';
  static const importFailed = 'Không đọc được file';

  /// "Đã xuất 3 sự kiện".
  static String exported(int n) => 'Đã xuất $n sự kiện';

  /// "Đã nhập 3 sự kiện".
  static String imported(int n) => 'Đã nhập $n sự kiện';

  /// "Nhập 3 sự kiện từ file?".
  static String importConfirmTitle(int n) => 'Nhập $n sự kiện từ file?';

  /// "File có phiên bản 2, app chỉ đọc được phiên bản 1".
  static String backupUnsupportedSchema(int found, int supported) =>
      'File có phiên bản $found, app chỉ đọc được phiên bản $supported';
}
