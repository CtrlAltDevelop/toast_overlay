import 'package:flutter/material.dart';

import '../toast_config.dart';
import '../toast_enums.dart';
import '../toast_strings.dart';
import 'toast_overlay_entry.dart';

/// One toast in a [ToastStack], identified so the column can keep each card's
/// state while its neighbours come and go.
@immutable
class StackedToast {
  const StackedToast({required this.id, required this.config});

  final Object id;
  final ToastConfig config;
}

/// Lays several toasts out as a column against the top and bottom edges.
///
/// The controller keeps a single overlay entry building this, so the toasts
/// share one layout and push each other along as they are added and removed.
class ToastStack extends StatelessWidget {
  const ToastStack({
    super.key,
    required this.toasts,
    required this.strings,
    required this.onDismissed,
    this.spacing = 8,
  });

  final List<StackedToast> toasts;

  /// Resolved against the toast's own context, so the strings follow the app's
  /// current locale.
  final ToastStrings Function(BuildContext context) strings;

  /// Called with the id of a toast whose exit animation has finished.
  final void Function(Object id) onDismissed;

  /// Gap between two stacked cards.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final position in ToastPosition.values)
          _edge(
            position,
            toasts.where((t) => t.config.position == position).toList(),
          ),
      ],
    );
  }

  Widget _edge(ToastPosition position, List<StackedToast> toasts) {
    final isTop = position.isTop;

    // The card carries the distance from the edge in its own margin, so only
    // the toast nearest the edge keeps its offset; the rest just get [spacing].
    final cards = <Widget>[];
    for (var i = 0; i < toasts.length; i++) {
      final toast = toasts[i];
      final isNearestEdge = isTop ? i == 0 : i == toasts.length - 1;
      if (cards.isNotEmpty) cards.add(SizedBox(height: spacing));
      cards.add(
        Builder(
          key: ValueKey(toast.id),
          builder: (context) => ToastOverlayEntry.stacked(
            config:
                isNearestEdge ? toast.config : toast.config.copyWith(offset: 0),
            strings: strings(context),
            onDismissed: () => onDismissed(toast.id),
          ),
        ),
      );
    }

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: isTop,
          bottom: !isTop,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cards,
          ),
        ),
      ),
    );
  }
}
