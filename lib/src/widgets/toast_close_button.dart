import 'package:material_ui/material_ui.dart';

import '../toast_theme.dart';
import 'toast_timer_progress.dart';

/// The dismiss button, wrapped in a countdown ring while the toast is
/// auto-dismissing.
class ToastCloseButton extends StatelessWidget {
  const ToastCloseButton({
    super.key,
    required this.onDismiss,
    required this.semanticsLabel,
    this.timerAnimation,
  });

  final VoidCallback onDismiss;
  final String semanticsLabel;
  final Animation<double>? timerAnimation;

  /// The visible circle is small by design, so the tap target is expanded to
  /// the 48dp accessibility minimum instead.
  static const double _minTapTarget = 48;
  static const double _visualSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final animation = timerAnimation;

    final icon = Icon(
      theme.icons.close,
      size: animation != null ? 9.6 : 14,
      color: theme.closeIconColor,
    );

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkResponse(
        onTap: onDismiss,
        radius: _minTapTarget / 2,
        child: SizedBox(
          width: _minTapTarget,
          height: _minTapTarget,
          child: Center(
            child: Container(
              width: _visualSize,
              height: _visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.surface.withValues(alpha: 0.5),
              ),
              child: animation == null
                  ? icon
                  : AnimatedBuilder(
                      animation: animation,
                      child: icon,
                      builder: (context, child) => Padding(
                        padding: const EdgeInsets.all(2),
                        child: ToastTimerProgress(
                          value: animation,
                          color: theme.closeIconColor,
                          size: 16,
                          child: child!,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
