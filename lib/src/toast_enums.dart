/// Where a toast enters from and anchors to.
enum ToastPosition {
  top,
  bottom;

  bool get isTop => this == ToastPosition.top;

  /// The vertical distance the toast travels while animating in. Negative for
  /// [top] so it slides down into place, positive for [bottom] so it slides up.
  double get entranceYOffset => switch (this) {
    ToastPosition.top => -20,
    ToastPosition.bottom => 20,
  };

  /// A stable label for logging and tests.
  String get shortName => switch (this) {
    ToastPosition.top => 'top',
    ToastPosition.bottom => 'bottom',
  };
}

/// The severity of a toast, which selects its colours, icon and default title.
enum ToastStatus {
  error,
  success,
  info,
  warning;

  /// A stable label for logging and tests.
  String get shortName => switch (this) {
    ToastStatus.error => 'error',
    ToastStatus.success => 'success',
    ToastStatus.info => 'info',
    ToastStatus.warning => 'warning',
  };
}
