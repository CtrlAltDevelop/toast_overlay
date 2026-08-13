import 'package:flutter/material.dart';

import '../toast_config.dart';
import '../toast_strings.dart';
import 'toast_card.dart';

/// Owns the show/dismiss animations and the auto-dismiss timer for one toast.
class ToastOverlayEntry extends StatefulWidget {
  const ToastOverlayEntry({
    super.key,
    required this.config,
    required this.strings,
    required this.onDismissed,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.anchored = true,
  });

  /// A toast that is laid out by a [ToastStack] instead of anchoring itself to
  /// a screen edge.
  const ToastOverlayEntry.stacked({
    super.key,
    required this.config,
    required this.strings,
    required this.onDismissed,
    this.transitionDuration = const Duration(milliseconds: 300),
  }) : anchored = false;

  final ToastConfig config;
  final ToastStrings strings;

  /// Whether this entry positions itself against the screen edge. False when a
  /// [ToastStack] owns the layout.
  final bool anchored;

  /// Called once the exit animation has finished.
  final VoidCallback onDismissed;

  final Duration transitionDuration;

  @override
  State<ToastOverlayEntry> createState() => _ToastOverlayEntryState();
}

class _ToastOverlayEntryState extends State<ToastOverlayEntry>
    with TickerProviderStateMixin {
  late final AnimationController _show;
  AnimationController? _timer;

  @override
  void initState() {
    super.initState();
    _show = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    )..forward();

    final duration = widget.config.duration;
    if (duration != null) {
      _timer = AnimationController(vsync: this, duration: duration)
        ..addStatusListener(_onTimerStatus)
        ..forward();
    }
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _dismiss();
  }

  void _dismiss() {
    // The timer can complete after the overlay has already been removed and
    // disposed; touching the controller then throws.
    if (!mounted) return;
    if (_show.status == AnimationStatus.dismissed) return;
    _show.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.removeStatusListener(_onTimerStatus);
    _timer?.dispose();
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.config.position.isTop;

    final card = RepaintBoundary(
      child: ToastCard(
        config: widget.config,
        strings: widget.strings,
        animation: _show.view,
        timerAnimation: _timer?.view,
        onDismiss: _dismiss,
      ),
    );

    // Inside a stack the host already supplies the Material and the SafeArea,
    // and lays the cards out in a column.
    if (!widget.anchored) return card;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: isTop,
          bottom: !isTop,
          child: card,
        ),
      ),
    );
  }
}
