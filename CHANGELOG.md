# Changelog

## 0.3.0

- Toasts can stack. `Toast.init(maxStack: 3)` (or `ToastController(maxStack:)`)
  keeps several toasts against their edge instead of replacing; the oldest one
  drops off past the limit, and `stackSpacing` sets the gap. The default of 1
  keeps the previous replace-on-show behaviour.
- `ToastTheme.cardRadius` and `ToastTheme.iconRadius` set the corner radii as a
  `BorderRadius`, without having to build a whole `ShapeBorder`. `cardShape` /
  `iconShape` still win when set.
- `ToastTheme.fontFamily` swaps the typeface for every line, and
  `referenceStyle` styles the `Ref: <id>` line on its own.
- `titleStyle` and `subtitleStyle` are now respected in full: a `fontWeight`,
  `color` or `fontFamily` they set is no longer overwritten by the theme's
  defaults.
- README screenshots are generated from the real widgets by
  `example/test/screenshots_test.dart`.

## 0.2.0

- Added `stringsBuilder`, which resolves `ToastStrings` against the toast's own
  `BuildContext` instead of freezing them when the controller is created. A
  controller is usually built before `runApp`, where no localisations exist, so
  fixed strings could never follow a locale change. `strings` still works for
  apps that do not localise.

## 0.1.0

Initial release.

- `Toast.show` / `ToastController` for overlay toasts with `error`, `success`,
  `info` and `warning` statuses, anchored top or bottom.
- Auto-dismiss with a countdown ring around the close button.
- Optional support `referenceId` rendered with a copy button; supplying one
  disables auto-dismiss so the user can copy it.
- `ToastTheme` extension for colours, text styles, shadows, shapes, icons and a
  `glowBuilder` backdrop, with a `ColorScheme`-derived fallback when none is
  registered.
- `ToastStrings` for host-supplied localisation, English by default.
- `ToastHistory` ring buffer and a `logger` callback.
- 48×48 tap targets and semantics labels on both action buttons.
