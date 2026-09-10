import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Nút GIS "Tiếp tục với Google" (tiếng Việt); kết quả đăng nhập về qua
/// `GoogleSignIn.instance.authenticationEvents` → `GoogleAuth.userChanges`.
Widget googleSignInButton() => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    theme: web.GSIButtonTheme.filledBlue,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.continueWith,
    shape: web.GSIButtonShape.pill,
    locale: 'vi',
  ),
);
