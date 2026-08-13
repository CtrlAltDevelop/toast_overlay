import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:toast_overlay/toast_overlay.dart';

/// A brand palette, wired in as a [ToastTheme] extension.
///
/// Every field is filled in here, so the example doubles as a reference for
/// what a [ToastTheme] can carry. All of them are optional except the colours.
///
/// Lives in its own file so the screenshot test can render the same toasts the
/// app shows.
const exampleToastTheme = ToastTheme(
  // Colours.
  surface: Color(0xFFF7F8FA),
  borderColor: Color(0xFFE5E7EB),
  titleColor: Color(0xFF0A0C12),
  subtitleColor: Color(0xFF6B7280),
  closeIconColor: Color(0xFF9CA3AF),
  statusColors: {
    ToastStatus.error: ToastStatusColors(
      background: Color(0xFFFEE4E2),
      foreground: Color(0xFFF04438),
    ),
    ToastStatus.success: ToastStatusColors(
      background: Color(0xFFD1FADF),
      foreground: Color(0xFF12B76A),
    ),
    ToastStatus.info: ToastStatusColors(
      background: Color(0xFFE4E9FF),
      foreground: Color(0xFF3B5BFF),
    ),
    ToastStatus.warning: ToastStatusColors(
      background: Color(0xFFFEF0C7),
      foreground: Color(0xFFF79009),
    ),
  },

  // Type. A family set on one of the styles wins over [fontFamily]; anything
  // the styles leave unset falls back to the ambient text theme.
  fontFamily: 'Roboto',
  titleStyle: TextStyle(fontSize: 15, height: 1.3),
  subtitleStyle: TextStyle(fontSize: 13, height: 1.35),
  referenceStyle: TextStyle(fontSize: 13, letterSpacing: 0.3),

  // Shape. Pass cardShape / iconShape instead when a radius is not enough.
  cardRadius: BorderRadius.all(Radius.circular(14)),
  iconRadius: BorderRadius.all(Radius.circular(8)),
  shadows: [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ],

  // Icons. These are the package defaults, spelled out.
  icons: ToastIcons(
    error: Remix.error_warning_fill,
    success: Remix.checkbox_circle_fill,
    info: Remix.information_fill,
    warning: Remix.alert_fill,
    close: Remix.close_line,
    copy: Remix.file_copy_line,
    copied: Remix.check_line,
  ),

  glowBuilder: statusGlow,
);

/// A decorative backdrop painted behind the card, one image per status.
Widget statusGlow(BuildContext context, ToastStatus status) => Image.asset(
      'assets/${status.shortName}_glow.webp',
      fit: BoxFit.fitWidth,
      alignment: Alignment.centerRight,
    );
