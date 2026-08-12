import 'package:flutter/widgets.dart';

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
    this.offset = 0,
    this.duration = const Duration(seconds: 3),
  });

  final ToastStatus status;

  /// Falls back to the status default title when empty.
  final String title;

  final ToastPosition position;
  final String? subtitle;

  /// A server-side reference id shown with a copy button, so the user can quote
  /// it to support. Hidden when null or empty.
  final String? referenceId;

  /// Distance from the anchored screen edge.
  final double offset;

  /// Auto-dismiss delay. Null keeps the toast up until dismissed manually.
  final Duration? duration;

  bool get hasReferenceId => referenceId != null && referenceId!.isNotEmpty;
  bool get hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  /// Whether the timer ring around the close button should be drawn.
  bool get isAutoDismissing => duration != null;

  ToastConfig copyWith({Duration? duration, bool clearDuration = false}) =>
      ToastConfig(
        status: status,
        title: title,
        position: position,
        subtitle: subtitle,
        referenceId: referenceId,
        offset: offset,
        duration: clearDuration ? null : (duration ?? this.duration),
      );

  @override
  bool operator ==(Object other) =>
      other is ToastConfig &&
      other.status == status &&
      other.title == title &&
      other.position == position &&
      other.subtitle == subtitle &&
      other.referenceId == referenceId &&
      other.offset == offset &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(
        status,
        title,
        position,
        subtitle,
        referenceId,
        offset,
        duration,
      );

  @override
  String toString() => 'ToastConfig(${status.shortName}, "$title"'
      '${subtitle == null ? '' : ', "$subtitle"'})';
}
