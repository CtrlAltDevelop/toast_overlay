import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'toast_enums.dart';

/// The colours for one [ToastStatus]: the icon tile background and the icon.
@immutable
class ToastStatusColors {
  const ToastStatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  ToastStatusColors lerpTo(ToastStatusColors other, double t) =>
      ToastStatusColors(
        background: Color.lerp(background, other.background, t) ?? background,
        foreground: Color.lerp(foreground, other.foreground, t) ?? foreground,
      );
}

/// Everything the toast needs to paint itself.
///
/// Register it as a [ThemeExtension] so the toast follows your app's light and
/// dark themes:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(extensions: const [ToastTheme.light]),
///   darkTheme: ThemeData(extensions: const [ToastTheme.dark]),
/// );
/// ```
///
/// When no extension is registered the toast falls back to [ToastTheme.of],
/// which derives a usable palette from the ambient [ColorScheme].
@immutable
class ToastTheme extends ThemeExtension<ToastTheme> {
  const ToastTheme({
    required this.surface,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.closeIconColor,
    required this.statusColors,
    this.titleStyle,
    this.subtitleStyle,
    this.shadows = const [],
    this.cardShape,
    this.iconShape,
    this.icons = const ToastIcons(),
    this.glowBuilder,
  });

  /// The toast card background.
  final Color surface;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color closeIconColor;

  /// Per-status icon colours. Missing entries fall back to [titleColor].
  final Map<ToastStatus, ToastStatusColors> statusColors;

  /// Text styles. When null the ambient theme's body/caption styles are used.
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final List<BoxShadow> shadows;

  /// Shape of the toast card. Defaults to a squircle with a 12pt radius.
  final ShapeBorder? cardShape;

  /// Shape of the leading icon tile. Defaults to a squircle with a 6pt radius.
  final ShapeBorder? iconShape;

  final ToastIcons icons;

  /// Optional decorative backdrop painted behind the card contents, built per
  /// status — this is where the host supplies its own glow images.
  final Widget Function(BuildContext context, ToastStatus status)? glowBuilder;

  ShapeBorder get resolvedCardShape =>
      cardShape ??
      SmoothRectangleBorder(
        side: BorderSide(width: 1, color: borderColor),
        borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 1),
      );

  ShapeBorder get resolvedIconShape =>
      iconShape ??
      SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(cornerRadius: 6, cornerSmoothing: 1),
      );

  ToastStatusColors colorsFor(ToastStatus status) =>
      statusColors[status] ??
      ToastStatusColors(background: surface, foreground: titleColor);

  /// The registered [ToastTheme], or one derived from the ambient
  /// [ColorScheme] when the host has not registered an extension.
  static ToastTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ToastTheme>() ?? _fromColorScheme(theme);
  }

  static ToastTheme _fromColorScheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return ToastTheme(
      surface: scheme.surfaceContainerHigh,
      borderColor: scheme.outlineVariant,
      titleColor: scheme.onSurface,
      subtitleColor: scheme.onSurfaceVariant,
      closeIconColor: scheme.onSurfaceVariant,
      statusColors: {
        ToastStatus.error: ToastStatusColors(
          background: scheme.errorContainer,
          foreground: scheme.error,
        ),
        ToastStatus.success: ToastStatusColors(
          background: scheme.tertiaryContainer,
          foreground: scheme.tertiary,
        ),
        ToastStatus.info: ToastStatusColors(
          background: scheme.primaryContainer,
          foreground: scheme.primary,
        ),
        ToastStatus.warning: ToastStatusColors(
          background: scheme.secondaryContainer,
          foreground: scheme.secondary,
        ),
      },
      shadows: const [
        BoxShadow(
            color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
      ],
    );
  }

  @override
  ToastTheme copyWith({
    Color? surface,
    Color? borderColor,
    Color? titleColor,
    Color? subtitleColor,
    Color? closeIconColor,
    Map<ToastStatus, ToastStatusColors>? statusColors,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    List<BoxShadow>? shadows,
    ShapeBorder? cardShape,
    ShapeBorder? iconShape,
    ToastIcons? icons,
    Widget Function(BuildContext, ToastStatus)? glowBuilder,
  }) =>
      ToastTheme(
        surface: surface ?? this.surface,
        borderColor: borderColor ?? this.borderColor,
        titleColor: titleColor ?? this.titleColor,
        subtitleColor: subtitleColor ?? this.subtitleColor,
        closeIconColor: closeIconColor ?? this.closeIconColor,
        statusColors: statusColors ?? this.statusColors,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        shadows: shadows ?? this.shadows,
        cardShape: cardShape ?? this.cardShape,
        iconShape: iconShape ?? this.iconShape,
        icons: icons ?? this.icons,
        glowBuilder: glowBuilder ?? this.glowBuilder,
      );

  @override
  ToastTheme lerp(ToastTheme? other, double t) {
    if (other == null) return this;
    return ToastTheme(
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      titleColor: Color.lerp(titleColor, other.titleColor, t) ?? titleColor,
      subtitleColor:
          Color.lerp(subtitleColor, other.subtitleColor, t) ?? subtitleColor,
      closeIconColor:
          Color.lerp(closeIconColor, other.closeIconColor, t) ?? closeIconColor,
      statusColors: {
        for (final status in ToastStatus.values)
          status: colorsFor(status).lerpTo(other.colorsFor(status), t),
      },
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      subtitleStyle: TextStyle.lerp(subtitleStyle, other.subtitleStyle, t),
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
      cardShape: t < 0.5 ? cardShape : other.cardShape,
      iconShape: t < 0.5 ? iconShape : other.iconShape,
      icons: t < 0.5 ? icons : other.icons,
      glowBuilder: t < 0.5 ? glowBuilder : other.glowBuilder,
    );
  }
}

/// The icon set used for each status and for the two action buttons.
@immutable
class ToastIcons {
  const ToastIcons({
    this.error = Remix.error_warning_fill,
    this.success = Remix.checkbox_circle_fill,
    this.info = Remix.information_fill,
    this.warning = Remix.alert_fill,
    this.close = Remix.close_line,
    this.copy = Remix.file_copy_line,
    this.copied = Remix.check_line,
  });

  final IconData error;
  final IconData success;
  final IconData info;
  final IconData warning;
  final IconData close;
  final IconData copy;
  final IconData copied;

  IconData forStatus(ToastStatus status) => switch (status) {
        ToastStatus.error => error,
        ToastStatus.success => success,
        ToastStatus.info => info,
        ToastStatus.warning => warning,
      };
}
