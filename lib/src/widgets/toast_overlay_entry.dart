import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';

import '../toast_config.dart';
import '../toast_enums.dart';
import '../toast_strings.dart';
import 'toast_card.dart';

/// Owns the show/dismiss animations, the auto-dismiss timer and the swipe
/// gesture for one toast.
class ToastOverlayEntry extends StatefulWidget {
  const ToastOverlayEntry({
    super.key,
    required this.config,
    required this.strings,
    required this.onDismissed,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.dismissRequested = false,
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
    this.dismissRequested = false,
  }) : anchored = false;

  final ToastConfig config;
  final ToastStrings strings;

  /// Whether this entry positions itself against the screen edge. False when a
  /// [ToastStack] owns the layout.
  final bool anchored;

  /// Flipped to true by the host to ask this toast to play its exit animation
  /// — how [ToastController.dismissToast] reaches one card in a stack.
  final bool dismissRequested;

  /// Called once the exit animation has finished.
  final VoidCallback onDismissed;

  final Duration transitionDuration;

  @override
  State<ToastOverlayEntry> createState() => _ToastOverlayEntryState();
}

class _ToastOverlayEntryState extends State<ToastOverlayEntry>
    with TickerProviderStateMixin {
  /// How far the card has to be dragged, as a fraction of its own height,
  /// before letting go dismisses it.
  static const double _dismissFraction = 0.4;

  /// A flick this fast dismisses regardless of how far it travelled.
  static const double _dismissVelocity = 300;

  late final AnimationController _show;
  AnimationController? _timer;

  double _dragExtent = 0;
  double _cardHeight = 0;
  bool _dragging = false;

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

    if (widget.dismissRequested) _dismiss();

    // Announced rather than left to the traversal order: the toast is a live
    // region in an overlay, which a screen reader would otherwise reach only
    // if the user happened to swipe onto it before it auto-dismissed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void didUpdateWidget(ToastOverlayEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dismissRequested && !oldWidget.dismissRequested) _dismiss();
  }

  void _announce() {
    if (!mounted) return;
    // Android deprecated announcement events — TalkBack clears its queue for
    // them — so platforms that would rather read the live region are left to.
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    final config = widget.config;
    final title = config.title.isNotEmpty
        ? config.title
        : widget.strings.defaultTitle(config.status);
    final message = config.hasSubtitle ? '$title. ${config.subtitle}' : title;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.maybeOf(context) ?? TextDirection.ltr,
      assertiveness: config.status == ToastStatus.error
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );
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

  /// Stops the countdown while a pointer is over or on the card, and resumes it
  /// from where it stopped once the pointer leaves.
  void _pauseTimer() => _timer?.stop();

  void _resumeTimer() {
    if (_dragging) return;
    final timer = _timer;
    if (timer == null || timer.isAnimating || timer.value >= 1) return;
    timer.forward();
  }

  void _onTap() {
    widget.config.onTap?.call();
    _dismiss();
  }

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _pauseTimer();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Only towards the anchored edge: dragging a top toast downwards, back over
    // the app, would fight the scroll the user probably meant.
    final delta = details.primaryDelta ?? 0;
    final towardsEdge = widget.config.position.isTop ? -delta : delta;
    setState(() => _dragExtent = (_dragExtent + towardsEdge).clamp(0, 1000));
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final towardsEdge = widget.config.position.isTop ? -velocity : velocity;
    final travelled = _cardHeight > 0 ? _dragExtent / _cardHeight : 0;

    if (towardsEdge > _dismissVelocity || travelled > _dismissFraction) {
      _dismiss();
    } else {
      setState(() => _dragExtent = 0);
      _resumeTimer();
    }
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
    final config = widget.config;
    final isTop = config.position.isTop;

    Widget card = RepaintBoundary(
      child: ToastCard(
        config: config,
        strings: widget.strings,
        animation: _show.view,
        timerAnimation: _timer?.view,
        onDismiss: _dismiss,
        onTap: config.onTap == null ? null : _onTap,
      ),
    );

    if (config.duration != null && config.pauseOnHover) {
      card = MouseRegion(
        onEnter: (_) => _pauseTimer(),
        onExit: (_) => _resumeTimer(),
        child: card,
      );
    }

    if (config.dismissible) {
      card = GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // The drag would otherwise merge the whole card into one semantics
        // node and offer a screen reader a scroll it cannot use; the close
        // button is the accessible way out.
        excludeFromSemantics: true,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: _SizeReporter(
          onSize: (size) => _cardHeight = size.height,
          child: AnimatedSlide(
            offset: Offset(
              0,
              _cardHeight > 0
                  ? (isTop ? -_dragExtent : _dragExtent) / _cardHeight
                  : 0,
            ),
            duration: _dragging ? Duration.zero : widget.transitionDuration,
            curve: Curves.easeOut,
            child: card,
          ),
        ),
      );
    }

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

/// Reports its child's laid-out size, so the swipe can be measured against the
/// card's own height rather than a guess.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  _RenderSizeReporter createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter render) =>
      render.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      onSize(size);
    }
  }
}
