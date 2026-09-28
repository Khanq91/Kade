import 'package:flutter/material.dart';

import '../breakpoints.dart';
import '../strings.dart';
import '../theme/kade_theme_extension.dart';
import 'notification_slide_in.dart';
import 'undo_snackbar.dart';

/// Mức thông báo; màu dot là dấu hiệu phân biệt, nội dung và layout giữ đồng bộ.
enum KadeNoticeKind { success, info, warning, error }

/// Host feedback duy nhất, đặt phía trên router để thông báo sống qua đổi route.
class KadeFeedbackHost extends StatefulWidget {
  const KadeFeedbackHost({super.key, required this.child});

  final Widget child;

  static KadeFeedbackHostState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FeedbackScope>();
    assert(
      scope != null,
      'KadeFeedbackHost chưa được gắn ở MaterialApp.builder',
    );
    return scope!.state;
  }

  @override
  State<KadeFeedbackHost> createState() => KadeFeedbackHostState();
}

class KadeFeedbackHostState extends State<KadeFeedbackHost> {
  int _noticeRequest = 0;
  String _noticeMessage = '';
  KadeNoticeKind _noticeKind = KadeNoticeKind.info;
  int _undoRequest = 0;
  String _undoMessage = '';
  VoidCallback? _undoAction;

  void showNotice(String message, {KadeNoticeKind kind = KadeNoticeKind.info}) {
    setState(() {
      _noticeMessage = message;
      _noticeKind = kind;
      _noticeRequest++;
    });
  }

  void showUndo({required String message, required VoidCallback onUndo}) {
    setState(() {
      _undoMessage = message;
      _undoAction = onUndo;
      _undoRequest++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KadeColors>()!;
    final compact =
        layoutOf(MediaQuery.sizeOf(context).width) == AppLayout.compact;
    final dotColor = switch (_noticeKind) {
      KadeNoticeKind.success => colors.b,
      KadeNoticeKind.info => colors.ac,
      KadeNoticeKind.warning => colors.sun,
      KadeNoticeKind.error => colors.offT,
    };
    return _FeedbackScope(
      state: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: NotificationSlideIn(
                      key: const ValueKey('kade-notification-slide-in'),
                      requestId: _noticeRequest,
                      message: _noticeMessage,
                      dotColor: dotColor,
                      backgroundColor: colors.sf,
                      borderColor: colors.line,
                      textColor: colors.tx,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: compact ? 84 : 16,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: UndoSnackbar(
                    key: const ValueKey('kade-undo-snackbar'),
                    requestId: _undoRequest,
                    message: _undoMessage,
                    undoLabel: Strings.undo,
                    backgroundColor: colors.sf,
                    borderColor: colors.line,
                    textColor: colors.tx,
                    accentColor: colors.acT,
                    onUndo: _undoAction,
                    onDismissed: () => _undoAction = null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackScope extends InheritedWidget {
  const _FeedbackScope({required this.state, required super.child});

  final KadeFeedbackHostState state;

  @override
  bool updateShouldNotify(_FeedbackScope oldWidget) => false;
}

/// Hiện notification slide-in gần nhất từ mọi màn hình/route.
void showKadeNotice(
  BuildContext context,
  String message, {
  KadeNoticeKind kind = KadeNoticeKind.info,
}) => KadeFeedbackHost.of(context).showNotice(message, kind: kind);
