// Port từ Snipz/notification_slide_in, đổi bộ đếm vòng đời sang Timer để
// không giữ một animation ticker chạy suốt thời gian thông báo đứng yên.
import 'dart:async';

import 'package:flutter/widgets.dart';

/// Pill thông báo trượt từ mép trên, overshoot nhẹ rồi tự ẩn.
class NotificationSlideIn extends StatefulWidget {
  const NotificationSlideIn({
    super.key,
    required this.requestId,
    required this.message,
    required this.dotColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.displayDuration = const Duration(milliseconds: 2200),
    this.onDismissed,
  });

  final int requestId;
  final String message;
  final Color dotColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Duration displayDuration;
  final VoidCallback? onDismissed;

  @override
  State<NotificationSlideIn> createState() => _NotificationSlideInState();
}

class _NotificationSlideInState extends State<NotificationSlideIn> {
  static const _drop = Cubic(.18, 1.25, .4, 1);
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.requestId != 0) _show();
  }

  @override
  void didUpdateWidget(NotificationSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) _show();
  }

  void _show() {
    _timer?.cancel();
    if (!_shown) setState(() => _shown = true);
    _timer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (!_shown || !mounted) return;
    setState(() => _shown = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return ClipRect(
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, -1.6),
        duration: motion ? const Duration(milliseconds: 550) : Duration.zero,
        curve: _drop,
        onEnd: () {
          if (!_shown) widget.onDismissed?.call();
        },
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: motion ? const Duration(milliseconds: 300) : Duration.zero,
          child: Semantics(
            liveRegion: true,
            label: widget.message,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.dotColor,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
