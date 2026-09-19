import 'package:material_ui/material_ui.dart' show kToolbarHeight;
import 'package:flutter/widgets.dart';

import 'toast_action.dart';
import 'toast_config.dart';
import 'toast_enums.dart';
import 'toast_history.dart';
import 'toast_strings.dart';
import 'widgets/toast_stack.dart';

/// Shows toasts in an [Overlay].
///
/// Create one and hold it wherever you keep app-wide services, or use the
/// [Toast] static facade if a single global instance is enough.
class ToastController {
  ToastController({
    required this.overlayResolver,
    this.strings = const ToastStrings(),
    this.stringsBuilder,
    this.logger,
    this.maxStack = 1,
    this.stackSpacing = 8,
    ToastHistory? history,
  }) : assert(maxStack >= 1, 'maxStack must be at least 1'),
       history = history ?? ToastHistory();

  /// Resolves the overlay to insert into. Returning null makes [show] a no-op,
  /// which is what you want when no route is mounted yet.
  final OverlayState? Function() overlayResolver;

  /// Static strings, used when [stringsBuilder] is null.
  final ToastStrings strings;

  /// Resolves strings against the toast's own [BuildContext], so they follow
  /// the app's current locale.
  ///
  /// Prefer this over [strings] in a localised app: a controller is usually
  /// created before `runApp`, where no localisations exist yet, and fixed
  /// strings would then never update when the user changes language.
  ///
  /// ```dart
  /// stringsBuilder: (context) {
  ///   final l10n = AppLocalizations.of(context)!;
  ///   return ToastStrings(error: l10n.toastTypeError, /* … */);
  /// },
  /// ```
  final ToastStrings Function(BuildContext context)? stringsBuilder;

  /// Called for every toast shown. Use it to forward to your own logging.
  final ToastLogger? logger;

  /// How many toasts may share the screen.
  ///
  /// The default of 1 replaces the toast on screen with each new one. Raise it
  /// and the toasts stack against their edge instead — a third toast with
  /// `maxStack: 2` pushes the oldest one out.
  final int maxStack;

  /// Gap between two stacked cards. Unused when [maxStack] is 1.
  final double stackSpacing;

  /// The most recent toasts, for a debug screen.
  final ToastHistory history;

  OverlayEntry? _entry;
  final List<StackedToast> _stack = [];
  final Set<Object> _dismissing = {};
  int _nextId = 0;

  /// Whether a toast is currently on screen.
  bool get isShowing => _entry != null;

  /// How many toasts are on screen. Never more than [maxStack].
  int get visibleCount => _stack.length;

  /// Shows [config].
  ///
  /// With the default [maxStack] of 1 this replaces the toast on screen;
  /// otherwise the toast joins the stack and the oldest one is dropped once
  /// [maxStack] is exceeded.
  ///
  /// A toast carrying a reference id never auto-dismisses: the user needs time
  /// to copy it, so only the close button removes it.
  ///
  /// Returns the toast's id, which [dismissToast] takes to remove that one
  /// toast. The id is still returned when no overlay was available and nothing
  /// was shown; dismissing it is then a no-op.
  Object show(ToastConfig config) {
    final effective = config.hasReferenceId
        ? config.copyWith(clearDuration: true)
        : config;

    final entry =
        '${ToastHistory.timestamp()} '
        '[${effective.status.shortName}] ${effective.title}'
        '${effective.hasSubtitle ? ' — ${effective.subtitle}' : ''}';
    history.add(entry);
    logger?.call(entry);

    final id = _nextId++;
    final overlay = overlayResolver();
    if (overlay == null) return id;

    if (maxStack == 1) _stack.clear();
    _stack.add(StackedToast(id: id, config: effective));
    // Oldest first, so anything over the limit falls off the front.
    if (_stack.length > maxStack) {
      _stack.removeRange(0, _stack.length - maxStack);
    }

    final overlayEntry = _entry;
    if (overlayEntry == null) {
      final created = OverlayEntry(builder: _buildStack);
      _entry = created;
      overlay.insert(created);
    } else {
      overlayEntry.markNeedsBuild();
    }

    return id;
  }

  Widget _buildStack(BuildContext context) => ToastStack(
    toasts: List.unmodifiable(_stack),
    dismissing: Set.unmodifiable(_dismissing),
    spacing: stackSpacing,
    strings: (context) => stringsBuilder?.call(context) ?? strings,
    onDismissed: _removeById,
  );

