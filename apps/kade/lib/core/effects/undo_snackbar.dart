// Port từ Snipz/undo_snackbar: spring vào/ra và progress line đếm ngược.
import 'package:flutter/widgets.dart';

/// Thanh hoàn tác có thời hạn; tăng [requestId] để hiện/retrigger.
class UndoSnackbar extends StatefulWidget {
  const UndoSnackbar({
    super.key,
    required this.requestId,
    required this.message,
    required this.undoLabel,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    this.undoDuration = const Duration(milliseconds: 3000),
    this.onUndo,
    this.onDismissed,
  });

  final int requestId;
  final String message;
  final String undoLabel;
  final Duration undoDuration;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback? onUndo;
  final VoidCallback? onDismissed;

  @override
  State<UndoSnackbar> createState() => _UndoSnackbarState();
}

class _UndoSnackbarState extends State<UndoSnackbar>
    with SingleTickerProviderStateMixin {
  static const _spring = Cubic(.34, 1.56, .64, 1);
  late final AnimationController _life;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: widget.undoDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      });
    if (widget.requestId != 0) _show();
  }

  @override
  void didUpdateWidget(UndoSnackbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.undoDuration != widget.undoDuration) {
      _life.duration = widget.undoDuration;
    }
    if (oldWidget.requestId != widget.requestId) _show();
  }

  void _show() {
    if (!_shown) setState(() => _shown = true);
    _life.forward(from: 0);
  }

  void _undo() {
    widget.onUndo?.call();
    _dismiss();
  }

  void _dismiss() {
    if (!_shown) return;
    _life.stop();
    setState(() => _shown = false);
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return ClipRect(
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 1.4),
        duration: motion ? const Duration(milliseconds: 400) : Duration.zero,
        curve: _spring,
        onEnd: () {
          if (!_shown) widget.onDismissed?.call();
        },
        child: Semantics(
          liveRegion: true,
          label: widget.message,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _undo,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              widget.undoLabel,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 2,
                  child: AnimatedBuilder(
                    animation: _life,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1 - _life.value,
                      child: ColoredBox(color: widget.accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
