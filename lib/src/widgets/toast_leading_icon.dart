import 'package:flutter/material.dart';

import '../toast_enums.dart';
import '../toast_theme.dart';

/// The status icon in its tinted tile.
class ToastLeadingIcon extends StatelessWidget {
  const ToastLeadingIcon({super.key, required this.status, this.size = 38});

  final ToastStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final colors = theme.colorsFor(status);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: colors.background,
        shape: theme.resolvedIconShape,
        shadows: theme.shadows,
      ),
      child: Center(
        child: Icon(
          theme.icons.forStatus(status),
          size: size * 0.63,
          color: colors.foreground,
          // The status is already conveyed by the title text, so the icon is
          // decorative for a screen reader.
          semanticLabel: null,
        ),
      ),
    );
  }
}
