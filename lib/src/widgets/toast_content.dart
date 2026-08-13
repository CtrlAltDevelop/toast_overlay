import 'package:flutter/material.dart';

import '../toast_config.dart';
import '../toast_enums.dart';
import '../toast_strings.dart';
import '../toast_theme.dart';
import 'toast_close_button.dart';
import 'toast_copy_button.dart';

/// The title row plus, below it, either the reference id or the subtitle.
class ToastContent extends StatelessWidget {
  const ToastContent({
    super.key,
    required this.config,
    required this.strings,
    required this.onDismiss,
    this.timerAnimation,
  });

  final ToastConfig config;
  final ToastStrings strings;
  final VoidCallback onDismiss;
  final Animation<double>? timerAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = config.title.isNotEmpty
        ? config.title
        : strings.defaultTitle(config.status);

    // A reference id is only meaningful on an error, and takes priority over
    // the subtitle because the user needs to be able to copy it.
    final showReference =
        config.status == ToastStatus.error && config.hasReferenceId;
    final detail = switch ((showReference, config.hasSubtitle)) {
      (true, _) => ToastReferenceRow(
          referenceId: config.referenceId!,
          strings: strings,
        ),
      (false, true) => ToastSubtitleText(subtitle: config.subtitle!),
      _ => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.resolvedTitleStyle(textTheme),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            ToastCloseButton(
              timerAnimation: timerAnimation,
              onDismiss: onDismiss,
              semanticsLabel: strings.closeLabel,
            ),
          ],
        ),
        if (detail != null) ...[const SizedBox(height: 4), detail],
      ],
    );
  }
}

/// `Ref: <id>` with a copy button.
class ToastReferenceRow extends StatelessWidget {
  const ToastReferenceRow({
    super.key,
    required this.referenceId,
    required this.strings,
  });

  final String referenceId;
  final ToastStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Flexible(
          child: Text(
            '${strings.referencePrefix}$referenceId',
            style: theme.resolvedReferenceStyle(textTheme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        ToastCopyButton(
          referenceId: referenceId,
          semanticsLabel: strings.copyReferenceLabel,
        ),
      ],
    );
  }
}

/// The secondary line under the title.
class ToastSubtitleText extends StatelessWidget {
  const ToastSubtitleText({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Text(
      subtitle,
      style: theme.resolvedSubtitleStyle(textTheme),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
