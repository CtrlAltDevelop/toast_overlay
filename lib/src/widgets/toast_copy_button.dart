import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../toast_enums.dart';
import '../toast_theme.dart';

/// Copies a reference id to the clipboard, showing a tick for a moment after.
class ToastCopyButton extends StatefulWidget {
  const ToastCopyButton({
    super.key,
    required this.referenceId,
    required this.semanticsLabel,
    this.confirmationDuration = const Duration(seconds: 2),
  });

  final String referenceId;
  final String semanticsLabel;

  /// How long the tick stays visible after a copy.
  final Duration confirmationDuration;

  @override
  State<ToastCopyButton> createState() => _ToastCopyButtonState();
}

class _ToastCopyButtonState extends State<ToastCopyButton> {
  static const double _minTapTarget = 48;

  bool _copied = false;
  Timer? _resetTimer;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.referenceId));
    if (!mounted) return;
    setState(() => _copied = true);
    // A cancellable timer rather than Future.delayed: the toast is usually
    // dismissed before the confirmation elapses, and a pending future would
    // outlive the widget.
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.confirmationDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: InkResponse(
        onTap: _copy,
        radius: _minTapTarget / 2,
        child: SizedBox(
          width: _minTapTarget,
          height: _minTapTarget,
          child: Center(
            child: Icon(
              _copied ? theme.icons.copied : theme.icons.copy,
              size: 14,
              color: _copied
                  ? theme.colorsFor(ToastStatus.success).foreground
                  : theme.subtitleColor,
            ),
          ),
        ),
      ),
    );
  }
}
