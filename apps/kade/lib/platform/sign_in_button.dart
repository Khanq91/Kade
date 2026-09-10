// Nút đăng nhập Google do GIS vẽ (web): google_sign_in_web không hỗ trợ
// `authenticate()`, bắt buộc dùng nút này (E003). Conditional import (plan
// §4.7): ngoài web là stub, không bao giờ hiện vì `supportsAuthenticate`.
export 'sign_in_button_stub.dart'
    if (dart.library.js_interop) 'sign_in_button_web.dart';