  void _removeById(Object id) {
    _stack.removeWhere((toast) => toast.id == id);
    _dismissing.remove(id);
    if (_stack.isEmpty) {
      _remove();
    } else {
      _entry?.markNeedsBuild();
    }
  }

  /// Convenience wrapper around [show].
  Object showToast({
    required ToastStatus status,
    required String title,
    String? subtitle,
    String? referenceId,
    ToastAction? action,
    VoidCallback? onTap,
    ToastPosition position = ToastPosition.top,
    double offset = kToolbarHeight,
    Duration? duration = const Duration(seconds: 3),
    bool dismissible = true,
    bool pauseOnHover = true,
  }) => show(
    ToastConfig(
      status: status,
      title: title,
      subtitle: subtitle,
      referenceId: referenceId,
      action: action,
      onTap: onTap,
      position: position,
      offset: offset,
      duration: duration,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
    ),
  );

  /// Plays the exit animation on the toast [show] returned [id] for, leaving
  /// any others on screen. Unknown and already-dismissing ids are ignored.
  void dismissToast(Object id) {
    if (_dismissing.contains(id)) return;
    if (!_stack.any((toast) => toast.id == id)) return;
    _dismissing.add(id);
    _entry?.markNeedsBuild();
  }

  /// Plays the exit animation on every toast on screen. Each card removes
  /// itself once its animation finishes; use [dismiss] to cut them immediately.
  void dismissAll() {
    for (final toast in _stack.toList()) {
      dismissToast(toast.id);
    }
  }

  /// Removes every toast on screen immediately, without the exit animation.
  void dismiss() => _remove();

  void _remove() {
    _stack.clear();
    _dismissing.clear();
    _entry?.remove();
    _entry = null;
  }
}

/// A single app-wide [ToastController], for apps that want a global entry
/// point rather than injecting the controller.
///
/// ```dart
/// Toast.init(navigatorKey: navigatorKey);
/// Toast.show(status: ToastStatus.success, title: 'Saved');
/// ```
abstract final class Toast {
  static ToastController? _controller;

  static const _notInitialized =
      'Toast is not initialized. Call Toast.init() before showing a toast.';

  /// The controller [init] created. Throws if [init] has not been called.
  static ToastController get instance {
    final controller = _controller;
    if (controller == null) throw StateError(_notInitialized);
    return controller;
  }

  static bool get isInitialized => _controller != null;

  /// Wires the facade to the app's root navigator.
  static void init({
    required GlobalKey<NavigatorState> navigatorKey,
    ToastStrings strings = const ToastStrings(),
    ToastStrings Function(BuildContext context)? stringsBuilder,
    ToastLogger? logger,
    int maxStack = 1,
    double stackSpacing = 8,
    ToastHistory? history,
  }) {
    _controller = ToastController(
      overlayResolver: () => navigatorKey.currentState?.overlay,
      strings: strings,
      stringsBuilder: stringsBuilder,
      logger: logger,
      maxStack: maxStack,
      stackSpacing: stackSpacing,
      history: history,
    );
  }

  /// Wires the facade to an explicit controller, which is what tests want.
  static void initWith(ToastController controller) => _controller = controller;

  /// Clears the facade. Call between tests to avoid leaking state.
  static void reset() {
    _controller?.dismiss();
    _controller = null;
  }

  /// The most recent toasts, for a debug screen.
  static ToastHistory get history => instance.history;

  static Object show({
    required ToastStatus status,
    required String title,
    String? subtitle,
    String? referenceId,
    ToastAction? action,
    VoidCallback? onTap,
    ToastPosition position = ToastPosition.top,
    double offset = kToolbarHeight,
    Duration? duration = const Duration(seconds: 3),
    bool dismissible = true,
    bool pauseOnHover = true,
  }) => instance.showToast(
    status: status,
    title: title,
    subtitle: subtitle,
    referenceId: referenceId,
    action: action,
    onTap: onTap,
    position: position,
    offset: offset,
    duration: duration,
    dismissible: dismissible,
    pauseOnHover: pauseOnHover,
  );

  /// Plays the exit animation on the toast [show] returned [id] for.
  static void dismissToast(Object id) => instance.dismissToast(id);

  /// Plays the exit animation on every toast on screen.
  static void dismissAll() => instance.dismissAll();

  /// Removes every toast on screen immediately, without the exit animation.
  static void dismiss() => instance.dismiss();
}
