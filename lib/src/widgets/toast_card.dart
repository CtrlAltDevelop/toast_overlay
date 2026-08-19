import 'package:material_ui/material_ui.dart';

import '../toast_config.dart';
import '../toast_strings.dart';
import '../toast_theme.dart';
import 'toast_close_button.dart';
import 'toast_content.dart';
import 'toast_leading_icon.dart';

/// The animated toast card: the surface, its glow backdrop, the leading icon
/// and the text content.
class ToastCard extends StatelessWidget {
  const ToastCard({
    super.key,
    required this.config,
    required this.strings,
    required this.animation,
    required this.onDismiss,
    this.timerAnimation,
    this.margin = const EdgeInsets.symmetric(horizontal: 26),
  });

  final ToastConfig config;
  final ToastStrings strings;
  final Animation<double> animation;
  final Animation<double>? timerAnimation;
  final VoidCallback onDismiss;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final isTop = config.position.isTop;

    return AnimatedBuilder(
      animation: animation,
      // The card is passed as `child` so it is built once rather than on every
      // animation tick.
      child: Container(
        margin: margin.copyWith(
          top: isTop ? config.offset : 0,
          bottom: isTop ? 0 : config.offset,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: theme.surface,
          shape: theme.resolvedCardShape,
          shadows: theme.shadows,
        ),
        child: Stack(
          children: [
            if (theme.glowBuilder != null)
              Positioned.fill(
                  child: theme.glowBuilder!(context, config.status)),
            Padding(
              // The right inset keeps the text clear of the close button, which
              // is laid out on top of the card rather than in this row.
              padding: const EdgeInsets.fromLTRB(10, 10, 38, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToastLeadingIcon(status: config.status),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ToastContent(config: config, strings: strings),
                  ),
                ],
              ),
            ),
            // Overlaid, so its 48dp tap target costs the card no height.
            Positioned(
              top: 0,
              right: 0,
              child: ToastCloseButton(
                timerAnimation: timerAnimation,
                onDismiss: onDismiss,
                semanticsLabel: strings.closeLabel,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        final value = animation.value;
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * config.position.entranceYOffset),
            child: child,
          ),
        );
      },
    );
  }
}
