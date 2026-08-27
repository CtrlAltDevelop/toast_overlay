import 'package:flutter/foundation.dart';

/// An optional button on a toast — an `Undo`, a `Retry`, a `View`.
///
/// ```dart
/// Toast.show(
///   status: ToastStatus.info,
///   title: 'Message archived',
///   action: ToastAction(label: 'Undo', onPressed: restore),
/// );
/// ```
@immutable
class ToastAction {
  const ToastAction({
    required this.label,
    required this.onPressed,
    this.dismissOnPressed = true,
  });

  /// The button's text. Supply it already localised.
  final String label;

  final VoidCallback onPressed;

  /// Whether pressing the button also dismisses the toast. Leave it on unless
  /// the toast should stay up to report what the action did.
  final bool dismissOnPressed;

  @override
  bool operator ==(Object other) =>
      other is ToastAction &&
      other.label == label &&
      other.onPressed == onPressed &&
      other.dismissOnPressed == dismissOnPressed;

  @override
  int get hashCode => Object.hash(label, onPressed, dismissOnPressed);
}
