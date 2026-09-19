import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

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
    this.referenceStyle,
    this.actionStyle,
    this.actionColor,
    this.fontFamily,
    this.maxWidth = 520,
    this.shadows = const [],
    this.cardRadius = const BorderRadius.all(Radius.circular(12)),
    this.iconRadius = const BorderRadius.all(Radius.circular(6)),
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
  ///
  /// Anything they set wins: a [titleStyle] with its own `fontWeight`, `color`
  /// or `fontFamily` is used as given, rather than being overwritten by
  /// [titleColor] and the default semi-bold weight.
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Style of the `Ref: <id>` line. Falls back to [subtitleStyle].
  final TextStyle? referenceStyle;

  /// Style of the action button's label. Falls back to the title style at the
  /// subtitle's size.
  final TextStyle? actionStyle;

  /// The action button's label and ripple colour. Falls back to [titleColor];
  /// one colour for every status keeps the button legible on all four.
  final Color? actionColor;

  /// Font family for every line of the toast, for hosts that only want to swap
  /// the typeface. A family set on one of the styles above wins over this.
  final String? fontFamily;

  final List<BoxShadow> shadows;

  /// The widest the card is allowed to get, so a toast does not stretch across
  /// a desktop window. [double.infinity] restores the pre-1.2 full-width card.
  final double maxWidth;

  /// Corner radii of the toast card, per corner. Ignored when [cardShape] is
  /// set.
  final BorderRadius cardRadius;

  /// Corner radii of the leading icon tile. Ignored when [iconShape] is set.
  final BorderRadius iconRadius;

  /// Shape of the toast card. Overrides [cardRadius] when set; defaults to a
  /// squircle with a [cardRadius] radius.
  final ShapeBorder? cardShape;

  /// Shape of the leading icon tile. Overrides [iconRadius] when set; defaults
  /// to a squircle with an [iconRadius] radius.
  final ShapeBorder? iconShape;

  final ToastIcons icons;

  /// Optional decorative backdrop painted behind the card contents, built per
  /// status — this is where the host supplies its own glow images.
  final Widget Function(BuildContext context, ToastStatus status)? glowBuilder;

  ShapeBorder get resolvedCardShape =>
      cardShape ??
      RoundedSuperellipseBorder(
        side: BorderSide(width: 1, color: borderColor),
        borderRadius: cardRadius,
      );

  ShapeBorder get resolvedIconShape =>
      iconShape ?? RoundedSuperellipseBorder(borderRadius: iconRadius);

  /// The title style, with this theme's colour, weight and family filled in
  /// wherever [titleStyle] leaves them unset.
  TextStyle resolvedTitleStyle(TextTheme textTheme) {
    final base = titleStyle ?? textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(
      color: titleStyle?.color ?? titleColor,
      fontWeight: titleStyle?.fontWeight ?? FontWeight.w600,
      fontFamily: titleStyle?.fontFamily ?? fontFamily ?? base.fontFamily,
    );
  }

  /// The subtitle style, filled in the same way from [subtitleStyle].
  TextStyle resolvedSubtitleStyle(TextTheme textTheme) =>
      _detailStyle(subtitleStyle, textTheme);

  /// The reference-id style, falling back to [resolvedSubtitleStyle].
  TextStyle resolvedReferenceStyle(TextTheme textTheme) =>
      _detailStyle(referenceStyle ?? subtitleStyle, textTheme);

  TextStyle _detailStyle(TextStyle? style, TextTheme textTheme) {
    final base = style ?? textTheme.bodySmall ?? const TextStyle();
    return base.copyWith(
      color: style?.color ?? subtitleColor,
      fontFamily: style?.fontFamily ?? fontFamily ?? base.fontFamily,
    );
  }

  /// The action label style, filled in from this theme where [actionStyle]
  /// leaves things unset.
  TextStyle resolvedActionStyle(TextTheme textTheme) {
    final base = actionStyle ?? textTheme.labelLarge ?? const TextStyle();
    return base.copyWith(
      fontWeight: actionStyle?.fontWeight ?? FontWeight.w600,
      fontFamily: actionStyle?.fontFamily ?? fontFamily ?? base.fontFamily,
    );
  }

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
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
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
    TextStyle? referenceStyle,
    TextStyle? actionStyle,
    Color? actionColor,
    String? fontFamily,
    double? maxWidth,
    List<BoxShadow>? shadows,
    BorderRadius? cardRadius,
    BorderRadius? iconRadius,
    ShapeBorder? cardShape,
    ShapeBorder? iconShape,
    ToastIcons? icons,
    Widget Function(BuildContext, ToastStatus)? glowBuilder,
  }) => ToastTheme(
    surface: surface ?? this.surface,
    borderColor: borderColor ?? this.borderColor,
    titleColor: titleColor ?? this.titleColor,
    subtitleColor: subtitleColor ?? this.subtitleColor,
    closeIconColor: closeIconColor ?? this.closeIconColor,
    statusColors: statusColors ?? this.statusColors,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    referenceStyle: referenceStyle ?? this.referenceStyle,
    actionStyle: actionStyle ?? this.actionStyle,
    actionColor: actionColor ?? this.actionColor,
    fontFamily: fontFamily ?? this.fontFamily,
    maxWidth: maxWidth ?? this.maxWidth,
    shadows: shadows ?? this.shadows,
    cardRadius: cardRadius ?? this.cardRadius,
    iconRadius: iconRadius ?? this.iconRadius,
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
      referenceStyle: TextStyle.lerp(referenceStyle, other.referenceStyle, t),
      actionStyle: TextStyle.lerp(actionStyle, other.actionStyle, t),
      actionColor: Color.lerp(actionColor, other.actionColor, t),
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      maxWidth: lerpDouble(maxWidth, other.maxWidth, t) ?? maxWidth,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
      cardRadius:
          BorderRadius.lerp(cardRadius, other.cardRadius, t) ?? cardRadius,
      iconRadius:
          BorderRadius.lerp(iconRadius, other.iconRadius, t) ?? iconRadius,
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
    this.error = Icons.error,
    this.success = Icons.check_circle,
    this.info = Icons.info,
    this.warning = Icons.warning,
    this.close = Icons.close,
    this.copy = Icons.content_copy,
    this.copied = Icons.check,
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
