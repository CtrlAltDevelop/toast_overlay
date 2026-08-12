import 'package:flutter/material.dart' show kToolbarHeight;
import 'package:flutter/widgets.dart';

import 'toast_config.dart';
import 'toast_enums.dart';
import 'toast_history.dart';
import 'toast_strings.dart';
import 'widgets/toast_overlay_entry.dart';

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
    ToastHistory? history,
  }) : history = history ?? ToastHistory();

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

  /// The most recent toasts, for a debug screen.
  final ToastHistory history;

  OverlayEntry? _entry;

  /// Whether a toast is currently on screen.
  bool get isShowing => _entry != null;

  /// Shows [config], replacing any toast already on screen.
  ///
  /// A toast carrying a reference id never auto-dismisses: the user needs time
  /// to copy it, so only the close button removes it.
  void show(ToastConfig config) {
    final effective =
        config.hasReferenceId ? config.copyWith(clearDuration: true) : config;

    final entry = '${ToastHistory.timestamp()} '
        '[${effective.status.shortName}] ${effective.title}'
        '${effective.hasSubtitle ? ' — ${effective.subtitle}' : ''}';
    history.add(entry);
    logger?.call(entry);

    final overlay = overlayResolver();
    if (overlay == null) return;

    dismiss();
    final overlayEntry = OverlayEntry(
      builder: (context) => ToastOverlayEntry(
        config: effective,
        strings: stringsBuilder?.call(context) ?? strings,
        onDismissed: _remove,
      ),
    );
    _entry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  /// Convenience wrapper around [show].
  void showToast({
    required ToastStatus status,
    required String title,
    String? subtitle,
    String? referenceId,
    ToastPosition position = ToastPosition.top,
    double offset = kToolbarHeight,
    Duration? duration = const Duration(seconds: 3),
  }) =>
      show(
        ToastConfig(
          status: status,
          title: title,
          subtitle: subtitle,
          referenceId: referenceId,
          position: position,
          offset: offset,
          duration: duration,
        ),
      );

  /// Removes the current toast immediately, without the exit animation.
  void dismiss() => _remove();

  void _remove() {
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
    ToastHistory? history,
  }) {
    _controller = ToastController(
      overlayResolver: () => navigatorKey.currentState?.overlay,
      strings: strings,
      stringsBuilder: stringsBuilder,
      logger: logger,
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

  static void show({
    required ToastStatus status,
    required String title,
    String? subtitle,
    String? referenceId,
    ToastPosition position = ToastPosition.top,
    double offset = kToolbarHeight,
    Duration? duration = const Duration(seconds: 3),
  }) =>
      instance.showToast(
        status: status,
        title: title,
        subtitle: subtitle,
        referenceId: referenceId,
        position: position,
        offset: offset,
        duration: duration,
      );

  static void dismiss() => instance.dismiss();
}
