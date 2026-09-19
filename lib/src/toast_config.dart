import 'package:flutter/widgets.dart';

import 'toast_action.dart';
import 'toast_enums.dart';

/// An immutable description of one toast.
@immutable
class ToastConfig {
  const ToastConfig({
    required this.status,
    required this.title,
    this.position = ToastPosition.top,
    this.subtitle,
    this.referenceId,
    this.action,
    this.onTap,
    this.offset = 0,
    this.duration = const Duration(seconds: 3),
    this.dismissible = true,
    this.pauseOnHover = true,
  });

  final ToastStatus status;

  /// Falls back to the status default title when empty.
  final String title;

  final ToastPosition position;
  final String? subtitle;

  /// A server-side reference id shown with a copy button, so the user can quote
  /// it to support. Hidden when null or empty.
  final String? referenceId;

  /// An optional button — `Undo`, `Retry` — shown under the text.
  final ToastAction? action;

  /// Called when the card itself is tapped. The toast is dismissed after.
  final VoidCallback? onTap;

  /// Distance from the anchored screen edge.
  final double offset;

  /// Auto-dismiss delay. Null keeps the toast up until dismissed manually.
  final Duration? duration;

  /// Whether the toast can be flicked away towards its anchored edge.
  final bool dismissible;

  /// Whether hovering the card pauses the auto-dismiss countdown, so a toast
  /// does not vanish out from under a pointer that is reading it. Desktop and
  /// web only — a touch pointer never generates a hover.
  final bool pauseOnHover;

  bool get hasReferenceId => referenceId != null && referenceId!.isNotEmpty;
  bool get hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  /// Whether the timer ring around the close button should be drawn.
  bool get isAutoDismissing => duration != null;

  ToastConfig copyWith({
    ToastStatus? status,
    String? title,
    ToastPosition? position,
    String? subtitle,
    String? referenceId,
    ToastAction? action,
    VoidCallback? onTap,
    double? offset,
    Duration? duration,
    bool clearDuration = false,
    bool? dismissible,
    bool? pauseOnHover,
  }) => ToastConfig(
    status: status ?? this.status,
    title: title ?? this.title,
    position: position ?? this.position,
    subtitle: subtitle ?? this.subtitle,
    referenceId: referenceId ?? this.referenceId,
    action: action ?? this.action,
    onTap: onTap ?? this.onTap,
    offset: offset ?? this.offset,
    duration: clearDuration ? null : (duration ?? this.duration),
    dismissible: dismissible ?? this.dismissible,
    pauseOnHover: pauseOnHover ?? this.pauseOnHover,
  );

  @override
  bool operator ==(Object other) =>
      other is ToastConfig &&
      other.status == status &&
      other.title == title &&
      other.position == position &&
      other.subtitle == subtitle &&
      other.referenceId == referenceId &&
      other.action == action &&
      other.onTap == onTap &&
      other.offset == offset &&
      other.duration == duration &&
      other.dismissible == dismissible &&
      other.pauseOnHover == pauseOnHover;

  @override
  int get hashCode => Object.hash(
    status,
    title,
    position,
    subtitle,
    referenceId,
    action,
    onTap,
    offset,
    duration,
    dismissible,
    pauseOnHover,
  );

  @override
  String toString() =>
      'ToastConfig(${status.shortName}, "$title"'
      '${subtitle == null ? '' : ', "$subtitle"'})';
}
