import 'package:flutter/widgets.dart';

import 'toast_enums.dart';

/// Every user-facing string the toast renders.
///
/// A published package cannot own your ARB files, so the host application
/// supplies these — typically from its own generated localisations. The
/// defaults are English so the package works out of the box.
@immutable
class ToastStrings {
  const ToastStrings({
    this.error = 'Error',
    this.success = 'Success',
    this.info = 'Info',
    this.warning = 'Warning',
    this.referencePrefix = 'Ref: ',
    this.closeLabel = 'Dismiss notification',
    this.copyReferenceLabel = 'Copy reference id',
  });

  /// Titles used when a toast is shown with an empty title.
  final String error;
  final String success;
  final String info;
  final String warning;

  /// Rendered immediately before the reference id.
  final String referencePrefix;

  /// Accessibility label for the close button.
  final String closeLabel;

  /// Accessibility label for the copy-reference button.
  final String copyReferenceLabel;

  /// The fallback title for [status].
  String defaultTitle(ToastStatus status) => switch (status) {
        ToastStatus.error => error,
        ToastStatus.success => success,
        ToastStatus.info => info,
        ToastStatus.warning => warning,
      };
}
