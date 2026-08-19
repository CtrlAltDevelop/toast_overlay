import 'package:material_ui/material_ui.dart';

import '../toast_config.dart';
import '../toast_enums.dart';
import '../toast_strings.dart';
import '../toast_theme.dart';
import 'toast_copy_button.dart';

/// The title plus, below it, the subtitle and the reference id.
class ToastContent extends StatelessWidget {
  const ToastContent({
    super.key,
    required this.config,
    required this.strings,
  });

  final ToastConfig config;
  final ToastStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = ToastTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = config.title.isNotEmpty
        ? config.title
        : strings.defaultTitle(config.status);

    // A reference id is only meaningful on an error. It sits under the
    // subtitle rather than replacing it, so the user gets both the
    // explanation and something to quote to support.
    final showReference =
        config.status == ToastStatus.error && config.hasReferenceId;

    return Column(
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
        if (showReference) ...[
          const SizedBox(height: 2),
          ToastReferenceRow(
            referenceId: config.referenceId!,
            strings: strings,
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
