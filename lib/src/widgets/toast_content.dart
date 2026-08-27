import 'package:material_ui/material_ui.dart';

import '../toast_action.dart';
import '../toast_config.dart';
import '../toast_strings.dart';
import '../toast_theme.dart';
import 'toast_copy_button.dart';

/// The title plus, below it, the subtitle and the reference id.
class ToastContent extends StatelessWidget {
  const ToastContent({
    super.key,
    required this.config,
    required this.strings,
    this.onActionPressed,
  });

  final ToastConfig config;
  final ToastStrings strings;

  /// Called after the action's own callback, when the action asked for the
  /// toast to be dismissed.
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = config.title.isNotEmpty
        ? config.title
        : strings.defaultTitle(config.status);

    // The reference id sits under the subtitle rather than replacing it, so
    // the user gets both the explanation and something to quote to support.
    final showReference = config.hasReferenceId;
    final action = config.action;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A live region covering the text only: platforms that read them
        // announce the toast on their own, and keeping the buttons outside it
        // leaves them as their own nodes rather than one merged blob.
        Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.resolvedTitleStyle(textTheme),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (config.hasSubtitle) ...[
                const SizedBox(height: 2),
                ToastSubtitleText(subtitle: config.subtitle!),
              ],
            ],
          ),
        ),
        if (showReference) ...[
          const SizedBox(height: 2),
          ToastReferenceRow(
            referenceId: config.referenceId!,
            strings: strings,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 4),
          ToastActionButton(
            action: action,
            onPressed: onActionPressed,
          ),
        ],
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
        const SizedBox(width: 4),
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

/// The toast's optional action, laid out under the text.
class ToastActionButton extends StatelessWidget {
  const ToastActionButton({super.key, required this.action, this.onPressed});

  final ToastAction action;

  /// Called after [ToastAction.onPressed] when the action dismisses the toast.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: () {
          action.onPressed();
          if (action.dismissOnPressed) onPressed?.call();
        },
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: theme.actionColor ?? theme.titleColor,
        ),
        child: Text(
          action.label,
          style: theme.resolvedActionStyle(textTheme),
        ),
      ),
    );
  }
}
