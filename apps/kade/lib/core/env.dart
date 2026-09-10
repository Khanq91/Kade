import 'dart:developer';

/// Giá trị môi trường truyền qua `--dart-define-from-file=../../dart_defines.json`
/// (AGENTS.md §7, mẫu: `dart_defines.example.json`). Thiếu → tính năng tương ứng
/// tắt, app vẫn chạy.
abstract final class Env {
  /// URL Apps Script trả JSON nghỉ bù (docs/setup-google.md phần A).
  static const String configUrl = String.fromEnvironment('KADE_CONFIG_URL');

  /// OAuth Web Client ID cho Google Sign-In trên web (Phase 2).
  static const String webClientId = String.fromEnvironment(
    'KADE_WEB_CLIENT_ID',
  );

  /// Có Web Client ID (đăng nhập Google, Phase 2) không.
  static bool get hasWebClientId => webClientId.isNotEmpty;

  /// Có URL remote config không.
  static bool get hasConfigUrl => configUrl.isNotEmpty;

  /// Ghi cảnh báo cho giá trị thiếu; gọi 1 lần lúc khởi động.
  static void logMissing() {
    if (configUrl.isEmpty) {
      log(
        'KADE_CONFIG_URL trống → tắt remote config, dùng asset overrides.json',
        name: 'kade.env',
      );
    }
    if (webClientId.isEmpty) {
      log(
        'KADE_WEB_CLIENT_ID trống → tắt đăng nhập Google trên web (Phase 2)',
        name: 'kade.env',
      );
    }
  }
}
