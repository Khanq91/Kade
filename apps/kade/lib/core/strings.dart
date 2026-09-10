/// Text UI tiếng Việt có dấu, gom 1 chỗ (chưa i18n) — AGENTS.md §7.
abstract final class Strings {
  static const appName = 'Kade';

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
